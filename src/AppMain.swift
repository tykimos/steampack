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

        // Show countdown next to icon
        if let endDate = timerEndDate {
            let remaining = max(0, Int(endDate.timeIntervalSinceNow))
            let hours = remaining / 3600
            let minutes = (remaining % 3600) / 60
            let seconds = remaining % 60
            if hours > 0 {
                statusItem.button?.title = String(format: " %d:%02d:%02d", hours, minutes, seconds)
            } else {
                statusItem.button?.title = String(format: " %02d:%02d", minutes, seconds)
            }
        } else {
            statusItem.button?.title = ""
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
        startScheduledSleep(seconds: TimeInterval(sender.tag), retry: true)
    }

    private func startScheduledSleep(seconds: TimeInterval, retry: Bool) {
        // If sleep is currently enabled, disable it first
        if !sleepToggle.isDisableSleep {
            guard let password = KeychainHelper.load() else {
                if promptPassword() && retry {
                    startScheduledSleep(seconds: seconds, retry: false)
                }
                return
            }
            let result = sleepToggle.toggle(password: password)
            switch result {
            case .success:
                break
            case .wrongPassword:
                KeychainHelper.delete()
                if promptPassword(message: "Incorrect password. Please try again.") && retry {
                    startScheduledSleep(seconds: seconds, retry: false)
                }
                return
            case .failed(let message):
                showError("pmset failed: \(message)")
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

        // Update the countdown display every second
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateIcon()
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

        // Re-enable sleep. If this fails the Mac stays awake, so never fail silently.
        if sleepToggle.isDisableSleep {
            reenableSleepAfterTimer()
        }
        sleepToggle.refresh()
        updateMenu()
    }

    private func reenableSleepAfterTimer() {
        let result: SleepToggle.ToggleResult
        if let password = KeychainHelper.load() {
            result = sleepToggle.toggle(password: password)
        } else {
            result = .wrongPassword
        }

        switch result {
        case .success:
            return
        case .wrongPassword:
            KeychainHelper.delete()
            let message = "The timer ended, but sleep could not be re-enabled. Enter your sudo password to re-enable sleep."
            if promptPassword(message: message), let password = KeychainHelper.load(),
               case .failed(let error) = sleepToggle.toggle(password: password) {
                showError("pmset failed: \(error)")
            }
        case .failed(let error):
            showError("The timer ended, but sleep could not be re-enabled.\n\npmset failed: \(error)")
        }
    }

    @objc private func toggleSleep() {
        performToggle(retry: true)
    }

    private func performToggle(retry: Bool) {
        guard let password = KeychainHelper.load() else {
            if promptPassword() && retry {
                performToggle(retry: false)
            }
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
            if promptPassword(message: "Incorrect password. Please try again.") && retry {
                performToggle(retry: false)
            }
        case .failed(let message):
            showError("pmset failed: \(message)")
        }
    }

    @objc private func changePassword() {
        promptPassword(message: "Enter new sudo password")
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    /// Asks for the sudo password until a correct one is entered or the user cancels.
    /// The password is checked with `sudo -v` before it is saved to the Keychain.
    /// Returns true when a verified password was saved.
    @discardableResult
    private func promptPassword(message: String = "Enter your sudo password") -> Bool {
        // Menu bar (accessory) apps are not frontmost, so the dialog would open behind other windows.
        NSApp.activate(ignoringOtherApps: true)
        var message = message
        while let pw = PasswordPrompt.show(message: message) {
            switch sleepToggle.verifyPassword(pw) {
            case .success:
                KeychainHelper.save(password: pw)
                return true
            case .wrongPassword:
                message = "Incorrect password. Please try again."
            case .failed(let error):
                showError("sudo failed: \(error)")
                return false
            }
        }
        return false
    }

    private func showError(_ message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "확인")
        alert.runModal()
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
