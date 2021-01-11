//
//  LogginUtils.swift
//  CommunicationDemo
//
//  Created by Dariy Kordiyak on 11.01.2021.
//

import Foundation

protocol Logging {}

extension Logging {
    
    // log
    func log(_ msg: String, logLevel: LogLevel = .log) {
        LogMessage(String(describing: type(of: self)), logLevel, msg)
    }
    static func log(_ msg: String, logLevel: LogLevel = .log) {
        LogMessage(String(describing: self), logLevel, msg)
    }
    
    // debug
    func debug(_ msg: String) {
        self.log(msg, logLevel: .debug)
    }
    static func debug(_ msg: String) {
        self.log(msg, logLevel: .debug)
    }
    
    // info
    func info(_ msg: String) {
        self.log(msg, logLevel: .info)
    }
    static func info(_ msg: String) {
        self.log(msg, logLevel: .info)
    }
    
    // warn
    func warn(_ msg: String) {
        self.log(msg, logLevel: .warn)
    }
    static func warn(_ msg: String) {
        self.log(msg, logLevel: .warn)
    }
    
    // error
    func error(_ msg: String) {
        self.log(msg, logLevel: .error)
    }
    static func error(_ msg: String) {
        self.log(msg, logLevel: .error)
    }
    
    // Level
    func setLogLevel(_ logLevel: LogLevel) {
        LoggingManager.shared.currentLogLevel = logLevel
    }
    
}
