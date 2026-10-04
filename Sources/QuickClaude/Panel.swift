import AppKit
import SwiftUI

final class ChatPanel: NSPanel, NSWindowDelegate {
    private let chat = Chat()

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 520),
            styleMask: [.titled, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            standardWindowButton(button)?.isHidden = true
        }
        isMovableByWindowBackground = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        minSize = NSSize(width: 340, height: 300)
        delegate = self
        contentView = NSHostingView(rootView: ChatView(chat: chat) { [weak self] in self?.hide() })
    }

    override var canBecomeKey: Bool { true }

    func toggle() {
        isVisible && isKeyWindow ? hide() : show()
    }

    func show() {
        let mouse = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main {
            let area = screen.visibleFrame
            setFrameOrigin(NSPoint(
                x: area.midX - frame.width / 2,
                y: area.minY + area.height * 2 / 3 - frame.height / 2
            ))
        }
        NSApp.activate()
        makeKeyAndOrderFront(nil)
        chat.focusToken += 1
    }

    func hide() {
        orderOut(nil)
        if NSApp.isActive { NSApp.hide(nil) }
    }

    override func cancelOperation(_ sender: Any?) {
        hide()
    }

    func windowDidResignKey(_ notification: Notification) {
        if isVisible { hide() }
    }
}
