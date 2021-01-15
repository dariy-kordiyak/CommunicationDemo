//
//  AppSettings.swift
//  CommunicationDemo
//
//  Created by Dariy Kordiyak on 09.01.2021.
//

import Foundation

final class AppSettings {
    
    // MARK: - Properties
    
    static let shared = AppSettings()
    
    static let timerRunCount = 15000
    static let timerInterval = 5
    
    private enum UserDefaultsKeys: String {
        case activeLoggingFileIndex
    }
    
    var activeLoggingFileIndex: Int {
        get {
            return getUserDefaultsInt(.activeLoggingFileIndex)
        }
        set {
            setUserDefaultsInt(.activeLoggingFileIndex, newValue: newValue)
        }
    }

    // MARK: - Private
    
    private func setUserDefaultsInt(_ key: UserDefaultsKeys, newValue: Int) {
        UserDefaults.standard.set(newValue, forKey: key.rawValue)
    }
    
    private func getUserDefaultsInt(_ key: UserDefaultsKeys, defaultValue: Int = 0) -> Int {
        if UserDefaults.standard.object(forKey: key.rawValue) == nil {
            return defaultValue
        } else {
            return UserDefaults.standard.integer(forKey: key.rawValue)
        }
    }
    
}
