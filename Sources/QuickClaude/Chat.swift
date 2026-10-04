import AppKit

struct Message: Identifiable {
    let id = UUID()
    let isUser: Bool
    var text: String
    var attachments: [Attachment] = []
}

@MainActor
final class Chat: ObservableObject {
    @Published private(set) var messages: [Message] = []
    @Published private(set) var sessionId: String?
    @Published private(set) var isRunning = false
    @Published var pending: [Attachment] = []
    @Published var focusToken = 0

    private var process: Process?

    private static let systemPrompt = "You are Claude, a helpful assistant answering in a small quick-chat window. Be concise and direct."
    private static let workDir = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".quickclaude")

    private nonisolated static let claudePath: String? = {
        let candidates = ["\(NSHomeDirectory())/.local/bin/claude", "/opt/homebrew/bin/claude", "/usr/local/bin/claude"]
        if let path = candidates.first(where: FileManager.default.isExecutableFile(atPath:)) { return path }
        if let path = desktopBundledClaude() { return path }
        let shell = Process()
        let out = Pipe()
        shell.executableURL = URL(fileURLWithPath: "/bin/zsh")
        shell.arguments = ["-lc", "command -v claude"]
        shell.standardOutput = out
        try? shell.run()
        shell.waitUntilExit()
        let path = String(decoding: out.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return path.isEmpty ? nil : path
    }()

    private nonisolated static func desktopBundledClaude() -> String? {
        let fm = FileManager.default
        let root = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support/Claude/claude-code")
        let versions = (try? fm.contentsOfDirectory(atPath: root.path)) ?? []
        for version in versions.sorted(by: { $0.compare($1, options: .numeric) == .orderedDescending }) {
            let versionDir = root.appendingPathComponent(version)
            for build in (try? fm.contentsOfDirectory(atPath: versionDir.path)) ?? [] {
                let path = versionDir.appendingPathComponent("\(build)/claude.app/Contents/MacOS/claude").path
                if fm.isExecutableFile(atPath: path) { return path }
            }
        }
        return nil
    }

    func paste(from pasteboard: NSPasteboard) -> Bool {
        let attachments = Attachment.read(from: pasteboard)
        pending += attachments
        return !attachments.isEmpty
    }

    func send(_ text: String, model: String, effort: String) {
        guard !isRunning else { return }
        let attachments = pending
        pending = []
        messages.append(Message(isUser: true, text: text, attachments: attachments))
        messages.append(Message(isUser: false, text: ""))

        guard let claude = Self.claudePath else {
            append("Couldn't find the `claude` CLI.")
            return
        }

        var args = [
            "-p", "--input-format", "stream-json",
            "--output-format", "stream-json", "--verbose", "--include-partial-messages",
            "--model", model, "--effort", effort,
            "--tools", "WebSearch,WebFetch", "--allowedTools", "WebSearch,WebFetch",
            "--setting-sources", "project", "--strict-mcp-config", "--disable-slash-commands",
            "--system-prompt", Self.systemPrompt,
        ]
        if let sessionId { args += ["--resume", sessionId] }

        try? FileManager.default.createDirectory(at: Self.workDir, withIntermediateDirectories: true)
        let process = Process()
        let input = Pipe()
        let out = Pipe()
        let err = Pipe()
        process.executableURL = URL(fileURLWithPath: claude)
        process.arguments = args
        process.currentDirectoryURL = Self.workDir
        process.standardInput = input
        process.standardOutput = out
        process.standardError = err

        do {
            try process.run()
        } catch {
            append("Couldn't start claude: \(error.localizedDescription)")
            return
        }
        self.process = process
        isRunning = true
        write(text, attachments, to: input.fileHandleForWriting)

        Task {
            var gotResult = false
            do {
                for try await line in out.fileHandleForReading.bytes.lines {
                    gotResult = handle(line) || gotResult
                }
            } catch {}
            if !gotResult, messages.last?.text.isEmpty == true {
                let stderr = String(decoding: err.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                append(stderr.isEmpty ? "Stopped." : stderr)
            }
            self.process = nil
            isRunning = false
        }
    }

    func stop() {
        process?.terminate()
    }

    func reset() {
        stop()
        messages = []
        pending = []
        sessionId = nil
        focusToken += 1
    }

    func openInClaude() {
        guard let sessionId, let url = URL(string: "claude://resume?session=\(sessionId)") else { return }
        NSWorkspace.shared.open(url)
    }

    private func write(_ text: String, _ attachments: [Attachment], to handle: FileHandle) {
        var content: [[String: Any]] = attachments.map {
            ["type": "image", "source": ["type": "base64", "media_type": $0.mediaType, "data": $0.data.base64EncodedString()]]
        }
        if !text.isEmpty { content.append(["type": "text", "text": text]) }
        let message: [String: Any] = ["type": "user", "message": ["role": "user", "content": content]]
        guard let line = try? JSONSerialization.data(withJSONObject: message) else { return }
        DispatchQueue.global().async {
            try? handle.write(contentsOf: line + Data("\n".utf8))
            try? handle.close()
        }
    }

    private func handle(_ line: String) -> Bool {
        guard let json = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any] else { return false }
        switch json["type"] as? String {
        case "system":
            if json["subtype"] as? String == "init" { sessionId = json["session_id"] as? String }
        case "stream_event":
            guard let event = json["event"] as? [String: Any] else { break }
            if event["type"] as? String == "content_block_start",
               (event["content_block"] as? [String: Any])?["type"] as? String == "text",
               messages.last?.text.isEmpty == false {
                append("\n\n")
            }
            if let delta = event["delta"] as? [String: Any],
               delta["type"] as? String == "text_delta",
               let text = delta["text"] as? String {
                append(text)
            }
        case "result":
            if json["is_error"] as? Bool == true {
                append("\n\n⚠️ " + ((json["result"] as? String) ?? "Something went wrong."))
            }
            return true
        default:
            break
        }
        return false
    }

    private func append(_ text: String) {
        guard !messages.isEmpty else { return }
        messages[messages.count - 1].text += text
    }
}
