
import AppKit
import Cocoa
import Carbon.HIToolbox.Events
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    let window = NSWindow(contentRect: NSMakeRect(200, 200, 400, 200),
                          styleMask: [.titled],
                          backing: .buffered,
                          defer: true,
                          screen: nil)

    let field = NSTextView(frame: .zero)
    var windowSize: WindowSize
    var keyCombinationsOnly: Bool
    var delay: Double

    weak var timer: Timer?

    init(
        size: Size?,
        keyCombinationsOnly: Bool,
        delay: Double?
    ) {
        self.windowSize = getWindowSize(for: size ?? .normal)
        self.keyCombinationsOnly = keyCombinationsOnly
        self.delay = delay ?? 0.5
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        
        let visualEffect = NSVisualEffectView()
        visualEffect.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.material = .appearanceBased
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 10.0

        
        window.titleVisibility = .hidden
        window.styleMask.remove(.titled)
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        guard let constraints = window.contentView else {
            exit(1)
        }

        window.contentView?.addSubview(visualEffect)

        visualEffect.leadingAnchor.constraint(equalTo: constraints.leadingAnchor).isActive = true
        visualEffect.trailingAnchor.constraint(equalTo: constraints.trailingAnchor).isActive = true
        visualEffect.topAnchor.constraint(equalTo: constraints.topAnchor).isActive = true
        visualEffect.bottomAnchor.constraint(equalTo: constraints.bottomAnchor).isActive = true
        
        field.backgroundColor = .clear
        field.isSelectable = false
        field.translatesAutoresizingMaskIntoConstraints = false

        window.contentView?.addSubview(field)

        field.leadingAnchor.constraint(equalTo: constraints.leadingAnchor, constant: windowSize.paddingHorizontal).isActive = true
        field.trailingAnchor.constraint(equalTo: constraints.trailingAnchor, constant: -windowSize.paddingHorizontal).isActive = true
        field.topAnchor.constraint(equalTo: constraints.topAnchor, constant: windowSize.paddingVertical).isActive = true
        field.bottomAnchor.constraint(equalTo: constraints.bottomAnchor, constant: windowSize.paddingVertical).isActive = true
        
        listenToGlobalKeyboardEvents(self)

        guard let screen = window.screen else {
            return
        }

        let windowFrameSize = window.frame.size
        let screenFrame = screen.frame
        let x = (screenFrame.width / 2) - (windowFrameSize.width / 2)
        let y = (screenFrame.height * 0.15) - (windowFrameSize.height / 2)

        window.setFrame(NSMakeRect(x, y, windowFrameSize.width, windowFrameSize.height), display: true)
    }

    func updateText(_ untrimmed: String, onlyMeta: Bool = false) {
        let str = untrimmed.trimmingCharacters(in: .whitespacesAndNewlines)

        if str.count == 0 {
            if timer == nil {
                window.orderOut(self)
            }
            return
        } else if onlyMeta {
            self.timer?.invalidate()
            self.timer = nil
        } else {
            self.queueClear()
        }

        let windowFrame = window.frame

        var originalFrame = field.frame
        originalFrame.size.width = 500 // Max width of the view
        field.frame = originalFrame

        field.textStorage?.setAttributedString(NSAttributedString(string: str))
        field.font = NSFont(name:"Helvetica Bold", size: self.windowSize.fontSize)
        field.textColor = .textColor
        field.alignment = .center        

        guard let layoutManager = field.layoutManager, let textContainer = field.textContainer else {
            return
        }

        layoutManager.ensureLayout(for: textContainer)
        let computedSize = layoutManager.usedRect(for: textContainer).size
        field.frame.size = computedSize

        // Padding for constraints
        let windowFrameSize = CGSize(width: computedSize.width + (2 * windowSize.paddingHorizontal), height: computedSize.height + (2 * windowSize.paddingVertical))

        let x = windowFrame.midX - (windowFrameSize.width / 2)
        let y = windowFrame.midY - (windowFrameSize.height / 2)

        window.setFrame(NSMakeRect(x, y, windowFrameSize.width, windowFrameSize.height), display: true)
        window.makeKeyAndOrderFront(nil)
    }


    func keyboardHandler(_ cgEvent: CGEvent, _ delegate: AppDelegate) -> Unmanaged<CGEvent>? {
        if cgEvent.type == .keyDown || cgEvent.type == .keyUp || cgEvent.type == .flagsChanged {
            if let event = NSEvent(cgEvent: cgEvent) {
                let keyDown = event.type == .keyDown
                let flagsChanged = event.type == .flagsChanged

                if flagsChanged && timer == nil {
                    var isCommand = false
                    var needsShift = false
                    var text = ""
                    if event.modifierFlags.contains(.control) {
                        isCommand = true
                        text += " ⌃"
                    }
                    if event.modifierFlags.contains(.option) {
                        isCommand = true
                        text += " ⌥"
                    }
                    if event.modifierFlags.contains(.shift) {
                        if isCommand {
                            text += " ⇧"
                        } else {
                            needsShift = true
                        }
                    }
                    if event.modifierFlags.contains(.command) {
                        if needsShift {
                            text += " ⇧"
                        }
                        text += " ⌘"
                    }
                
                    DispatchQueue.main.async {
                        self.updateText(text, onlyMeta: true)
                    }
                } else if keyDown {
                    DispatchQueue.main.async {
                        self.updateText(getKeyPressText(event, keyCombinationsOnly: self.keyCombinationsOnly))
                    }
                    
                }
            }
        } else if cgEvent.type == .tapDisabledByUserInput || cgEvent.type == .tapDisabledByTimeout {
            CGEvent.tapEnable(tap: eventTap!, enable: true)
        }
        // focused app will receive the event
        return Unmanaged.passRetained(cgEvent)
    }

    func queueClear() {
        timer?.invalidate()
        let nextTimer = Timer.scheduledTimer(timeInterval: self.delay, target: self, selector: #selector(AppDelegate.clear), userInfo: nil, repeats: false)
        timer = nextTimer
    }

    @objc func clear() {
        timer?.invalidate()
        timer = nil
        self.updateText("")
    }
}
