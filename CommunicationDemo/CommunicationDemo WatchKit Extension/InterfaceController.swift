//
//  InterfaceController.swift
//  CommunicationDemo WatchKit Extension
//
//  Created by Dariy Kordiyak on 04.01.2021.
//

import WatchKit
import WatchConnectivity
import Foundation

class InterfaceController: WKInterfaceController, Logging {
    
    // MARK: - Properties
    
    private var wcSession = WCSession.default
    private var timer: Timer?
    private var timerRunCount = 0

    @IBOutlet private weak var textLabel: WKInterfaceLabel!
    @IBOutlet private weak var dateLabel: WKInterfaceDate!
    @IBOutlet private weak var actionButton: WKInterfaceButton!
    
    // MARK: - Lifecycle
    
    override func awake(withContext context: Any?) {
        // Configure interface objects here.
        super.awake(withContext: context)
        log("InterfaceController -> awake")
        
        timer = Timer.scheduledTimer(timeInterval: 5,
                                     target: self,
                                     selector: #selector(timerFired),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        log("InterfaceController -> willActivate")
        
        guard WCSession.isSupported() else {
            log("InterfaceController -> FATAL: WCSession not supported")
            fatalError("WCSession not suppoted")
        }
        wcSession.delegate = self
        wcSession.activate()
        
        log("InterfaceController -> isCompanionAppInstalled: \(wcSession.isCompanionAppInstalled)")
        log("InterfaceController -> isReachable: \(wcSession.isReachable)")
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        log("InterfaceController -> didDeactivate")
    }
    
    // MARK: - Actions

    @IBAction private func actionButtonPressed() {
        log("InterfaceController -> actionButtonPressed")
        sendMessage(parameter: "action button")
    }
    
    @objc private func timerFired() {
        log("InterfaceController -> timerFired")
        timerRunCount += 1
        if timerRunCount == 15 {
            log("InterfaceController -> timer invalidated")
            timer?.invalidate()
        }
        else {
            sendMessage(parameter: "\(timerRunCount)")
        }
    }
    
    // MARK: - Private
    
    private func sendMessage(parameter: String) {
        guard wcSession.isReachable else {
            log("InterfaceController -> WARNING: sendMessage iPhone not reachable")
            return
        }
        log("InterfaceController -> sendMessage")
        
        let message = ["key": "from Watch: \(parameter)"]
        wcSession.sendMessage(message) { [weak self] response in
            guard let responsePayload = response["key"] as? String else {
                self?.log("InterfaceController -> FATAL: wrong response format")
                fatalError("InterfaceController -> FATAL: wrong response format")
            }
            DispatchQueue.main.async {
                self?.textLabel.setText("\(responsePayload)")
            }
        } errorHandler: { [weak self] error in
            self?.log("InterfaceController -> WARNING: sendMessage errorHandler: \(error)")
        }
    }
    
}

extension InterfaceController: WCSessionDelegate {
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        log("InterfaceController -> WCSessionDelegate -> activationDidCompleteWith state: \(activationState), error: \(String(describing: error))")
    }
    
    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any]) {
        log("InterfaceController -> WCSessionDelegate -> didReceiveMessage: \(message)")
        guard let messagePayload = message["key"] as? String else {
            log("InterfaceController -> WCSessionDelegate -> WARNING: message payload wrong")
            return
        }
        textLabel.setText(messagePayload)
    }
    
    func sessionCompanionAppInstalledDidChange(_ session: WCSession) {
        log("InterfaceController -> sessionCompanionAppInstalledDidChange")
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        log("InterfaceController -> sessionReachabilityDidChange, isReachable: \(session.isReachable), activationState: \(session.activationState)")
    }
    
}
