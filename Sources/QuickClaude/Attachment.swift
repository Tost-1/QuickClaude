import AppKit
import UniformTypeIdentifiers

struct Attachment: Identifiable {
    let id = UUID()
    let data: Data
    let mediaType: String
    let thumbnail: NSImage

    private static let maxDimension: CGFloat = 1568
    private static let maxPNGBytes = 3_500_000

    init?(image: NSImage) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let scale = min(1, Self.maxDimension / CGFloat(max(cgImage.width, cgImage.height)))
        let width = Int(CGFloat(cgImage.width) * scale)
        let height = Int(CGFloat(cgImage.height) * scale)
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ), let context = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
        context.cgContext.interpolationQuality = .high
        context.cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        if let png = rep.representation(using: .png, properties: [:]), png.count <= Self.maxPNGBytes {
            data = png
            mediaType = "image/png"
        } else if let jpeg = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.85]) {
            data = jpeg
            mediaType = "image/jpeg"
        } else {
            return nil
        }
        thumbnail = NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
    }

    static func read(from pasteboard: NSPasteboard) -> [Attachment] {
        let fileURLs = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true, .urlReadingContentsConformToTypes: [UTType.image.identifier]]
        ) as? [URL] ?? []
        if fileURLs.isEmpty, pasteboard.string(forType: .string) != nil { return [] }
        let images = fileURLs.isEmpty
            ? pasteboard.readObjects(forClasses: [NSImage.self]) as? [NSImage] ?? []
            : fileURLs.compactMap(NSImage.init(contentsOf:))
        return images.compactMap(Attachment.init(image:))
    }
}
