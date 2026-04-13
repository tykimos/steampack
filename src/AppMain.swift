import Cocoa
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let sleepToggle = SleepToggle()

    // Menu items that need updating
    private var statusMenuItem: NSMenuItem!
    private var toggleMenuItem: NSMenuItem!
    private var scheduledMenuItem: NSMenuItem!
    private var loginItemMenuItem: NSMenuItem!

    // Scheduled sleep timer
    private var sleepTimer: Timer?
    private var timerEndDate: Date?
    private var countdownTimer: Timer?

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

        // Scheduled sleep submenu
        scheduledMenuItem = NSMenuItem(title: "Scheduled Sleep", action: nil, keyEquivalent: "")
        let scheduledSubmenu = NSMenu()
        let durations: [(String, TimeInterval)] = [
            ("10 Minutes", 10 * 60),
            ("30 Minutes", 30 * 60),
            ("1 Hour", 60 * 60),
            ("2 Hours", 2 * 60 * 60),
            ("4 Hours", 4 * 60 * 60),
        ]
        for (title, seconds) in durations {
            let item = NSMenuItem(title: title, action: #selector(scheduleSleep(_:)), keyEquivalent: "")
            item.target = self
            item.tag = Int(seconds)
            scheduledSubmenu.addItem(item)
        }
        scheduledSubmenu.addItem(NSMenuItem.separator())
        let cancelItem = NSMenuItem(title: "Cancel Timer", action: #selector(cancelScheduledSleep), keyEquivalent: "")
        cancelItem.target = self
        scheduledSubmenu.addItem(cancelItem)
        scheduledMenuItem.submenu = scheduledSubmenu
        if let image = NSImage(systemSymbolName: "hourglass.badge.eye", accessibilityDescription: "Scheduled Sleep") {
            image.isTemplate = true
            scheduledMenuItem.image = image
        }
        menu.addItem(scheduledMenuItem)

        menu.addItem(NSMenuItem.separator())

        loginItemMenuItem = NSMenuItem(title: loginItemText(), action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItemMenuItem.target = self
        menu.addItem(loginItemMenuItem)

        let changePwItem = NSMenuItem(title: "Change Password", action: #selector(changePassword), keyEquivalent: "")
        changePwItem.target = self
        menu.addItem(changePwItem)

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func updateIcon() {
        let name: String
        if sleepTimer != nil {
            name = "hourglass.badge.eye"
        } else if sleepToggle.isDisableSleep {
            name = "eye.fill"
        } else {
            name = "eye.half.closed.fill"
        }
        if let image = NSImage(systemSymbolName: name, accessibilityDescription: "Sleep Toggle") {
            image.isTemplate = true
            statusItem.button?.image = image
        }
    }

    private func updateMenu() {
        statusMenuItem.title = statusText()
        toggleMenuItem.title = toggleText()
        loginItemMenuItem.title = loginItemText()
        updateIcon()
    }

    private func statusText() -> String {
        if let endDate = timerEndDate {
            let remaining = max(0, endDate.timeIntervalSinceNow)
            let hours = Int(remaining) / 3600
            let minutes = (Int(remaining) % 3600) / 60
            if hours > 0 {
                return "Sleep in \(hours)h \(minutes)m"
            } else {
                return "Sleep in \(minutes)m"
            }
        }
        return sleepToggle.isDisableSleep ? "Sleep Disabled" : "Sleep Enabled"
    }

    private func toggleText() -> String {
        sleepToggle.isDisableSleep ? "Enable Sleep" : "Disable Sleep"
    }

    private var isLoginItemEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    private func loginItemText() -> String {
        isLoginItemEnabled ? "✓ Start at Login" : "  Start at Login"
    }

    @objc private func toggleLoginItem() {
        do {
            if isLoginItemEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Login Item"
            alert.informativeText = "Failed to update login item: \(error.localizedDescription)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        updateMenu()
    }

    @objc private func scheduleSleep(_ sender: NSMenuItem) {
        let seconds = TimeInterval(sender.tag)

        // If sleep is currently enabled, disable it first
        if !sleepToggle.isDisableSleep {
            guard let password = KeychainHelper.load() else {
                promptPassword()
                return
            }
            let result = sleepToggle.toggle(password: password)
            switch result {
            case .success:
                break
            case .wrongPassword:
                KeychainHelper.delete()
                promptPassword()
                return
            case .failed:
                return
            }
        }

        // Cancel any existing timer
        sleepTimer?.invalidate()
        countdownTimer?.invalidate()

        // Set the end date and start timers
        timerEndDate = Date().addingTimeInterval(seconds)

        sleepTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            self?.timerFired()
        }

        // Update the countdown display every 30 seconds
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateMenu()
        }

        updateMenu()
    }

    @objc private func cancelScheduledSleep() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        timerEndDate = nil
        updateMenu()
    }

    private func timerFired() {
        sleepTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        timerEndDate = nil

        // Re-enable sleep
        if sleepToggle.isDisableSleep {
            guard let password = KeychainHelper.load() else { return }
            _ = sleepToggle.toggle(password: password)
        }
        updateMenu()
    }

    @objc private func toggleSleep() {
        guard let password = KeychainHelper.load() else {
            promptPassword()
            return
        }

        let result = sleepToggle.toggle(password: password)
        switch result {
        case .success:
            // Cancel any scheduled timer on manual toggle
            cancelScheduledSleep()
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
