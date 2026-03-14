import Foundation
import HealthKit
import os.log

#if os(watchOS)
import WatchKit
#endif

/// Manages HealthKit workout sessions for Apple Watch
/// Required for CMBatchedSensorManager access and background execution
final class WorkoutService: ObservableObject {

    private let logger = Logger(subsystem: "com.aihomerun.watch", category: "WorkoutService")

    // MARK: - Published State
    @Published var isWorkoutActive = false
    @Published var heartRate: Double = 0
    @Published var activeCalories: Double = 0
    @Published var elapsedTime: TimeInterval = 0

    // MARK: - HealthKit
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var timer: Timer?

    // MARK: - Authorization

    private var hasRequestedAuth = false

    func requestAuthorization() async -> Bool {
        // If already requested this session, skip (avoids repeated system dialogs)
        if hasRequestedAuth { return true }

        guard HKHealthStore.isHealthDataAvailable() else {
            logger.warning("HealthKit not available on this device")
            return false
        }

        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.workoutType()
        ]

        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            hasRequestedAuth = true
            logger.info("HealthKit authorization granted")
            return true
        } catch {
            logger.error("HealthKit authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Start Workout

    func startWorkout() async throws {
        guard !isWorkoutActive else { return }

        let config = HKWorkoutConfiguration()
        config.activityType = .baseball
        config.locationType = .outdoor

        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)

            // Start the session and builder
            let startDate = Date()
            workoutSession?.startActivity(with: startDate)
            try await workoutBuilder?.beginCollection(at: startDate)

            await MainActor.run {
                self.isWorkoutActive = true
                self.elapsedTime = 0
                self.heartRate = 0
                self.activeCalories = 0
            }

            startHeartRateQuery()
            startTimer()

            logger.info("Workout session started")
        } catch {
            logger.error("Failed to start workout: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - End Workout

    func endWorkout() async -> (avgHeartRate: Double, peakHeartRate: Double, calories: Double)? {
        guard isWorkoutActive else { return nil }

        workoutSession?.end()

        do {
            let endDate = Date()
            try await workoutBuilder?.endCollection(at: endDate)

            // Collect summary stats
            let stats = workoutBuilder?.statistics(for: HKQuantityType(.heartRate))
            let avgHR = stats?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0
            let maxHR = stats?.maximumQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0

            let calStats = workoutBuilder?.statistics(for: HKQuantityType(.activeEnergyBurned))
            let cal = calStats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0

            try await workoutBuilder?.finishWorkout()

            await MainActor.run {
                self.isWorkoutActive = false
            }

            stopHeartRateQuery()
            stopTimer()

            logger.info("Workout ended. Avg HR: \(avgHR), Peak HR: \(maxHR), Cal: \(cal)")

            return (avgHeartRate: avgHR, peakHeartRate: maxHR, calories: cal)
        } catch {
            logger.error("Failed to end workout: \(error.localizedDescription)")
            await MainActor.run {
                self.isWorkoutActive = false
            }
            return nil
        }
    }

    // MARK: - Heart Rate Monitoring

    private func startHeartRateQuery() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)

        heartRateQuery = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }

        heartRateQuery?.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }

        if let query = heartRateQuery {
            healthStore.execute(query)
        }
    }

    private func stopHeartRateQuery() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
    }

    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample], let latest = samples.last else { return }
        let hr = latest.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        DispatchQueue.main.async {
            self.heartRate = hr
        }
    }

    // MARK: - Timer

    private func startTimer() {
        let startDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.elapsedTime = Date().timeIntervalSince(startDate)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
