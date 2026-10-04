import AppKit

@MainActor
enum Updater {
    private static let repo = Bundle.main.object(forInfoDictionaryKey: "QuickClaudeRepo") as? String
    private nonisolated static let environment = ProcessInfo.processInfo.environment.merging(
        ["PATH": "/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin"]
    ) { $1 }

    static func check() async {
        guard let repo else {
            return show("Can't check for updates", "This build doesn't know its repository. Rebuild it with build.sh.")
        }
        let fetch = await run(["git", "fetch", "origin"], in: repo)
        guard fetch.status == 0 else { return show("Couldn't check for updates", fetch.output) }

        let log = await run(["git", "log", "--oneline", "HEAD..@{u}"], in: repo)
        guard log.status == 0 else { return show("Couldn't check for updates", log.output) }
        let changes = log.output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !changes.isEmpty else { return show("QuickClaude is up to date", "") }

        let alert = NSAlert()
        alert.messageText = "An update is available"
        alert.informativeText = changes
        alert.addButton(withTitle: "Install and Restart")
        alert.addButton(withTitle: "Later")
        NSApp.activate()
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let pull = await run(["git", "pull", "--ff-only"], in: repo)
        guard pull.status == 0 else { return show("Update failed", pull.output) }
        let build = await run(["swift", "build", "-c", "release"], in: repo)
        guard build.status == 0 else { return show("Build failed", String(build.output.suffix(2000))) }

        let install = Process()
        install.executableURL = URL(fileURLWithPath: "/bin/zsh")
        install.arguments = ["build.sh"]
        install.currentDirectoryURL = URL(fileURLWithPath: repo)
        install.environment = environment
        do {
            try install.run()
        } catch {
            show("Install failed", error.localizedDescription)
        }
    }

    private static func run(_ args: [String], in directory: String) async -> (status: Int32, output: String) {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let process = Process()
                let pipe = Pipe()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                process.arguments = args
                process.currentDirectoryURL = URL(fileURLWithPath: directory)
                process.environment = environment
                process.standardOutput = pipe
                process.standardError = pipe
                do {
                    try process.run()
                } catch {
                    return continuation.resume(returning: (-1, error.localizedDescription))
                }
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                continuation.resume(returning: (process.terminationStatus, String(decoding: data, as: UTF8.self)))
            }
        }
    }

    private static func show(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        NSApp.activate()
        alert.runModal()
    }
}
