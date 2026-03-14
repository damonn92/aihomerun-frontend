import Foundation
import WatchConnectivity
import os.log

/// Handles communication between Apple Watch and iPhone
/// On Watch: sends session data to iPhone
/// On iPhone: receives session data from Watch
final class WatchConnectivityService: NSObject, ObservableObject {

    static let shared = WatchConnectivityService()

    private let logger = Logger(subsystem: "com.aihomerun", category: "WatchConnectivity")

    // MARK: - Published State
    @Published var isReachable = false
    @Published var isPaired = false
    @Published var isWatchAppInstalled = false
    @Published var lastReceivedSession: SwingSession?
    @Published var transferProgress: Double = 0

    // Callbacks
    var onSessionReceived: ((SwingSession) -> Void)?
    var onSwingDetected: ((SwingEvent) -> Void)?
    var onPlayerInfoRequested: (() -> (name: String, age: Int, hand: BattingHand)?)?

    private override init() {
        super.init()
    }

    // MARK: - Activation

    func activate() {
        guard WCSession.isSupported() else {
            logger.warning("WatchConnectivity not supported on this device")
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        logger.info("WatchConnectivity session activating...")
    }

    // MARK: - Send Session Data (Watch → iPhone)

    func sendSessionToPhone(_ session: SwingSession) {
        guard WCSession.default.isReachable else {
            // Phone not reachable — queue as file transfer
            transferSessionAsFile(session)
            return
        }

        do {
            let data = try JSONEncoder().encode(session)
            WCSession.default.sendMessageData(data, replyHandler: { _ in
                self.logger.info("Session sent to iPhone successfully")
            }, errorHandler: { error in
                self.logger.error("Failed to send session: \(error.localizedDescription)")
                // Fallback to file transfer
                self.transferSessionAsFile(session)
            })
        } catch {
            logger.error("Failed to encode session: \(error.localizedDescription)")
        }
    }

    private func transferSessionAsFile(_ session: SwingSession) {
        do {
            let data = try JSONEncoder().encode(session)
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("session_\(session.id.uuidString).json")
            try data.write(to: tempURL)

            let transfer = WCSession.default.transferFile(tempURL, metadata: [
                WatchMessageKey.sessionComplete: true
            ])
            logger.info("Session queued as file transfer: \(transfer.progress.fractionCompleted)")
        } catch {
            logger.error("Failed to queue session file: \(error.localizedDescription)")
        }
    }

    // MARK: - Send Real-Time Swing Update (Watch → iPhone)

    func sendSwingUpdate(_ event: SwingEvent) {
        guard WCSession.default.isReachable else { return }

        do {
            let data = try JSONEncoder().encode(event)
            let message: [String: Any] = [
                WatchMessageKey.swingDetected: data
            ]
            WCSession.default.sendMessage(message, replyHandler: nil)
        } catch {
            logger.error("Failed to send swing update: \(error.localizedDescription)")
        }
    }

    // MARK: - Send Heart Rate Update (Watch → iPhone)

    func sendHeartRateUpdate(_ heartRate: Double) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(
            [WatchMessageKey.heartRateUpdate: heartRate],
            replyHandler: nil
        )
    }

    // MARK: - Request Player Info (Watch → iPhone)

    func requestActivePlayer() {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(
            [WatchMessageKey.requestActivePlayer: true],
            replyHandler: { response in
                self.logger.info("Received player info from iPhone")
            }
        )
    }

    // MARK: - Send Start/Stop Commands (iPhone → Watch)

    func sendStartSession(playerName: String, playerAge: Int, battingHand: BattingHand) {
        guard WCSession.default.isReachable else {
            logger.warning("Watch not reachable for start command")
            return
        }

        let message: [String: Any] = [
            WatchMessageKey.startSession: true,
            WatchMessageKey.playerName: playerName,
            WatchMessageKey.playerAge: playerAge,
            WatchMessageKey.battingHand: battingHand.rawValue
        ]

        WCSession.default.sendMessage(message, replyHandler: nil)
    }

    func sendStopSession() {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(
            [WatchMessageKey.stopSession: true],
            replyHandler: nil
        )
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            #if os(iOS)
            self.isPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
            #endif
        }
        logger.info("WC activation complete: \(activationState.rawValue)")
    }

    // Required on iOS
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        logger.info("WC session became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        logger.info("WC session deactivated, reactivating...")
        session.activate()
    }
    #endif

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    // MARK: - Receive Messages

    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        // Received session data
        do {
            let swingSession = try JSONDecoder().decode(SwingSession.self, from: messageData)
            DispatchQueue.main.async {
                self.lastReceivedSession = swingSession
                self.onSessionReceived?(swingSession)
            }
            replyHandler(Data("OK".utf8))
            logger.info("Received session with \(swingSession.swingCount) swings")
        } catch {
            logger.error("Failed to decode session: \(error.localizedDescription)")
            replyHandler(Data("ERROR".utf8))
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Handle swing update
        if let swingData = message[WatchMessageKey.swingDetected] as? Data {
            do {
                let event = try JSONDecoder().decode(SwingEvent.self, from: swingData)
                DispatchQueue.main.async {
                    self.onSwingDetected?(event)
                }
            } catch {
                logger.error("Failed to decode swing event: \(error.localizedDescription)")
            }
        }

        // Handle player info request
        if message[WatchMessageKey.requestActivePlayer] != nil {
            if let playerInfo = onPlayerInfoRequested?() {
                let response: [String: Any] = [
                    WatchMessageKey.playerName: playerInfo.name,
                    WatchMessageKey.playerAge: playerInfo.age,
                    WatchMessageKey.battingHand: playerInfo.hand.rawValue
                ]
                if WCSession.default.isReachable {
                    WCSession.default.sendMessage(response, replyHandler: nil)
                }
            }
        }

        // Handle start session command
        if message[WatchMessageKey.startSession] != nil {
            logger.info("Received start session command from iPhone")
        }

        // Handle stop session command
        if message[WatchMessageKey.stopSession] != nil {
            logger.info("Received stop session command from iPhone")
        }

        // Handle heart rate update
        if let hr = message[WatchMessageKey.heartRateUpdate] as? Double {
            logger.debug("Heart rate update: \(hr)")
        }
    }

    // MARK: - Receive Files

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        do {
            let data = try Data(contentsOf: file.fileURL)
            let swingSession = try JSONDecoder().decode(SwingSession.self, from: data)
            DispatchQueue.main.async {
                self.lastReceivedSession = swingSession
                self.onSessionReceived?(swingSession)
            }
            logger.info("Received session file with \(swingSession.swingCount) swings")
        } catch {
            logger.error("Failed to process received file: \(error.localizedDescription)")
        }
    }
}
