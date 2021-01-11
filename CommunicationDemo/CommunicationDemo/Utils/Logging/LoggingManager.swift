//
//  LoggingManager.swift
//  CommunicationDemo
//
//  Created by Dariy Kordiyak on 09.01.2021.
//

import Foundation
import Zip

public enum LogLevel: Int {
    case debug = 0
    case log = 1
    case info = 2
    case warn = 3
    case error = 4
    
    var tag: String? {
        switch self {
        case .debug:
            return "[DEBUG]"
        case .log:
            return nil
        case .info:
            return "[INFO]"
        case .warn:
            return "[WARN]"
        case .error:
            return "[ERROR]"
        }
    }
}

public func LogMessage(_ domain: String,
                       _ level: LogLevel,
                       _ format: String,
                       _ args: CVarArg...) {
    let message = String(format: format, arguments: args)
    LoggingManager.shared.logMessage(domain: domain, level: level, message: message)
}

final class LoggingManager {
    
    // MARK: - Properties
    
    static let shared = LoggingManager()
    
    // How many and max allowed size of each logging file
    let maxFileSize: UInt64 = 1000000
    let numLogFiles = 10

    // How often we check if we need to roll to the next log file
    let logFileRollCheckIntervalSec: TimeInterval = 10 * kMinutesPerHour

    // The rolling index of the current log file and number of files we manage
    var logFileIndex = 0

    // The full path to the current log file and handle
    public var curLogFilePath: String?
    var curLogFileH: FileHandle?

    // Periodic time to swap log files
    fileprivate var periodicTimer: Timer?

    // Our domain
    let logDomain = "LoggingModel"

    // Preformed newline
    let newline = "\n".data(using: .utf8)!

    // timestamp formatter for log messages
    var timestampFormatter = DateFormatter()

    // Queue for serializing access to the log file
    let logFileQueue = DispatchQueue(label: "com.dariykordiyak.CommunicationDemo.logQueue")
    
    var currentLogLevel: LogLevel = .log
    
    // MARK: - Initialization
    
    // Setup the logging file, rotate existing one if necessary
    private init() {
        // Init our timestamp formatter for log lines
        timestampFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        // Set the initial log file to be one greater than what we were using last time we
        // launched.
        logFileIndex = nextLogFileIndex(AppSettings.shared.activeLoggingFileIndex)
        AppSettings.shared.activeLoggingFileIndex = logFileIndex
        let newPath = logFilePath(index: logFileIndex)
        try? FileManager.default.removeItem(atPath: newPath)
        setLogFile(pathOpt: newPath)

        // Log a message upon startup
        logMarker("Initializing LoggingModel, logging to: \(newPath)")
        logImportantInfo()

        // Setup periodic timer for rotating log file
        periodicTimer = Timer.scheduledTimerOnMainLoop(timeInterval: logFileRollCheckIntervalSec,
                                             target: self,
                                             selector: #selector(periodicTimerCB),
                                             userInfo: nil, repeats: true)
    }

    // -------------------------------------------------------------------------------------
    // Log a message
    public func logMessage(domain: String, level: LogLevel, message: String) {
        guard self.shouldLog(logLevel: level, currentLogLevel: self.currentLogLevel) else {
            return
        }
//        #if os(watchOS)
//        guard AppSettings.shared.loggingEnabled else {
//            return
//        }
//        #endif
        let outputLine = String(format: "%@ | %@", domain, message)
        let taggedOutputLine = self.addLogLevelTag(level, to: outputLine)
        logString(taggedOutputLine)
    }

    // -------------------------------------------------------------------------------------
    // Log a marker
    public func logMarker(_ message: String) {
        let outputLine = String(format: "\n     ============= %@ ==============", message)
        logString(outputLine)
    }

    // -------------------------------------------------------------------------------------
    // Log a raw string
    public func logString(_ str: String, withTimestamp: Bool = true) {
        // Send to system logs
        NSLog(str)

        // Send to file
        let tsStr = timestampFormatter.string(from: Date())
        let prefix = withTimestamp ? tsStr + " | " : ""
        if let data = (prefix + str).data(using: .utf8) {
            logFileQueue.async {
                [weak self] in
                guard let uSelf = self else { return }

                uSelf.curLogFileH?.write(uSelf.newline)
                uSelf.curLogFileH?.write(data)
            }
        }
    }

    // -----------------------------------------------------------------------------------------
    // Return the logging data
    public var loggedData: Data {
        var allData = Data()
        logFileQueue.sync {
            // Flush all data to the current log file and close it
            let saveLogFile = curLogFilePath
            setLogFile(pathOpt: nil)

            var nextIndex = nextLogFileIndex(logFileIndex)
            while true {
                let logURL = URL(fileURLWithPath: logFilePath(index: nextIndex))
                if let prev = try? Data(contentsOf: logURL) {
                    LogMessage(logDomain, .debug, "Added \(prev.count) bytes from \(logURL)")
                    allData.append(prev)
                }

                if nextIndex == logFileIndex {
                    break
                }
                nextIndex = nextLogFileIndex(nextIndex)
            }

            // Restore log file now
            setLogFile(pathOpt: saveLogFile)
        }

        return allData
    }

    public var loggedDataZip: URL? {
        // Calculate the log zip filename
        let tempDir = (NSTemporaryDirectory() as NSString)
        let zipFilePath = tempDir.appendingPathComponent("log.zip")
        let zipFileURL: URL = URL(fileURLWithPath: zipFilePath)

        // Gather all file URLs
        var logFileURLs: [URL] = []

        logFileQueue.sync {
            // Flush all data to the current log file and close it
            let saveLogFile = curLogFilePath
            setLogFile(pathOpt: nil)

            var nextIndex = nextLogFileIndex(logFileIndex)
            while true {
                let logFilePath = self.logFilePath(index: nextIndex)

                if FileManager.default.fileExists(atPath: logFilePath) {
                    logFileURLs.append(URL(fileURLWithPath: logFilePath))
                }

                if nextIndex == logFileIndex {
                    break
                }
                nextIndex = nextLogFileIndex(nextIndex)
            }

            // Restore log file now
            setLogFile(pathOpt: saveLogFile)

            // Delete zip file if it already exists
            try? FileManager.default.removeItem(at: zipFileURL)
            
            // Zip it up
            do {
                try Zip.zipFiles(paths: logFileURLs,
                                 zipFilePath: zipFileURL,
                                 password: nil,
                                 progress: nil)
            } catch {
                LogMessage(logDomain, .error, "Unable to zip the log file")
                //zipFileURL = nil
            }
        }

        return zipFileURL
    }

    // -----------------------------------------------------------------------------------------
    // Delete log files
    public func deleteLogs() {
        LogMessage(logDomain, .log, "Deleting log files")

        logFileQueue.sync {
            logFileIndex = nextLogFileIndex(logFileIndex)
            AppSettings.shared.activeLoggingFileIndex = logFileIndex
            let newPath = logFilePath(index: logFileIndex)
            try? FileManager.default.removeItem(atPath: newPath)
            setLogFile(pathOpt: newPath)

            let fileManager = FileManager.default
            let documentsDirectory =  fileManager.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
            do {
                if let documentPath = documentsDirectory.path {
                    let fileNames = try fileManager.contentsOfDirectory(atPath: "\(documentPath)")
                    for fileName in fileNames {
                        if fileName.hasPrefix("log") && fileName != "log\(logFileIndex).txt" {
                            let filePathName = "\(documentPath)/\(fileName)"
                            try fileManager.removeItem(atPath: filePathName)
                        }
                    }
                }
            } catch {
                LogMessage(logDomain, .error, "Could not delete log files \(error)")
            }
        }
    }

    // -----------------------------------------------------------------------------------------
    // Log important system info, like the app version, system version, etc.
    private func logImportantInfo() {
        let outputLine = "System info: appVerson: \(UIUtility.appVersionStr), "
            + "sysVersion: \(UIUtility.osVersionStr), "
            + "model: \(UIUtility.modelStr)"
        logString(outputLine)
    }

    // -----------------------------------------------------------------------------------------
    // Set the current logging file
    private func setLogFile(pathOpt: String?) {
        curLogFileH?.synchronizeFile()
        curLogFileH?.closeFile()
        curLogFileH = nil
        curLogFilePath = pathOpt

        if let path = pathOpt {
            self.logMessage(domain: logDomain, level: .log, message: "Now logging to file: \(path)")
            logImportantInfo()
            if !FileManager.default.fileExists(atPath: path) {
                FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
            }
            curLogFileH = FileHandle(forWritingAtPath: curLogFilePath!)
            if curLogFileH == nil {
                NSLog("ERROR: Could not open log file at \(curLogFilePath!)")
            }
            curLogFileH?.seekToEndOfFile()
        }
    }

    // -----------------------------------------------------------------------------------------
    // Index of the next and previous log file
    private func prevLogFileIndex(_ index: Int) -> Int {
        var newValue = index - 1
        if newValue < 0 {
            newValue = numLogFiles - 1
        }
        return newValue
    }

    func nextLogFileIndex(_ index: Int) -> Int {
        return (index + 1) % numLogFiles
    }

    // -----------------------------------------------------------------------------------------
    // Get full path to log file of the given index
    private func logFilePath(index: Int) -> String {
        let allPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                           .userDomainMask, true)
        let documentsDirectory = allPaths.first!
        let name = "log\(index).txt"
        return documentsDirectory + "/" + name
    }

    // -----------------------------------------------------------------------------------------
    // Rotate the logging file if necessary
    private func rotateLogFileIfNecessary() {

        // Get the size of the existing file
        var fileSize: UInt64
        curLogFileH?.synchronizeFile()

        // Set the logging buffer to nil so that all pending data gets written to it
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: curLogFilePath!)
            fileSize = (attr[FileAttributeKey.size] as? UInt64) ?? 0
        } catch {
            LogMessage(logDomain, .error, "Error getting file size of \(curLogFilePath!): \(error)")
            fileSize = 0
        }

        LogMessage(logDomain, .debug, "Current size of \(curLogFilePath!) is \(fileSize)")
        if fileSize < maxFileSize {
            LogMessage(logDomain, .log, "Current size of log file \(curLogFilePath!) = \(fileSize)")
            return
        }

        // Too big, rotate to the other one
        logFileIndex = nextLogFileIndex(logFileIndex)
        AppSettings.shared.activeLoggingFileIndex = logFileIndex
        let newPath = logFilePath(index: logFileIndex)

        LogMessage(logDomain, .log, "Current log file too big (\(fileSize)), "
            + "switching to \(newPath)")

        // Delete the new file so that it starts over at 0 size
        try? FileManager.default.removeItem(atPath: newPath)
        setLogFile(pathOpt: newPath)
    }

    // ---------------------------------------------------------------------------------------
    // Periodic functions
    @objc func periodicTimerCB() {
        LogMessage(logDomain, .log, "Running periodic timer")
        logFileQueue.async {
            [weak self] in
            guard let uSelf = self else { return }
            uSelf.rotateLogFileIfNecessary()
        }
    }
    
}

extension LoggingManager {
    
    private func addLogLevelTag(_ logLevel: LogLevel, to logString: String) -> String {
        return [logLevel.tag, logString].compactMap({$0}).joined(separator: " ")
    }
    private func shouldLog(logLevel: LogLevel, currentLogLevel: LogLevel) -> Bool {
        return (logLevel.rawValue >= currentLogLevel.rawValue)
    }
    
}
