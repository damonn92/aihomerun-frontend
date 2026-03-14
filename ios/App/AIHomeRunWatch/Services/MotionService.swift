import Foundation
import CoreMotion
import os.log

/// Handles all IMU data collection from Apple Watch sensors
/// Supports both CMMotionManager (100Hz, Series 4+) and CMBatchedSensorManager (800Hz, Series 8+)
final class MotionService: ObservableObject {

    private let logger = Logger(subsystem: "com.aihomerun.watch", category: "MotionService")

    // MARK: - Published State
    @Published var isCollecting = false
    @Published var sensorRate: SensorRate = .standard
    @Published var latestAcceleration: CMAcceleration = CMAcceleration(x: 0, y: 0, z: 0)
    @Published var latestRotationRate: CMRotationRate = CMRotationRate(x: 0, y: 0, z: 0)

    // MARK: - Sensor Managers
    private let motionManager = CMMotionManager()
    #if os(watchOS)
    private var batchedManager: CMBatchedSensorManager?
    private var accelTask: Task<Void, Never>?
    private var motionTask: Task<Void, Never>?
    #endif

    // MARK: - Data Buffers
    private var accelerometerBuffer: [(timestamp: TimeInterval, x: Double, y: Double, z: Double)] = []
    private var deviceMotionBuffer: [(timestamp: TimeInterval, rotX: Double, rotY: Double, rotZ: Double, gravX: Double, gravY: Double, gravZ: Double, userAccX: Double, userAccY: Double, userAccZ: Double)] = []

    // Callback for swing detection
    var onBatchReady: ((_ accelBatch: [(timestamp: TimeInterval, x: Double, y: Double, z: Double)],
                        _ motionBatch: [(timestamp: TimeInterval, rotX: Double, rotY: Double, rotZ: Double, gravX: Double, gravY: Double, gravZ: Double, userAccX: Double, userAccY: Double, userAccZ: Double)]) -> Void)?

    // MARK: - Initialization

    init() {
        #if os(watchOS)
        checkHighFrequencyAvailability()
        #endif
    }

    #if os(watchOS)
    private func checkHighFrequencyAvailability() {
        if CMBatchedSensorManager.isAccelerometerSupported &&
           CMBatchedSensorManager.isDeviceMotionSupported {
            batchedManager = CMBatchedSensorManager()
            sensorRate = .highFrequency
            logger.info("High-frequency sensors available (800Hz accel / 200Hz motion)")
        } else {
            sensorRate = .standard
            logger.info("Using standard sensors (100Hz)")
        }
    }
    #endif

    // MARK: - Start Collection

    func startCollection() {
        guard !isCollecting else { return }
        isCollecting = true
        accelerometerBuffer.removeAll()
        deviceMotionBuffer.removeAll()

        #if os(watchOS)
        if sensorRate == .highFrequency, let batchedManager {
            startHighFrequencyCollection(batchedManager)
        } else {
            startStandardCollection()
        }
        #else
        startStandardCollection()
        #endif

        logger.info("Started motion collection at \(self.sensorRate.rawValue)")
    }

    // MARK: - Stop Collection

    func stopCollection() {
        guard isCollecting else { return }
        isCollecting = false

        #if os(watchOS)
        accelTask?.cancel()
        motionTask?.cancel()
        accelTask = nil
        motionTask = nil
        #endif

        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()

        logger.info("Stopped motion collection. Accel buffer: \(self.accelerometerBuffer.count), Motion buffer: \(self.deviceMotionBuffer.count)")
    }

    // MARK: - Standard Collection (100Hz, all Apple Watch models)

    private func startStandardCollection() {
        motionManager.accelerometerUpdateInterval = 1.0 / 100.0  // 100Hz
        motionManager.deviceMotionUpdateInterval = 1.0 / 100.0

        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self, let data else { return }
            let entry = (timestamp: data.timestamp, x: data.acceleration.x, y: data.acceleration.y, z: data.acceleration.z)
            self.accelerometerBuffer.append(entry)
            self.latestAcceleration = data.acceleration
        }

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self, let motion else { return }
            let entry = (
                timestamp: motion.timestamp,
                rotX: motion.rotationRate.x, rotY: motion.rotationRate.y, rotZ: motion.rotationRate.z,
                gravX: motion.gravity.x, gravY: motion.gravity.y, gravZ: motion.gravity.z,
                userAccX: motion.userAcceleration.x, userAccY: motion.userAcceleration.y, userAccZ: motion.userAcceleration.z
            )
            self.deviceMotionBuffer.append(entry)
            self.latestRotationRate = motion.rotationRate

            // Process batches every 1 second (~100 samples)
            if self.accelerometerBuffer.count >= 100 {
                self.processBatch()
            }
        }
    }

    // MARK: - High Frequency Collection (800Hz accel / 200Hz motion, Series 8+)

    #if os(watchOS)
    private func startHighFrequencyCollection(_ manager: CMBatchedSensorManager) {
        // 800Hz accelerometer stream
        accelTask = Task {
            do {
                for try await batch in manager.accelerometerUpdates() {
                    guard !Task.isCancelled else { break }
                    for dataPoint in batch {
                        let entry = (
                            timestamp: dataPoint.timestamp,
                            x: dataPoint.acceleration.x,
                            y: dataPoint.acceleration.y,
                            z: dataPoint.acceleration.z
                        )
                        await MainActor.run {
                            self.accelerometerBuffer.append(entry)
                            self.latestAcceleration = dataPoint.acceleration
                        }
                    }
                }
            } catch {
                logger.error("Accelerometer stream error: \(error.localizedDescription)")
            }
        }

        // 200Hz device motion stream
        motionTask = Task {
            do {
                for try await batch in manager.deviceMotionUpdates() {
                    guard !Task.isCancelled else { break }
                    for dataPoint in batch {
                        let entry = (
                            timestamp: dataPoint.timestamp,
                            rotX: dataPoint.rotationRate.x, rotY: dataPoint.rotationRate.y, rotZ: dataPoint.rotationRate.z,
                            gravX: dataPoint.gravity.x, gravY: dataPoint.gravity.y, gravZ: dataPoint.gravity.z,
                            userAccX: dataPoint.userAcceleration.x, userAccY: dataPoint.userAcceleration.y, userAccZ: dataPoint.userAcceleration.z
                        )
                        await MainActor.run {
                            self.deviceMotionBuffer.append(entry)
                            self.latestRotationRate = dataPoint.rotationRate
                        }
                    }
                    // Process after each batch delivery (~1 second)
                    await MainActor.run {
                        self.processBatch()
                    }
                }
            } catch {
                logger.error("Device motion stream error: \(error.localizedDescription)")
            }
        }
    }
    #endif

    // MARK: - Batch Processing

    private func processBatch() {
        let accelBatch = accelerometerBuffer
        let motionBatch = deviceMotionBuffer
        accelerometerBuffer.removeAll(keepingCapacity: true)
        deviceMotionBuffer.removeAll(keepingCapacity: true)

        onBatchReady?(accelBatch, motionBatch)
    }

    // MARK: - Get Remaining Buffered Data

    func flushBuffers() -> (accel: [(timestamp: TimeInterval, x: Double, y: Double, z: Double)],
                            motion: [(timestamp: TimeInterval, rotX: Double, rotY: Double, rotZ: Double, gravX: Double, gravY: Double, gravZ: Double, userAccX: Double, userAccY: Double, userAccZ: Double)]) {
        let accel = accelerometerBuffer
        let motion = deviceMotionBuffer
        accelerometerBuffer.removeAll()
        deviceMotionBuffer.removeAll()
        return (accel, motion)
    }
}
