//
//  WorkoutSessionManager.swift
//  CommunicationDemo WatchKit Extension
//
//  Created by Dariy Kordiyak on 12.01.2021.
//

import Foundation
import HealthKit

final class WorkoutSessionManager: NSObject, Logging {
    
    // MARK: - Properties
    
    static let shared = WorkoutSessionManager()
    
    private var isRunning = false
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession!
    private var workoutState: HKWorkoutSessionState = .notStarted
    
    // MARK: - State
    
    func getWorkoutState() -> HKWorkoutSessionState {
         // We have to return a cached value because session.state does not immediately get
         // updated after we call store.start(), store.end(), or store.pause()
         if let session = session {
             log("Current session state: \(session.state)")
         }
         return session?.state ?? .notStarted
    }

    func startWorkout() {
        do {
            session = try HKWorkoutSession(healthStore: healthStore,
                                           configuration: workoutConfiguration())
        } catch {
            log("failed to start workout")
            isRunning = false
            return
        }

        log("startWorkout")
        session.delegate = self
    }

    func togglePause() {
        log("togglePause")
        if isRunning {
            pauseWorkout()
        }
        else {
            resumeWorkout()
        }
    }

    func pauseWorkout() {
        log("pauseWorkout")
        isRunning = false
        session.pause()
    }

    func resumeWorkout() {
        log("resumeWorkout")
        isRunning = true
        session.resume()
    }

    func endWorkout() {
        log("endWorkout")
        isRunning = false
        session.end()
    }
    
    // MARK: - Configuration
    
    private func workoutConfiguration() -> HKWorkoutConfiguration {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .walking
        configuration.locationType = .indoor
        
        return configuration
    }
    
}

extension WorkoutSessionManager: HKWorkoutSessionDelegate {

    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        log("workoutSession didChangeTo: \(toState) from: \(fromState), date: \(date)")

        workoutState = toState
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
