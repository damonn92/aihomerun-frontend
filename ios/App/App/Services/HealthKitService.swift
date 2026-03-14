import Foundation
import HealthKit
import os.log

/// iPhone-side HealthKit service — reads workout data, heart rate, and activity metrics
@MainActor
final class HealthKitService: ObservableObject {

    static let shared = HealthKitService()

    private let logger = Logger(subsystem: "com.aihomerun.app", category: "HealthKit")
    private let healthStore = HKHealthStore()

    // MARK: - Published State

    @Published var isAuthorized = false
    @Published var isAvailable = false

    // Weekly summary
    @Published var weeklyWorkouts: [HKWorkout] = []
    @Published var weeklyActiveCalories: Double = 0
    @Published var weeklyExerciseMinutes: Double = 0
    @Published var weeklyWorkoutCount: Int = 0

    // Today's stats
    @Published var todaySteps: Int = 0
    @Published var todayActiveCalories: Double = 0
    @Published var todayExerciseMinutes: Double = 0
    @Published var restingHeartRate: Double = 0

    // Recent heart rate samples
    @Published var recentHeartRates: [HeartRateSample] = []

    // All-time training stats
    @Published var totalBaseballWorkouts: Int = 0
    @Published var totalTrainingMinutes: Double = 0
    @Published var averageHeartRateDuringTraining: Double = 0
    @Published var totalCaloriesBurned: Double = 0

    // Loading state
    @Published var isLoading = false

    // MARK: - Init

    init() {
        isAvailable = HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    /// Types we want to read from HealthKit
    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.activitySummaryType()
        ]
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) { types.insert(heartRate) }
        if let restingHR = HKObjectType.quantityType(forIdentifier: .restingHeartRate) { types.insert(restingHR) }
        if let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(activeEnergy) }
        if let exerciseTime = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) { types.insert(exerciseTime) }
        if let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount) { types.insert(stepCount) }
        return types
    }

    /// Types we want to write (workout sessions from Watch sync)
    private var shareTypes: Set<HKSampleType> {
        [HKObjectType.workoutType()]
    }

    func requestAuthorization() async -> Bool {
        guard isAvailable else {
            logger.warning("HealthKit not available on this device")
            return false
        }

        do {
            try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
            isAuthorized = true
            logger.info("HealthKit authorization granted")
            return true
        } catch {
            logger.error("HealthKit authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Fetch All Data

    func fetchAllData() async {
        guard isAvailable else { return }

        if !isAuthorized {
            let granted = await requestAuthorization()
            if !granted { return }
        }

        isLoading = true

        async let w = fetchWeeklyWorkouts()
        async let t = fetchTodayStats()
        async let h = fetchRecentHeartRates()
        async let a = fetchAllTimeTrainingStats()

        _ = await (w, t, h, a)

        isLoading = false
    }

    // MARK: - Weekly Workouts

    private func fetchWeeklyWorkouts() async {
        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: weekAgo, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(
                    sampleType: .workoutType(),
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    if let error { continuation.resume(throwing: error) }
                    else { continuation.resume(returning: samples ?? []) }
                }
                healthStore.execute(query)
            }

            let workouts = samples.compactMap { $0 as? HKWorkout }
            weeklyWorkouts = workouts
            weeklyWorkoutCount = workouts.count

            // Calculate totals
            weeklyActiveCalories = workouts.reduce(0) { total, workout in
                total + (workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)
            }
            weeklyExerciseMinutes = workouts.reduce(0) { total, workout in
                total + workout.duration / 60.0
            }

            logger.info("Fetched \(workouts.count) workouts this week")
        } catch {
            logger.error("Failed to fetch weekly workouts: \(error.localizedDescription)")
        }
    }

    // MARK: - Today Stats

    private func fetchTodayStats() async {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        // Steps
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            if let steps = await fetchSum(quantityType: stepType, predicate: predicate, unit: .count()) {
                todaySteps = Int(steps)
            }
        }

        // Active calories
        if let calType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            if let cal = await fetchSum(quantityType: calType, predicate: predicate, unit: .kilocalorie()) {
                todayActiveCalories = cal
            }
        }

        // Exercise minutes
        if let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) {
            if let min = await fetchSum(quantityType: exerciseType, predicate: predicate, unit: .minute()) {
                todayExerciseMinutes = min
            }
        }

        // Resting heart rate (most recent)
        if let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            if let hr = await fetchLatest(quantityType: restingHRType, unit: HKUnit.count().unitDivided(by: .minute())) {
                restingHeartRate = hr
            }
        }
    }

    // MARK: - Recent Heart Rates

    private func fetchRecentHeartRates() async {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let calendar = Calendar.current
        guard let hoursAgo = calendar.date(byAdding: .hour, value: -24, to: Date()) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: hoursAgo, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(
                    sampleType: heartRateType,
                    predicate: predicate,
                    limit: 50,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    if let error { continuation.resume(throwing: error) }
                    else { continuation.resume(returning: samples ?? []) }
                }
                healthStore.execute(query)
            }

            let hrUnit = HKUnit.count().unitDivided(by: .minute())
            recentHeartRates = samples.compactMap { sample -> HeartRateSample? in
                guard let qSample = sample as? HKQuantitySample else { return nil }
                return HeartRateSample(
                    date: qSample.startDate,
                    bpm: qSample.quantity.doubleValue(for: hrUnit)
                )
            }
        } catch {
            logger.error("Failed to fetch heart rates: \(error.localizedDescription)")
        }
    }

    // MARK: - All-Time Training Stats

    private func fetchAllTimeTrainingStats() async {
        let baseballPredicate = HKQuery.predicateForWorkouts(with: .baseball)

        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(
                    sampleType: .workoutType(),
                    predicate: baseballPredicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: nil
                ) { _, samples, error in
                    if let error { continuation.resume(throwing: error) }
                    else { continuation.resume(returning: samples ?? []) }
                }
                healthStore.execute(query)
            }

            let workouts = samples.compactMap { $0 as? HKWorkout }
            totalBaseballWorkouts = workouts.count
            totalTrainingMinutes = workouts.reduce(0) { $0 + $1.duration / 60.0 }
            totalCaloriesBurned = workouts.reduce(0) { total, w in
                total + (w.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)
            }

            logger.info("All-time: \(workouts.count) baseball workouts, \(Int(self.totalTrainingMinutes)) min")
        } catch {
            logger.error("Failed to fetch all-time stats: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func fetchSum(quantityType: HKQuantityType, predicate: NSPredicate, unit: HKUnit) async -> Double? {
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let value = result?.sumQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    private func fetchLatest(quantityType: HKQuantityType, unit: HKUnit) async -> Double? {
        await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }
}

// MARK: - Models

struct HeartRateSample: Identifiable {
    let id = UUID()
    let date: Date
    let bpm: Double
}
