import AppKit
import Carbon.HIToolbox
import ServiceManagement

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: ChatPanel!
    private var hotKey: HotKey?
    private var statusItem: NSStatusItem!
    private let openItem = NSMenuItem(title: "", action: #selector(openPanel), keyEquivalent: "")

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = makeMenu()
        panel = ChatPanel()
        statusItem = makeStatusItem()
        if !registerHotKey(Shortcut.saved) {
            showShortcutTaken(Shortcut.saved)
        }
        try? SMAppService.mainApp.register()
    }

    private func registerHotKey(_ shortcut: Shortcut) -> Bool {
        hotKey = nil
        hotKey = HotKey(keyCode: shortcut.keyCode, modifiers: shortcut.modifiers) { [weak self] in
            self?.panel.toggle()
        }
        openItem.title = "Open QuickClaude (\(shortcut.display))"
        return hotKey != nil
    }

    private func showShortcutTaken(_ shortcut: Shortcut) {
        let alert = NSAlert()
        alert.messageText = "QuickClaude couldn't register \(shortcut.display)"
        alert.informativeText = "Another app or a system shortcut is using it."
        alert.runModal()
    }

    private func makeStatusItem() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "sparkle", accessibilityDescription: "QuickClaude")
        let menu = NSMenu()
        openItem.target = self
        menu.addItem(openItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Change Shortcut…", action: #selector(changeShortcut), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Check for Updates…", action: #selector(checkForUpdates), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit QuickClaude", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        item.menu = menu
        return item
    }

    @objc private func openPanel() {
        panel.show()
    }

    @objc private func changeShortcut() {
        let current = Shortcut.saved
        hotKey = nil
        guard let shortcut = Shortcut.record() else {
            _ = registerHotKey(current)
            return
        }
        if registerHotKey(shortcut) {
            Shortcut.saved = shortcut
        } else {
            showShortcutTaken(shortcut)
            _ = registerHotKey(current)
        }
    }

    @objc private func checkForUpdates() {
        Task { await Updater.check() }
    }

    private func makeMenu() -> NSMenu {
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit QuickClaude", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        let menu = NSMenu()
        for submenu in [appMenu, editMenu] {
            let item = NSMenuItem()
            item.submenu = submenu
            menu.addItem(item)
        }
        return menu
    }
}
