import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let sleepToggle = SleepToggle()

    // Menu items that need updating
    private var statusMenuItem: NSMenuItem!
    private var toggleMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        setupMenu()
        updateIcon()

        if KeychainHelper.load() == nil {
            promptPassword()
        }
    }

    private func setupMenu() {
        let menu = NSMenu()

        statusMenuItem = NSMenuItem(title: statusText(), action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        toggleMenuItem = NSMenuItem(title: toggleText(), action: #selector(toggleSleep), keyEquivalent: "t")
        toggleMenuItem.target = self
        menu.addItem(toggleMenuItem)

        menu.addItem(NSMenuItem.separator())

        let changePwItem = NSMenuItem(title: "Change Password", action: #selector(changePassword), keyEquivalent: "")
        changePwItem.target = self
        menu.addItem(changePwItem)

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func updateIcon() {
        let name = sleepToggle.isDisableSleep ? "eye.trianglebadge.exclamationmark.fill" : "eye.half.closed.fill"
        if let image = NSImage(systemSymbolName: name, accessibilityDescription: "Sleep Toggle") {
            image.isTemplate = true
            statusItem.button?.image = image
        }
    }

    private func updateMenu() {
        statusMenuItem.title = statusText()
        toggleMenuItem.title = toggleText()
        updateIcon()
    }

    private func statusText() -> String {
        sleepToggle.isDisableSleep ? "Sleep Disabled" : "Sleep Enabled"
    }

    private func toggleText() -> String {
        sleepToggle.isDisableSleep ? "Enable Sleep" : "Disable Sleep"
    }

    @objc private func toggleSleep() {
        guard let password = KeychainHelper.load() else {
            promptPassword()
            return
        }

        let result = sleepToggle.toggle(password: password)
        switch result {
        case .success:
            updateMenu()
        case .wrongPassword:
            KeychainHelper.delete()
            let alert = NSAlert()
            alert.messageText = "SteamPack"
            alert.informativeText = "Incorrect password. Please try again."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "확인")
            alert.runModal()
            promptPassword()
        case .failed(let message):
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = "pmset failed: \(message)"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "확인")
            alert.runModal()
        }
    }

    @objc private func changePassword() {
        if let pw = PasswordPrompt.show(message: "Enter new sudo password") {
            KeychainHelper.save(password: pw)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func promptPassword() {
        if let pw = PasswordPrompt.show() {
            KeychainHelper.save(password: pw)
        }
    }
}

@main
enum Main {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
