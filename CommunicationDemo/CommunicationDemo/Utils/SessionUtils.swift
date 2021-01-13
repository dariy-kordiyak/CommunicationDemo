//
//  SessionUtils.swift
//  CommunicationDemo
//
//  Created by Dariy Kordiyak on 13.01.2021.
//

import Foundation
import WatchConnectivity

extension WCSessionActivationState {
    
    func toString() -> String {
        switch self {
        case .activated: return "activated"
        case .inactive: return "inactive"
        case .notActivated: return "notActivated"
        @unknown default:
            return "unknown default"
        }
    }
    
}
