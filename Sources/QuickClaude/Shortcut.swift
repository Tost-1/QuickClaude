import AppKit
import Carbon.HIToolbox

struct Shortcut: Codable {
    var keyCode: UInt32
    var modifiers: UInt32
    var display: String

    static let fallback = Shortcut(keyCode: UInt32(kVK_Space), modifiers: UInt32(controlKey), display: "⌃Space")

    static var saved: Shortcut {
        get {
            UserDefaults.standard.data(forKey: "shortcut")
                .flatMap { try? JSONDecoder().decode(Shortcut.self, from: $0) } ?? fallback
        }
        set { UserDefaults.standard.set(try? JSONEncoder().encode(newValue), forKey: "shortcut") }
    }

    init(keyCode: UInt32, modifiers: UInt32, display: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.display = display
    }

    init?(event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var modifiers: UInt32 = 0
        var symbols = ""
        if flags.contains(.control) { modifiers |= UInt32(controlKey); symbols += "⌃" }
        if flags.contains(.option) { modifiers |= UInt32(optionKey); symbols += "⌥" }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey); symbols += "⇧" }
        if flags.contains(.command) { modifiers |= UInt32(cmdKey); symbols += "⌘" }
        guard modifiers != 0 else { return nil }
        let key = Int(event.keyCode) == kVK_Space ? "Space" : (event.charactersIgnoringModifiers ?? "").uppercased()
        self.init(keyCode: UInt32(event.keyCode), modifiers: modifiers, display: symbols + key)
    }

    static func record() -> Shortcut? {
        let alert = NSAlert()
        alert.messageText = "Press a new shortcut"
        alert.informativeText = "Include at least one of ⌃ ⌥ ⇧ ⌘. Current: \(saved.display)"
        alert.addButton(withTitle: "Cancel")
        var recorded: Shortcut?
        let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard let shortcut = Shortcut(event: event) else { return event }
            recorded = shortcut
            NSApp.stopModal()
            return nil
        }
        NSApp.activate()
        alert.runModal()
        if let monitor { NSEvent.removeMonitor(monitor) }
        return recorded
    }
}
