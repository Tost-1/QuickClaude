import AppKit
import MarkdownUI
import SwiftMath
import SwiftUI

enum MathMarkdown {
    private static let block = try! NSRegularExpression(pattern: #"\$\$([\s\S]+?)\$\$|\\\[([\s\S]+?)\\\]"#)
    private static let inline = try! NSRegularExpression(pattern: #"(?<!\$)\$(?![\s$])([^$\n]+?)(?<!\s)\$(?!\d)|\\\((.+?)\\\)"#)

    static func prepare(_ text: String) -> String {
        text.components(separatedBy: "```").enumerated().map { index, part in
            guard index.isMultiple(of: 2) else { return part }
            let blocks = replace(block, in: part) { "\n```math\n\($0.trimmingCharacters(in: .whitespacesAndNewlines))\n```\n" }
            return replace(inline, in: blocks) { "![math](math:\($0.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""))" }
        }
        .joined(separator: "```")
    }

    private static func replace(_ regex: NSRegularExpression, in text: String, with transform: (String) -> String) -> String {
        let source = text as NSString
        let result = NSMutableString(string: source)
        for match in regex.matches(in: text, range: NSRange(location: 0, length: source.length)).reversed() {
            guard let latex = [1, 2].map(match.range(at:)).first(where: { $0.location != NSNotFound }) else { continue }
            result.replaceCharacters(in: match.range, with: transform(source.substring(with: latex)))
        }
        return result as String
    }
}

@MainActor
enum MathRenderer {
    static func image(_ latex: String, display: Bool, fontSize: CGFloat) -> NSImage? {
        let label = MTMathUILabel()
        label.latex = latex
        label.labelMode = display ? .display : .text
        label.fontSize = fontSize
        label.textColor = Theme.textNS
        guard label.error == nil else { return nil }
        let size = label.intrinsicContentSize
        guard size.width > 0, size.height > 0 else { return nil }
        label.frame = CGRect(origin: .zero, size: size)
        label.layout()
        guard let rep = label.bitmapImageRepForCachingDisplay(in: label.bounds) else { return nil }
        label.cacheDisplay(in: label.bounds, to: rep)
        let image = NSImage(size: size)
        image.addRepresentation(rep)
        return image
    }
}

struct InlineMathProvider: InlineImageProvider {
    struct Unrenderable: Error {}

    func image(with url: URL, label: String) async throws -> Image {
        guard url.scheme == "math",
              let latex = url.absoluteString.dropFirst("math:".count).removingPercentEncoding,
              let image = await MathRenderer.image(latex, display: false, fontSize: 15)
        else { throw Unrenderable() }
        return Image(nsImage: image)
    }
}

struct MathBlock: View {
    let latex: String

    var body: some View {
        if let image = MathRenderer.image(latex, display: true, fontSize: 17) {
            ScrollView(.horizontal) {
                Image(nsImage: image)
            }
            .frame(maxWidth: .infinity)
            .markdownMargin(top: 0, bottom: 10)
        } else {
            Text(latex)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Theme.text)
                .markdownMargin(top: 0, bottom: 10)
        }
    }
}
