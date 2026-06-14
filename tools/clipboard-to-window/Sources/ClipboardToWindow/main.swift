import AppKit
import Foundation
import UniformTypeIdentifiers

enum ClipboardImageError: Error, CustomStringConvertible {
    case noImage

    var description: String {
        switch self {
        case .noImage:
            return "Clipboard does not contain an image."
        }
    }
}

enum ClipboardImageReader {
    static func read(from pasteboard: NSPasteboard = .general) throws -> NSImage {
        if let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage],
           let image = images.first {
            return image
        }

        for type in [NSPasteboard.PasteboardType.png, .tiff] {
            if let data = pasteboard.data(forType: type),
               let image = NSImage(data: data) {
                return image
            }
        }

        if let urls = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] {
            for url in urls where url.isFileURL {
                if let image = NSImage(contentsOf: url) {
                    return image
                }
            }
        }

        throw ClipboardImageError.noImage
    }
}

enum ImageSaveError: Error, CustomStringConvertible {
    case cannotCreatePNGData

    var description: String {
        switch self {
        case .cannotCreatePNGData:
            return "Could not create PNG data for this image."
        }
    }
}

enum PNGImageWriter {
    static func pngData(from image: NSImage) throws -> Data {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw ImageSaveError.cannotCreatePNGData
        }

        return pngData
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let image: NSImage
    private var window: NSWindow?

    init(image: NSImage) {
        self.image = image
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMainMenu()

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let contentSize = fittedContentSize(for: image, in: screenFrame)
        let frame = NSRect(
            x: screenFrame.midX - contentSize.width / 2,
            y: screenFrame.midY - contentSize.height / 2,
            width: contentSize.width,
            height: contentSize.height
        )

        let imageView = NSImageView(frame: NSRect(origin: .zero, size: contentSize))
        imageView.image = image
        imageView.imageAlignment = .alignCenter
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Clipboard Image"
        window.contentView = imageView
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.setFrameAutosaveName("ClipboardImageWindow")

        self.window = window

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    @objc private func saveImage(_ sender: Any?) {
        guard let window else {
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.nameFieldStringValue = "Clipboard Image.png"
        panel.title = "Save Clipboard Image"

        panel.beginSheetModal(for: window) { [image] response in
            guard response == .OK, let url = panel.url else {
                return
            }

            do {
                let data = try PNGImageWriter.pngData(from: image)
                try data.write(to: url, options: .atomic)
            } catch {
                self.presentSaveError(error, for: window)
            }
        }
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.terminate(nil)
    }

    private func installMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(
            withTitle: "Quit Clipboard To Window",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        let saveItem = NSMenuItem(
            title: "Save Image...",
            action: #selector(saveImage(_:)),
            keyEquivalent: "s"
        )
        saveItem.target = self
        fileMenu.addItem(saveItem)
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        NSApp.mainMenu = mainMenu
    }

    private func presentSaveError(_ error: Error, for window: NSWindow) {
        let alert = NSAlert(error: error)
        alert.messageText = "The image could not be saved."
        alert.beginSheetModal(for: window)
    }

    private func fittedContentSize(for image: NSImage, in screenFrame: NSRect) -> NSSize {
        let imageSize = normalizedImageSize(image)
        let maxSize = NSSize(width: screenFrame.width * 0.9, height: screenFrame.height * 0.9)
        let scale = min(maxSize.width / imageSize.width, maxSize.height / imageSize.height, 1.0)

        return NSSize(
            width: max(imageSize.width * scale, 240),
            height: max(imageSize.height * scale, 160)
        )
    }

    private func normalizedImageSize(_ image: NSImage) -> NSSize {
        if image.size.width > 0, image.size.height > 0 {
            return image.size
        }

        for representation in image.representations {
            if representation.pixelsWide > 0, representation.pixelsHigh > 0 {
                return NSSize(width: representation.pixelsWide, height: representation.pixelsHigh)
            }
        }

        return NSSize(width: 800, height: 600)
    }
}

do {
    let image = try ClipboardImageReader.read()
    let app = NSApplication.shared
    let delegate = AppDelegate(image: image)

    app.delegate = delegate
    app.run()
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
