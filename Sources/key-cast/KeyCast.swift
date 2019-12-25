import Cocoa
import Carbon.HIToolbox.Events
import SwiftCLI

enum Size: String, ConvertibleFromString, CaseIterable {
    case small
    case normal
    case large
}

struct WindowSize {
    let fontSize: CGFloat
    let paddingVertical: CGFloat
    let paddingHorizontal: CGFloat
}

extension WindowSize {
    init(size: Size) {
        switch size {
            case .small:
                self.init(fontSize: 18.0, paddingVertical: 10.0, paddingHorizontal: 12.0)
            case .large:
                self.init(fontSize: 26.0, paddingVertical: 16.0, paddingHorizontal: 20.0)
            default:
                self.init(fontSize: 22.0, paddingVertical: 14.0, paddingHorizontal: 18.0)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let window: NSWindow = {
        let window = NSWindow(
            contentRect: CGRect(x: 200, y: 200, width: 400, height: 200),
            styleMask: [.titled],
            backing: .buffered,
            defer: true
        )

        window.titleVisibility = .hidden
        window.styleMask.remove(.titled)
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        return window
    }()

    let field: NSTextView = {
        let textView = NSTextView()
        textView.backgroundColor = .clear
        textView.isSelectable = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    let windowSize: WindowSize
    let keyCombinationsOnly: Bool
    let delay: Double
    let display: Int?

    weak var timer: Timer?
    var eventTap: CFMachPort?

    init(
        size: Size?,
        keyCombinationsOnly: Bool,
        delay: Double?,
        display: Int?
    ) {
        self.windowSize = WindowSize(size: size ?? .normal)
        self.keyCombinationsOnly = keyCombinationsOnly
        self.delay = delay ?? 0.5
        self.display = display
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let visualEffect = NSVisualEffectView()
        visualEffect.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.material = .appearanceBased
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 10.0

        guard let contentView = window.contentView else {
            fatalError()
        }

        contentView.addSubview(visualEffect)
        contentView.addSubview(field)

        visualEffect.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        visualEffect.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        visualEffect.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        visualEffect.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        field.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: windowSize.paddingHorizontal).isActive = true
        field.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -windowSize.paddingHorizontal).isActive = true
        field.topAnchor.constraint(equalTo: contentView.topAnchor, constant: windowSize.paddingVertical).isActive = true
        field.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: windowSize.paddingVertical).isActive = true

        listenToGlobalKeyboardEvents()

        guard let screen = (display == nil ? nil : NSScreen.screens.first { screen in
            (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? Int) == display
        }) ?? window.screen else {
            return
        }

        let windowFrameSize = window.frame.size
        let screenFrame = screen.frame
        let x = screenFrame.origin.x + (screenFrame.width / 2) - (windowFrameSize.width / 2)
        let y = screenFrame.origin.y + (screenFrame.height * 0.15) - (windowFrameSize.height / 2)

        window.setFrame(NSMakeRect(x, y, windowFrameSize.width, windowFrameSize.height), display: true)
    }

    func updateText(_ untrimmed: String, onlyMeta: Bool = false) {
        let string = untrimmed.trimmingCharacters(in: .whitespacesAndNewlines)

        if string.count == 0 {
            if timer == nil {
                window.orderOut(self)
            }
            return
        } else if onlyMeta {
            timer?.invalidate()
            timer = nil
        } else {
            queueClear()
        }

        let windowFrame = window.frame

        var originalFrame = field.frame
        originalFrame.size.width = 500 // Max width of the view
        field.frame = originalFrame
        field.textStorage?.setAttributedString(NSAttributedString(string: string))
        field.textColor = .textColor
        field.alignment = .center

        if #available(macOS 10.15, *) {
           field.font = NSFont.monospacedSystemFont(ofSize: windowSize.fontSize, weight: .bold)
        } else {
           field.font = NSFont.systemFont(ofSize: windowSize.fontSize, weight: .bold)
        }

        guard
            let layoutManager = field.layoutManager,
            let textContainer = field.textContainer
        else {
            return
        }

        layoutManager.ensureLayout(for: textContainer)
        let computedSize = layoutManager.usedRect(for: textContainer).size
        field.frame.size = computedSize

        // Padding for constraints
        let windowFrameSize = CGSize(width: computedSize.width + (2 * windowSize.paddingHorizontal), height: computedSize.height + (2 * windowSize.paddingVertical))

        let x = windowFrame.midX - (windowFrameSize.width / 2)
        let y = windowFrame.midY - (windowFrameSize.height / 2)
        let frame = CGRect(x: x, y: y, width: windowFrameSize.width, height: windowFrameSize.height)

        window.setFrame(frame, display: true)
        window.makeKeyAndOrderFront(nil)
    }

    func keyboardHandler(_ cgEvent: CGEvent) -> Unmanaged<CGEvent>? {
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

        // The focused app will receive the event.
        return Unmanaged.passRetained(cgEvent)
    }

    func queueClear() {
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.timer?.invalidate()
            self?.timer = nil
            self?.updateText("")
        }
    }

    func listenToGlobalKeyboardEvents() {
        DispatchQueue.global(qos: .userInteractive).async {
            let eventMask = [CGEventType.keyDown, CGEventType.keyUp, CGEventType.flagsChanged].reduce(CGEventMask(0), { $0 | (1 << $1.rawValue) })

            self.eventTap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: eventMask,
                callback: { (_, _, event, delegate_) -> Unmanaged<CGEvent>? in
                    let this = Unmanaged<AppDelegate>.fromOpaque(delegate_!).takeUnretainedValue()
                    return this.keyboardHandler(event)
                },
                userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            )

            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, self.eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: self.eventTap!, enable: true)
            CFRunLoopRun()
        }
    }
}
