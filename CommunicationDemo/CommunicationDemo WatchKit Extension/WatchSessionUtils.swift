//
//  WatchSessionUtils.swift
//  CommunicationDemo WatchKit Extension
//
//  Created by Dariy Kordiyak on 13.01.2021.
//

import Foundation
import HealthKit

extension HKWorkoutSessionState {
    
    func toString() -> String {
        switch self {
        case .notStarted:
            return "notStarted"
        case .running:
            return "running"
        case .ended:
            return "ended"
        case .paused:
            return "paused"
        case .prepared:
            return "prepared"
        case .stopped:
            return "stopped"
        @unknown default:
            return "unknown default"
        }
    }
    
}
