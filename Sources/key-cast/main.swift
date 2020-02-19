import Cocoa
import SwiftCLI

final class KeyCastCommand: Command {
    let name = "key-cast"

    @Flag("-k", "--key-combinations", description: "Show key combinations only")
    var keyCombinationsOnly: Bool

    @Key("-s", "--size", description: "Size of the window and font to use. Defaults to normal")
    var size: Size?

    @Key("-t", "--delay", description: "How long the key remains on screen in seconds")
    var delay: Double?

    @Key("-d", "--display", description: "Display number of the screen to show the UI in. Defaults to the main screen.")
    var display: Int?

    @Key("-b", "--bounds", description: "JSON object with bounds of a rectangle to show the UI in. Example: '{\"bounds\":[[955,627],[656,384]]}'")
    var bounds: String?

    func execute() throws {
        if !AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary) {
            print("Please enable accessibility permissions")
            exit(1)
        }

        let app = NSApplication.shared
        let delegate = AppDelegate(
            size: size,
            keyCombinationsOnly: keyCombinationsOnly,
            delay: delay,
            display: display,
            bounds: bounds
        )
        app.delegate = delegate
        app.run()
    }
}

let keyCast = CLI(singleCommand: KeyCastCommand())
_ = keyCast.go()
