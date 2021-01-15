//
//  SessionManager.swift
//  CommunicationDemo WatchKit Extension
//
//  Created by Dariy Kordiyak on 14.01.2021.
//

import Foundation
import WatchKit
import WatchConnectivity
import HealthKit

protocol SessionManagerDelegate: class {
    func didReceive(message: String)
}

final class SessionManager: NSObject, Logging {
    
    // MARK: - Properties
    
    static let shared = SessionManager()
    
    weak var delegate: SessionManagerDelegate?
    var wcSession = WCSession.default
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutState: HKWorkoutSessionState = .notStarted
    
    /// simplified version of our Legacy app, we don't need to support .locked / .unlocked states without user login support
    private var desiredForegroundState: Int?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        
        setDesiredForegroundState()
    }
    
    // MARK: - API
    
    func setDesiredForegroundState() {
        guard desiredForegroundState == nil else {
            log("error: ForegroundStateError.lockOperationInProgress")
            return
        }
        desiredForegroundState = 0
        transitionWorkoutTowardsDesiredState()
    }
    
    func activateSession() {
        guard WCSession.isSupported() else {
            log("FATAL: WCSession not supported")
            fatalError("WCSession not suppoted")
        }
        wcSession.delegate = self
        wcSession.activate()
    }
    
    func sendMessage(parameter: String) {
        guard wcSession.isReachable else {
            log("WARNING: sendMessage iPhone not reachable")
            return
        }
        log("sendMessage")
        
        let message = ["key": "from Watch: \(parameter)"]
        wcSession.sendMessage(message) { [weak self] response in
            guard let responsePayload = response["key"] as? String else {
                self?.log("FATAL: wrong response format")
                fatalError("FATAL: wrong response format")
            }
            self?.log("sendMessage -> response received: \(responsePayload)")
        } errorHandler: { [weak self] error in
            self?.log("WARNING: sendMessage errorHandler: \(error)")
        }
    }
    
    private func transitionWorkoutTowardsDesiredState() {
        guard desiredForegroundState != nil else {
            log("transitionWorkoutTowardsDesiredState did not complete: desiredForegroundState == nil")
            return
        }
        
        log("transitionWorkoutTowardsDesiredState, sessionState: \(String(describing: workoutSession?.state.toString()))")
                
        switch workoutSession?.state {
        case nil:
            createWorkoutSession()
            transitionWorkoutTowardsDesiredState()
        case .notStarted:
            workoutSession?.prepare()
        case .prepared:
            desiredForegroundStateAchieved()
        case .running, .paused, .stopped:
            // We don't ever expect to get into these states.
            // The expected progression through the workout states is:
            // nil (unlocked) -> notStarted -> prepared (locked) -> ended -> back to nil (unlocked)
            warn("Unexpected session state: \(workoutSession?.state.toString() ?? "nil")")
            // Still end the session to get back to an expected state
            workoutSession?.end()
        case .ended:
            workoutSession = nil
            transitionWorkoutTowardsDesiredState()
        @unknown default:
            warn("Unknown session state: \(workoutSession?.state.toString() ?? "nil")")
        }
    }
    
    private func desiredForegroundStateAchieved() {
        desiredForegroundState = nil
    }
    
    // MARK: - Workout
    
    private func workoutConfiguration() -> HKWorkoutConfiguration {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .walking
        configuration.locationType = .indoor
        
        return configuration
    }
    
    private func createWorkoutSession() {
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore,
                                           configuration: workoutConfiguration())
            workoutSession?.delegate = self
        } catch {
            log("failed to create workout session")
            return
        }
                
        log("createWorkoutSession")
    }

}

extension SessionManager: WCSessionDelegate {
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        log("activationDidCompleteWith state: \(activationState.toString()), error: \(String(describing: error))")
        
        switch activationState {
        case .notActivated:
            log("activationDidCompleteWith: .notActivated")
        case .inactive:
            log("activationDidCompleteWith: .inactive")
        case .activated:
            log("activationDidCompleteWith: .activated")
        @unknown default:
            log("activationDidCompleteWith unknown state")
            fatalError()
        }
    }
    
    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any]) {
        log("didReceiveMessage: \(message)")
        if let messagePayload = message["key"] as? String {
            DispatchQueue.main.async {
                self.delegate?.didReceive(message: messagePayload)
            }
        }
    }
    
    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any],
                 replyHandler: @escaping ([String : Any]) -> Void) {
        log("didReceiveMessage with reply handler: \(message)")
        
        guard message["cmd"] as? String == "getLogs" else {
            return
        }
        
        guard let logZipFileUrl = LoggingManager.shared.loggedDataZip else {
            replyHandler(["success": false])
            return
        }
        wcSession.transferFile(logZipFileUrl, metadata: ["type": "log"])
        replyHandler(["success": true])
    }
    
    func sessionCompanionAppInstalledDidChange(_ session: WCSession) {
        log("sessionCompanionAppInstalledDidChange")
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        log("sessionReachabilityDidChange, isReachable: \(session.isReachable), activationState: \(session.activationState.toString())")
    }
    
    func session(_ session: WCSession,
                 didFinish fileTransfer: WCSessionFileTransfer,
                 error: Error?) {
        var msg = "session(didFinish:error) called"

        if let error = error {
            self.error("Error: \(error.localizedDescription)")
            return
        }

        if let type = fileTransfer.file.metadata?["type"] as? String {
            msg += " (type = \(type))"
        }

        msg += " (filename = \(fileTransfer.file.fileURL))"

        log(msg)
    }
    
}

extension SessionManager: HKWorkoutSessionDelegate {
    
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        log("workoutSession didChangeTo: \(toState.toString()) from: \(fromState.toString()), date: \(date)")

        workoutState = toState
        
        transitionWorkoutTowardsDesiredState()
    }

    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didFailWithError error: Error) {
        log("workoutSession didFailWithError: \(error)")
    }

    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didGenerate event: HKWorkoutEvent) {
        log("workoutSession didGenerate: \(event)")
    }
    
}

