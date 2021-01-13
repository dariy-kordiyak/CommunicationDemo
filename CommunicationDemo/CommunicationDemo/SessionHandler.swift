//
//  SessionHandler.swift
//  CommunicationDemo
//
//  Created by Dariy Kordiyak on 11.01.2021.
//

import Foundation
import WatchConnectivity

protocol SessionHandlerDelegate: class {
    func sessionHandler(_ hander: SessionHandler, didReceiveMessage message: String)
}

final class SessionHandler: NSObject, Logging {
    
    // MARK: - Properties
    
    static let shared = SessionHandler()
    weak var delegate: SessionHandlerDelegate?
    var wcSession = WCSession.default
    
    // MARK: - API
    
    func configureWatchConnectivitySession() {
        guard WCSession.isSupported() else {
            log("FATAL: WCSession not supported")
            fatalError("WCSession not suppoted")
        }
        
        wcSession.delegate = self
        wcSession.activate()
        
        log("isReachable: \(wcSession.isReachable)")
    }
    
}

extension SessionHandler: WCSessionDelegate {
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        log("activationDidCompleteWith state: \(activationState), error: \(String(describing: error))")
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
        log("sessionWatchStateDidChange, isReachable: \(session.isReachable), activationState: \(session.activationState)")
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
