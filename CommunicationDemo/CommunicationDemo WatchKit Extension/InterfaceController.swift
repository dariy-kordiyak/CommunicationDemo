//
//  InterfaceController.swift
//  CommunicationDemo WatchKit Extension
//
//  Created by Dariy Kordiyak on 04.01.2021.
//

import WatchKit
import WatchConnectivity
import HealthKit
import Foundation

class InterfaceController: WKInterfaceController, Logging {
    
    // MARK: - Properties
    
    private var wcSession = WCSession.default
    private var timer: Timer?
    private var timerRunCount = 0
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutState: HKWorkoutSessionState = .notStarted

    @IBOutlet private weak var textLabel: WKInterfaceLabel!
    @IBOutlet private weak var dateLabel: WKInterfaceDate!
    @IBOutlet private weak var actionButton: WKInterfaceButton!
    
    // MARK: - Lifecycle
    
    override func awake(withContext context: Any?) {
        // Configure interface objects here.
        super.awake(withContext: context)
        log("awake")
        timer = Timer.scheduledTimer(timeInterval: 5,
                                     target: self,
                                     selector: #selector(timerFired),
                                     userInfo: nil,
                                     repeats: true)
        activateSession()
        log("isCompanionAppInstalled: \(wcSession.isCompanionAppInstalled)")
        log("isReachable: \(wcSession.isReachable)")
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        log("willActivate")
        log("isCompanionAppInstalled: \(wcSession.isCompanionAppInstalled)")
        log("isReachable: \(wcSession.isReachable)")
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        log("didDeactivate")
    }
    
    // MARK: - Actions

    @IBAction private func actionButtonPressed() {
        log("actionButtonPressed")
        sendMessage(parameter: "action button")
    }
    
    @objc private func timerFired() {
        log("timerFired")
        timerRunCount += 1
        if timerRunCount == 1500 {
            log("timer invalidated")
            timer?.invalidate()
        }
        else {
            sendMessage(parameter: "\(timerRunCount)")
        }
    }
        
    // MARK: - Private
    
    private func activateSession() {
        guard WCSession.isSupported() else {
            log("FATAL: WCSession not supported")
            fatalError("WCSession not suppoted")
        }
        wcSession.delegate = self
        wcSession.activate()
    }
    
    private func sendMessage(parameter: String) {
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

extension InterfaceController: WCSessionDelegate {
    
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
            createWorkoutSession()
        @unknown default:
            log("activationDidCompleteWith unknown state")
            fatalError()
        }
    }
    
    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any]) {
        log("didReceiveMessage: \(message)")
        guard let messagePayload = message["key"] as? String else {
            log("WARNING: message payload wrong")
            return
        }
        textLabel.setText(messagePayload)
    }
    
    func sessionCompanionAppInstalledDidChange(_ session: WCSession) {
        log("sessionCompanionAppInstalledDidChange")
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        log("sessionReachabilityDidChange, isReachable: \(session.isReachable), activationState: \(session.activationState.toString())")
    }
    
}

extension InterfaceController: HKWorkoutSessionDelegate {

    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        log("workoutSession didChangeTo: \(toState.toString()) from: \(fromState.toString()), date: \(date)")

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
