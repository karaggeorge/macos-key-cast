import Cocoa
import SwiftCLI

final class KeyCastCommand: Command {
    let name = "key-cast"

    @Flag("-k", "--key-combinations", description: "Show key combinations only")
    var keyCombinationsOnly: Bool

    @Key("-s", "--size", description: "Size of the window and font to use. Defaults to normal")
    var size: Size?

    @Key("-d", "--delay", description: "How long the key remains on screen in seconds")
    var delay: Double?

    func execute() throws {
        if !AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary) {
            print("Please enable accessibility permissions")
            exit(1)
        }

        let app = NSApplication.shared
        let delegate = AppDelegate(
            size: size,
            keyCombinationsOnly: keyCombinationsOnly,
            delay: delay
        )
        app.delegate = delegate
        app.run()
    }
}

let keyCast = CLI(singleCommand: KeyCastCommand())
_ = keyCast.go()
