import Cocoa

struct PasswordPrompt {
    static func show(message: String = "Enter your sudo password") -> String? {
        let alert = NSAlert()
        alert.messageText = "SteamPack"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        let input = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        input.placeholderString = "Password"
        alert.accessoryView = input
        alert.window.initialFirstResponder = input

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return nil }

        let value = input.stringValue
        return value.isEmpty ? nil : value
    }
}
