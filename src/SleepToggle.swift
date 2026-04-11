import Foundation

class SleepToggle {
    private(set) var isDisableSleep: Bool = false

    init() {
        refresh()
    }

    func refresh() {
        isDisableSleep = currentStatus()
    }

    func currentStatus() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return false
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return false }

        for line in output.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.lowercased().hasPrefix("sleepdisabled") ||
               trimmed.lowercased().hasPrefix("disablesleep") {
                return trimmed.hasSuffix("1")
            }
        }
        return false
    }

    enum ToggleResult {
        case success
        case wrongPassword
        case failed(String)
    }

    func toggle(password: String) -> ToggleResult {
        let newValue = isDisableSleep ? "0" : "1"

        let escaped = password.replacingOccurrences(of: "'", with: "'\\''")
        let script = "echo '\(escaped)' | /usr/bin/sudo -S /usr/bin/pmset -a disablesleep \(newValue)"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", script]

        let stderrPipe = Pipe()
        process.standardOutput = FileHandle.nullDevice
        process.standardError = stderrPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return .failed(error.localizedDescription)
        }

        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrOutput = String(data: stderrData, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            if stderrOutput.lowercased().contains("incorrect password") ||
               stderrOutput.lowercased().contains("sorry") {
                return .wrongPassword
            }
            return .failed(stderrOutput)
        }

        isDisableSleep = !isDisableSleep
        return .success
    }
}
