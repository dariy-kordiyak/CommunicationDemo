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
    
    private var sessionManager = SessionManager.shared
    private var timer: Timer?
    private var timerRunCount = 0

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
        sessionManager.activateSession()
        sessionManager.delegate = self
        log("isCompanionAppInstalled: \(sessionManager.wcSession.isCompanionAppInstalled)")
        log("isReachable: \(sessionManager.wcSession.isReachable)")
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        log("willActivate")
        log("isCompanionAppInstalled: \(sessionManager.wcSession.isCompanionAppInstalled)")
        log("isReachable: \(sessionManager.wcSession.isReachable)")
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        log("didDeactivate")
    }
    
    // MARK: - Actions

    @IBAction private func actionButtonPressed() {
        log("actionButtonPressed")
        sessionManager.sendMessage(parameter: "action button")
    }
    
    @objc private func timerFired() {
        log("timerFired")
        timerRunCount += 1
        if timerRunCount == 1500 {
            log("timer invalidated")
            timer?.invalidate()
        }
        else {
            sessionManager.sendMessage(parameter: "\(timerRunCount)")
        }
    }
    
}

extension InterfaceController: SessionManagerDelegate {
    
    func didReceive(message: String) {
        textLabel.setText(message)
    }
    
}
