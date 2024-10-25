import os
import SwiftUI

// MARK: - Logging System Overview

/**
 Logging System Usage:

 - Basic Logging:
   - Use `log()` to log the current location in the code, recording file, function, and line number.

 - Error Logging:
   - Log errors with a message and log level `.error`, e.g., `log("Error message", .error)`.

 - Logging with Arguments:
   - String Interpolation: Insert values directly into your string, e.g., `log("Hello \("World")!")`.
   - Placeholder Syntax: Use C-style string format specifiers, e.g., `log("Hello %@!", "World")`.

 - Appending Extra Arguments:
   - Extra arguments beyond placeholders are appended at the end of the log, e.g., `log("Main Message", "Hello", "World!")`.

 - Custom Log Levels:
   - Specify a log level other than `.info` by providing it as an argument, e.g., `log("Main Message", .error, "Hello", "World!")`.

 - Flexible Argument Types:
   - The logging system handles various argument types, formatting them for clarity in logs.

 - Intelligent Argument Handling:
   - Empty array arguments are automatically filtered out to maintain clean and relevant logs.

 Use these features to create detailed and informative log statements for effective debugging and application monitoring.
 */

let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.unknown", category: "application")

// TODO: Buffer settings
// makes sure that output appears immediately as it's written, which can be especially useful for debugging or when you want real-time logging in a console application.
// setbuf(__stdoutp, nil)

public func log(fileID: String = #fileID, function: String = #function, line: Int = #line) {
    log("", [], level: .info, fileID: fileID, function: function, line: line)
}

public func log(_ message: Any, fileID: String = #fileID, function: String = #function, line: Int = #line) {
    log(String(describing: message), [], level: .info, fileID: fileID, function: function, line: line)
}

public func log(_ message: Any, _ level: OSLogType = .info, _ args: CVarArg..., fileID: String = #fileID, function: String = #function, line: Int = #line) {
    log(String(describing: message), args, level: level, fileID: fileID, function: function, line: line)
}

public func log(_ message: Any, _ args: CVarArg..., fileID: String = #fileID, function: String = #function, line: Int = #line) {
    log(String(describing: message), args, level: .info, fileID: fileID, function: function, line: line)
}

public func log(_ message: String = "", fileID: String = #fileID, function: String = #function, line: Int = #line) {
    log(message, [], level: .info, fileID: fileID, function: function, line: line)
}

public func log(_ message: String = "", _ level: OSLogType = .info, _ args: CVarArg..., fileID: String = #fileID, function: String = #function, line: Int = #line) {
    log(message, args, level: level, fileID: fileID, function: function, line: line)
}

public func log(_ message: Int = 0, fileID: String = #fileID, function: String = #function, line: Int = #line) {
    log("\(message)", [], level: .info, fileID: fileID, function: function, line: line)
}

public func log(_ message: String = "", _ args: CVarArg..., level: OSLogType = .info, fileID: String = #fileID, function: String = #function, line: Int = #line) {
    let formattedMessage = formatMessage(message, args: args, fileID: fileID, function: function, line: line)
    
    logger.log(level: level, "\(formattedMessage, privacy: .public)")
}

private func formatMessage(_ message: String, args: CVarArg..., fileID: String, function: String, line: Int) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd-MM-yy HH:mm:ss.SSS"
    
    let timestamp = dateFormatter.string(from: Date())
    let threadID = pthread_mach_thread_np(pthread_self())
    
    let numberOfPlaceholders = message.components(separatedBy: "%").count - 1

    // Filter out empty arrays from the arguments
    let validArgs = args.compactMap { arg -> CVarArg? in
        if let arrayArg = arg as? [Any], !arrayArg.isEmpty {
            return arrayArg
        } else if arg is [Any] {
            return nil  // Exclude empty arrays
        } else {
            return String(describing: arg)
        }
    }
    
    var formattedMessage = ""
    if validArgs.count > numberOfPlaceholders {
        let formattedArgsMessage = String(format: message, arguments: Array(validArgs.prefix(numberOfPlaceholders)) as [CVarArg])
        let extraArgs = validArgs.dropFirst(numberOfPlaceholders).map { String(describing: $0) }
        if !extraArgs.isEmpty {
            let extraArgsString = extraArgs.joined(separator: ", ")
            formattedMessage = "\(formattedArgsMessage) [Extra Args: \(extraArgsString)]"
        } else {
            formattedMessage = "\(formattedArgsMessage)"
        }
    } else {
        formattedMessage = String(format: message, arguments: validArgs as [CVarArg])
    }
    
    return "[\(timestamp)] [Thread \(threadID)] \(formattedMessage) | \(fileID) \(function) line: \(line)"
}

public func sanityLogTest() {
    log("1")                                    // print '1' in info level
    log("2", 0)                                 // print '2' in info level + extra args
    log("%@", 3)                                // print '3' in info level
    log("%@", "4")                              // print '4' in info level
    log(5)                                      // print '5' in info level
    log(6, .error)                              // print '6' in error level
    log(7, .error, 0, 0)                        // print '7' in error level + extra args
    log(8, .error, "extra", "extra")            // print '8' in error level + extra args
    log(9, .error, "extra", 0)                  // print '9' in error level + extra args
    log("10", .error)                           // print '10' in error level
    log(11, "extra")                            // print '11' in info level + extra args
    log("\(12)")                                // print '12' in info level
    log("\(13)", .error)                        // print '13' in error level
    log("\(14)", .error, "extra")               // print '    ' in error level + extra args
    log("\("15")")                              // print '15' in info level
    log(ExampleObject.example)                  // print 'Example' in info level
    log(ExampleObject.example, .error)          // print 'Example' in error level
    log(ExampleObject.example, 1, 2, 3)         // print 'Example' in info level + extra args
    log(ExampleObject.example, .error, 1, 2, 3) // print 'Example' in error level + extra args
}

enum ExampleObject: Error, LocalizedError {
    case example

    var errorDescription: String? {
        switch self {
        case .example:
            return NSLocalizedString("The endpoint URL is invalid", comment: "")
        }
    }
}
