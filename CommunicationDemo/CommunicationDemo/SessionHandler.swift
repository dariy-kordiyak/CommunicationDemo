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
    
    enum PhoneToWatchCmd: String {
        case getLogs
        case setStartingUp
    }
    
    static let shared = SessionHandler()
    weak var delegate: SessionHandlerDelegate?
    var wcSession = WCSession.default
    private var healthStore: HKHealthStore = HKHealthStore()
    private var startWatchAppCounter: Int = 0
    private var logPullCompletionHandler: ((_ fileUrl: URL?, _ error: Error?) -> Void)?
    
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
            self?.sendStartingUpRequest()
        })
        startWatchAppCounter += 1
    }
    
    func getLogs(completion: @escaping (_ fileUrl: URL?, _ error: Error?) -> Void) {
        sendWatchRequestGetLogs()
        logPullCompletionHandler = completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            let error = NSError(domain: "WatchSensorModel",
                                code: 1,
                                userInfo: [NSLocalizedDescriptionKey: "Request timed out"])
            if let handler = self.logPullCompletionHandler {
                self.logPullCompletionHandler = nil
                handler(nil, error)
            }
        }
    }
    
    // MARK: - Private
    
    private func sendWatchRequestGetLogs() {
        let request = PhoneToWatchCmd.getLogs
        log("sendWatchRequestGetLogs")
        sendRequest(request: request, msg: ["cmd": request.rawValue])
    }
    
    private func sendStartingUpRequest() {
        let request = PhoneToWatchCmd.setStartingUp
        log("sendStartingUpRequest")
        sendRequest(request: request, msg: ["cmd": request.rawValue])
    }
    
    @discardableResult
    private func sendRequest(request: PhoneToWatchCmd, msg: [String: Any], isPing: Bool = false) -> Bool {
        let pingStr = isPing ? "[ping]" : ""
        if !isPing {
            log("Sending \(request) \(pingStr) cmd at \(TimeUtil.nowUTCTimestamp())")
        } else {
            debug("Sending \(request) \(pingStr) cmd at \(TimeUtil.nowUTCTimestamp())")
        }

        wcSession.sendMessage(msg) { (dict) in
            
        } errorHandler: { [weak self] (error) in
            self?.logPullCompletionHandler?(nil, error)
            self?.logPullCompletionHandler = nil
        }

        return true
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
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        log("session(didReceive file:\(file.fileURL))")
        if let type = file.metadata?["type"] as? String {
            if type == "log" {
                if let handler = logPullCompletionHandler {
                    logPullCompletionHandler = nil
                    handler(file.fileURL, nil)
                }
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        log("session(didReceiveUserInfo)")
    }
    
}
