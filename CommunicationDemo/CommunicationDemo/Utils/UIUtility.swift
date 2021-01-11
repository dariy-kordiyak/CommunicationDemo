//
//  UIUtility.swift
//  CommunicationDemo
//
//  Created by Dariy Kordiyak on 09.01.2021.
//

import Foundation

final class UIUtility {
    
    static public var appVersionStr: String = {
        // Get the app version string
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "?"
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?.?"
        let buildNum = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return appName + "_" + version + "_" + buildNum
    } ()

    static public var osVersionStr: String  {
        return ProcessInfo().operatingSystemVersionString
    }

    static public var modelStr: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
}
