import MarkdownUI
import SwiftUI

struct ChatView: View {
    @ObservedObject var chat: Chat
    let hide: () -> Void

    @AppStorage("model") private var model = "sonnet"
    @AppStorage("effort") private var effort = "medium"
    @State private var input = ""
    @FocusState private var isInputFocused: Bool

    private static let models = [("Fable", "fable"), ("Opus", "opus"), ("Sonnet", "sonnet"), ("Haiku", "haiku")]
    private static let efforts = ["low", "medium", "high", "xhigh", "max"]

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Theme.border)
            messages
            inputBar
        }
        .background(Theme.background)
        .ignoresSafeArea()
        .onChange(of: chat.focusToken) { isInputFocused = true }
    }

    private var header: some View {
        HStack(spacing: 6) {
            CloseButton(action: hide)
                .padding(.trailing, 6)
            Picker("Model", selection: $model) {
                ForEach(Self.models, id: \.1) { Text($0.0).tag($0.1) }
            }
            .fixedSize()
            Picker("Effort", selection: $effort) {
                ForEach(Self.efforts, id: \.self) { Text($0.capitalized).tag($0) }
            }
            .fixedSize()
            Spacer()
            Button(action: chat.reset) { Image(systemName: "square.and.pencil") }
                .keyboardShortcut("n")
                .help("New chat (⌘N)")
            Button {
                chat.openInClaude()
                hide()
            } label: {
                Image(systemName: "arrow.up.forward.app")
            }
            .disabled(chat.sessionId == nil || chat.isRunning)
            .help("Open in Claude")
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .buttonStyle(.borderless)
        .foregroundStyle(Theme.secondary)
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private var messages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(chat.messages) { message in
                        MessageRow(message: message, isPending: chat.isRunning && message.id == chat.messages.last?.id)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(14)
            }
            .onChange(of: chat.messages.last?.text) { proxy.scrollTo("bottom", anchor: .bottom) }
            .overlay {
                if chat.messages.isEmpty {
                    Text("How can I help?")
                        .font(.system(size: 22, design: .serif))
                        .foregroundStyle(Theme.secondary)
                }
            }
        }
    }

    private var inputBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !chat.pending.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(chat.pending) { attachment in
                            Thumbnail(attachment: attachment)
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        chat.pending.removeAll { $0.id == attachment.id }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.white, .black.opacity(0.6))
                                    }
                                    .buttonStyle(.plain)
                                    .padding(3)
                                }
                        }
                    }
                }
            }
            inputRow
        }
        .padding(10)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border))
        .padding(12)
    }

    private var canSend: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !chat.pending.isEmpty
    }

    private var inputRow: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Message Claude", text: $input, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...6)
                .focused($isInputFocused)
                .foregroundStyle(Theme.text)
                .onKeyPress(.return, phases: .down) { press in
                    if press.modifiers.contains(.shift) {
                        input += "\n"
                    } else {
                        send()
                    }
                    return .handled
                }
            Button(action: chat.isRunning ? chat.stop : send) {
                Image(systemName: chat.isRunning ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.accent)
            }
            .buttonStyle(.plain)
            .disabled(!chat.isRunning && !canSend)
        }
    }

    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canSend, !chat.isRunning else { return }
        input = ""
        chat.send(text, model: model, effort: effort)
    }
}

private struct MessageRow: View {
    let message: Message
    let isPending: Bool

    var body: some View {
        if message.isUser {
            VStack(alignment: .trailing, spacing: 6) {
                if !message.attachments.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(message.attachments) { Thumbnail(attachment: $0, size: 96) }
                    }
                }
                if !message.text.isEmpty {
                    Text(message.text)
                        .foregroundStyle(Theme.text)
                        .textSelection(.enabled)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.userBubble, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.leading, 40)
            .frame(maxWidth: .infinity, alignment: .trailing)
        } else if message.text.isEmpty && isPending {
            ProgressView().controlSize(.small)
        } else {
            Markdown(MathMarkdown.prepare(message.text))
                .markdownTheme(.claude)
                .markdownInlineImageProvider(InlineMathProvider())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct Thumbnail: View {
    let attachment: Attachment
    var size: CGFloat = 56

    var body: some View {
        Image(nsImage: attachment.thumbnail)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border))
    }
}

private struct CloseButton: View {
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(red: 1, green: 0.373, blue: 0.341))
                .overlay(Circle().stroke(.black.opacity(0.15), lineWidth: 0.5))
                .overlay {
                    if isHovering {
                        Image(systemName: "xmark")
                            .font(.system(size: 7, weight: .heavy))
                            .foregroundStyle(.black.opacity(0.55))
                    }
                }
                .frame(width: 12, height: 12)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .help("Close (Esc)")
    }
}
