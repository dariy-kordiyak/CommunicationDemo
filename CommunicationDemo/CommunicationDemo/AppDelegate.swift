//
//  AppDelegate.swift
//  CommunicationDemo
//
//  Created by Dariy Kordiyak on 04.01.2021.
//

import UIKit
import HealthKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, Logging {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setLogLevel(.log)
        log("didFinishLaunchingWithOptions")
        SessionHandler.shared.configureWatchConnectivitySession()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        log("configurationForConnecting")
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        log("didDiscardSceneSessions")
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
        log("applicationShouldRequestHealthAuthorization")
        let healthStore = HKHealthStore()
        healthStore.handleAuthorizationForExtension { [weak self] (success, error) in
            if let error = error {
                self?.log("handleAuthorizationForExtensionWithCompletion with error: \(error.localizedDescription)")
            } else {
                self?.log("handleAuthorizationForExtensionWithCompletion with success \(success)")
            }
        }
    }
    
    func application(_ application: UIApplication,
                     handleWatchKitExtensionRequest userInfo: [AnyHashable : Any]?,
                     reply: @escaping ([AnyHashable : Any]?) -> Void) {
        log("handleWatchKitExtensionRequest \(String(describing: userInfo))")
    }

}

