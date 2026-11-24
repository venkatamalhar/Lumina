import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        
        setupStatusItem()
        setupPopover()
        setupHotKey()
        setupWakeObservers()
        
        ScheduleManager.shared.start()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        HotKeyManager.shared.unregister()
        GammaController.shared.restoreDisplaySettings(animated: false)
    }
    
    private func setupWakeObservers() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(
            self,
            selector: #selector(handleDisplayWake),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleDisplayWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }
    
    @objc private func handleDisplayWake() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            ScheduleManager.shared.evaluateSchedule(animated: false)
        }
    }
    
    func updateStatusIcon(isFiltering: Bool) {
        guard let button = statusItem?.button else { return }
        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        let symbolName = isFiltering ? "sun.max.fill" : "sun.max"
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Lumina")?
            .withSymbolConfiguration(config)
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
            let image = NSImage(systemSymbolName: "sun.max.fill", accessibilityDescription: "Lumina")?
                .withSymbolConfiguration(config)
            button.image = image
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover.behavior = .transient
        
        let contentView = MenuBarView(
            onOpenSettings: { [weak self] in
                self?.openSettingsWindow()
            },
            onQuit: {
                NSApplication.shared.terminate(nil)
            }
        )
        let hostingController = NSHostingController(rootView: contentView)
        popover.contentViewController = hostingController
        popover.contentSize = NSSize(width: 330, height: 275)
    }
    
    private func setupHotKey() {
        HotKeyManager.shared.onHotKeyPressed = {
            DispatchQueue.main.async {
                ScheduleManager.shared.toggleFilter()
            }
        }
        HotKeyManager.shared.registerDefaultToggleKey()
    }
    
    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    func openSettingsWindow() {
        popover.performClose(nil)
        
        if let existing = settingsWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }
        
        let hostingController = NSHostingController(rootView: SettingsView())
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 380),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Lumina Settings"
        window.isReleasedWhenClosed = false
        window.contentViewController = hostingController
        
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
