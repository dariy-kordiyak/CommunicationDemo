//
//  HealthKitHandler.swift
//  CommunicationDemo WatchKit Extension
//
//  Created by Dariy Kordiyak on 12.01.2021.
//

import Foundation
import HealthKit

final class HealthKitHandler: NSObject, Logging {
    
    // MARK: - Properties
    
    static let shared = HealthKitHandler()
    
    private let healthStore = HKHealthStore()
    private var isRunning = false
    
    // MARK: - Configuration
    
    func authorizeHealthKit(completion: @escaping ((_ success: Bool,
                                                    _ error: Error?) -> Void)) {
        guard HKHealthStore.isHealthDataAvailable() else {
            log("HealthKitHandler -> isHealthDataAvailable == false")
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
            self?.log("HealthKitHandler -> authorizeHealthKit with success: \(success), error: \(String(describing: error))")
            completion(success, error)
        }
    }
        
    // MARK: - State
    
    func start() {
        guard !isRunning else {
            return
        }
        log("HealthKitHandler -> start")
        isRunning = true
    }
    
    func stop() {
        log("HealthKitHandler -> stop")
        isRunning = false
    }
    
}
