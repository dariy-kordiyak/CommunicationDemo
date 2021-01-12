//
//  SessionHandler.swift
//  CommunicationDemo
//
//  Created by Dariy Kordiyak on 11.01.2021.
//

import Foundation
import WatchConnectivity

final class SessionHandler: NSObject, Logging {
    
    // MARK: - Properties
    
    static let shared = SessionHandler()
    var wcSession = WCSession.default
    
    // MARK: - API
    
    func configureWatchConnectivitySession() {
        guard WCSession.isSupported() else {
            log("SessionHandler -> FATAL: WCSession not supported")
            fatalError("WCSession not suppoted")
        }
        
        wcSession.delegate = self
        wcSession.activate()
        
        log("SessionHandler -> isReachable: \(wcSession.isReachable)")
    }
    
}

extension SessionHandler: WCSessionDelegate {
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        log("SessionHandler -> activationDidCompleteWith state: \(activationState), error: \(String(describing: error))")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        log("SessionHandler -> sessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        log("SessionHandler -> sessionDidDeactivate")
        /// Switching of paired devices requires session to re-activate
        wcSession.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        log("SessionHandler -> sessionWatchStateDidChange, isReachable: \(session.isReachable), activationState: \(session.activationState)")
    }
    
    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any],
                 replyHandler: @escaping ([String : Any]) -> Void) {
        log("SessionHandler -> didReceiveMessage: \(message)")
        guard message["key"] as? String == "message" else {
            log("SessionHandler -> WARNING: wrong message payload")
            return
        }
        
        let response: [String: Any] = ["message": "test"]
        replyHandler(response)
    }
    
}
