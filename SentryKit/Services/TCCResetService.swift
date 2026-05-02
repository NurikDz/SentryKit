// TCCResetService.swift
// SentryKit
//
// Wraps tccutil commands for resetting TCC permissions safely.

import Foundation

/// Result of a tccutil reset operation.
struct ResetResult {
    let success: Bool
    let output: String
    let error: String
    let service: String
    let bundleID: String?
}

/// Service for executing tccutil reset commands.
final class TCCResetService {

    /// Resets a specific service for a specific app.
    /// - Parameters:
    ///   - service: The TCC service to reset (e.g., "ScreenCapture")
    ///   - bundleID: The bundle identifier of the app to reset
    /// - Returns: Result of the operation
    func resetServiceForApp(service: TCCService, bundleID: String) async -> ResetResult {
        let serviceName = service.tccutilServiceName
        return await executeReset(arguments: [serviceName, bundleID], service: serviceName, bundleID: bundleID)
    }

    /// Resets a specific service for all apps.
    /// - Parameter service: The TCC service to reset
    /// - Returns: Result of the operation
    func resetServiceForAll(service: TCCService) async -> ResetResult {
        let serviceName = service.tccutilServiceName
        return await executeReset(arguments: [serviceName], service: serviceName, bundleID: nil)
    }

    /// Resets all TCC permissions (nuclear option).
    /// - Returns: Result of the operation
    func resetAll() async -> ResetResult {
        return await executeReset(arguments: ["All"], service: "All", bundleID: nil)
    }

    // MARK: - Private

    private func executeReset(arguments: [String], service: String, bundleID: String?) async -> ResetResult {
        return await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
            process.arguments = ["reset"] + arguments

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            do {
                try process.run()
                process.waitUntilExit()

                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outputData, encoding: .utf8) ?? ""
                let error = String(data: errorData, encoding: .utf8) ?? ""

                let result = ResetResult(
                    success: process.terminationStatus == 0,
                    output: output,
                    error: error,
                    service: service,
                    bundleID: bundleID
                )
                continuation.resume(returning: result)
            } catch {
                let result = ResetResult(
                    success: false,
                    output: "",
                    error: error.localizedDescription,
                    service: service,
                    bundleID: bundleID
                )
                continuation.resume(returning: result)
            }
        }
    }
}
