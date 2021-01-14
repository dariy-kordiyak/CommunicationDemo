//
//  SessionHandler.swift
//  CommunicationDemo
//
//  Created by Dariy Kordiyak on 11.01.2021.
//

import Foundation
import WatchConnectivity
import HealthKit

protocol SessionHandlerDelegate: class {
    func sessionHandler(_ hander: SessionHandler, didReceiveMessage message: String)
}

final class SessionHandler: NSObject, Logging {
    
    // MARK: - Properties
    
    static let shared = SessionHandler()
    weak var delegate: SessionHandlerDelegate?
    var wcSession = WCSession.default
    private var healthStore: HKHealthStore = HKHealthStore()
    private var startWatchAppCounter: Int = 0
    
    // MARK: - API
    
    func authorizeHealthKit(completion: @escaping ((_ success: Bool,
                                                    _ error: Error?) -> Void)) {
        guard HKHealthStore.isHealthDataAvailable() else {
            log("isHealthDataAvailable == false")
            completion(false, nil)
            return
        }
        
        let typesToWrite: Set = [
            HKSampleType.quantityType(forIdentifier: .bodyMass)!
        ]
        
        let typesToRead: Set = [
            HKSampleType.quantityType(forIdentifier: .bodyMass)!,
            HKSampleType.quantityType(forIdentifier: .heartRate)!,
            HKSampleType.quantityType(forIdentifier: .stepCount)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToWrite,
                                         read: typesToRead) { [weak self] (success, error) in
            self?.log("authorizeHealthKit with success: \(success), error: \(String(describing: error))")
            completion(success, error)
        }
    }
    
    func configureWatchConnectivitySession() {
        guard WCSession.isSupported() else {
            log("FATAL: WCSession not supported")
            fatalError("WCSession not suppoted")
        }
        
        wcSession.delegate = self
        wcSession.activate()
                
        log("isReachable: \(wcSession.isReachable)")
    }
    
    func startWatchApp() {
        let config = HKWorkoutConfiguration()
        config.activityType = .walking
        config.locationType = .indoor

        log("Attempting to start watch app (\(startWatchAppCounter))")
        healthStore.startWatchApp(with: config, completion: {[weak self, startWatchAppCounter] success, error in
            self?.log("Received response from startWatchApp (\(startWatchAppCounter)), isSuccess: \(success)")
        })
        startWatchAppCounter += 1
    }
    
}

extension SessionHandler: WCSessionDelegate {
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        log("activationDidCompleteWith state: \(activationState.toString()), error: \(String(describing: error))")
        
        switch activationState {
        case .notActivated:
            log("activationDidCompleteWith .notActivated")
        case .inactive:
            log("activationDidCompleteWith .inactive")
        case .activated:
            log("activationDidCompleteWith .activated")
            startWatchApp()
        @unknown default:
            log("Session state unknown")
            fatalError("Session state unknown")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        log("sessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        log("sessionDidDeactivate")
        /// Switching of paired devices requires session to re-activate
        wcSession.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        log("sessionWatchStateDidChange, isReachable: \(session.isReachable), activationState: \(session.activationState.toString())")
    }
    
    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any],
                 replyHandler: @escaping ([String : Any]) -> Void) {
        log("didReceiveMessage: \(message)")
        
        delegate?.sessionHandler(self, didReceiveMessage: (message["key"] as? String) ?? "")
        
        let response: [String: Any] = ["key": "iPhone received"]
        replyHandler(response)
    }
    
}
