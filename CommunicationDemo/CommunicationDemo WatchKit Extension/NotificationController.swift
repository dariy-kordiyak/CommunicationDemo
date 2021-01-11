//
//  NotificationController.swift
//  CommunicationDemo WatchKit Extension
//
//  Created by Dariy Kordiyak on 04.01.2021.
//

import WatchKit
import Foundation
import UserNotifications

class NotificationController: WKUserNotificationInterfaceController, Logging {

    override init() {
        // Initialize variables here.
        super.init()
        
        // Configure interface objects here.
        log("NotificationController -> init")
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        log("NotificationController -> willActivate")
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        log("NotificationController -> didDeactivate")
    }

    override func didReceive(_ notification: UNNotification) {
        // This method is called when a notification needs to be presented.
        // Implement it if you use a dynamic notification interface.
        // Populate your dynamic notification interface as quickly as possible.
        log("NotificationController -> didReceive(_ notification)")
    }
}
