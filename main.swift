import AppKit
import Cocoa
import Carbon.HIToolbox.Events
import Foundation

let shiftedSpecialKeys = [
    NSNumber(48) : "⇤",
    NSNumber(50) : "~",
    NSNumber(27) : "_",
    NSNumber(24) : "+",
    NSNumber(33) : "{",
    NSNumber(30) : "}",
    NSNumber(41) : ":",
    NSNumber(39) : "\"",
    NSNumber(43) : "<",
    NSNumber(47) : ">",
    NSNumber(44) : "?",
    NSNumber(42) : "|",
    NSNumber(29) : ")",
    NSNumber(18) : "!",
    NSNumber(19) : "@",
    NSNumber(20) : "#",
    NSNumber(21) : "$",
    NSNumber(23) : "%",
    NSNumber(22) : "^",
    NSNumber(26) : "&",
    NSNumber(28) : "*",
    NSNumber(25) : "(",
    NSNumber(0) : "A",
    NSNumber(11) : "B",
    NSNumber(8) : "C",
    NSNumber(2) : "D",
    NSNumber(14) : "E",
    NSNumber(3) : "F",
    NSNumber(5) : "G",
    NSNumber(4) : "H",
    NSNumber(34) : "I",
    NSNumber(38) : "J",
    NSNumber(40) : "K",
    NSNumber(37) : "L",
    NSNumber(46) : "M",
    NSNumber(45) : "N",
    NSNumber(31) : "O",
    NSNumber(35) : "P",
    NSNumber(12) : "Q",
    NSNumber(15) : "R",
    NSNumber(1) : "S",
    NSNumber(17) : "T",
    NSNumber(32) : "U",
    NSNumber(9) : "V",
    NSNumber(13) : "W",
    NSNumber(7) : "X",
    NSNumber(16) : "Y",
    NSNumber(6) : "Z"
]

let specialKeys = [
    NSNumber(126) : "↑",
    NSNumber(125) : "↓",
    NSNumber(124) : "→",
    NSNumber(123) : "←",
    NSNumber(48) : "⇥",
    NSNumber(53) : "⎋",
    NSNumber(71) : "⎋",
    NSNumber(51) : "⌫",
    NSNumber(117) : "⌦",
    NSNumber(114) : "?",
    NSNumber(115) : "↖",
    NSNumber(119) : "↘",
    NSNumber(116) : "⇞",
    NSNumber(121) : "⇟",
    NSNumber(36) : "↩",
    NSNumber(76) : "↩",
    NSNumber(122) : "F1",
    NSNumber(120) : "F2",
    NSNumber(99) : "F3",
    NSNumber(118) : "F4",
    NSNumber(96) : "F5",
    NSNumber(97) : "F6",
    NSNumber(98) : "F7",
    NSNumber(100) : "F8",
    NSNumber(101) : "F9",
    NSNumber(109) : "F10",
    NSNumber(103) : "F11",
    NSNumber(111) : "F12",
    NSNumber(105) : "F13",
    NSNumber(107) : "F14",
    NSNumber(113) : "F15",
    NSNumber(106) : "F16",
    NSNumber(49) : "␣"
]

func getKeyPressText(_ event: NSEvent) -> String {
    let command = event.modifierFlags.contains(.command)
    let shift = event.modifierFlags.contains(.shift)
    let option = event.modifierFlags.contains(.option)
    let control = event.modifierFlags.contains(.control)

    var modifiers: UInt32 = 0
    var keyCode: CGKeyCode? = nil

    
    if let cgEvent = event.cgEvent {
        keyCode = CGKeyCode(cgEvent.getIntegerValueField(.keyboardEventKeycode))
    }

    var charCode = keyCode ?? 0

    var isShifted = false
    var needsShiftGlyph = false
    var isCommand = false
    var text = ""

    if control {
        modifiers |= UInt32(NSEvent.ModifierFlags.control.rawValue)
        isCommand = true
        text += " ⌃"
    }
    if option {
        modifiers |= UInt32(NSEvent.ModifierFlags.option.rawValue)
        isCommand = true
        text += " ⌥"
    }
    if shift {
        modifiers |= UInt32(NSEvent.ModifierFlags.shift.rawValue)
        isShifted = true
        if isCommand {
            text += " ⇧"
        } else {
            needsShiftGlyph = true
        }
    }
    if command {
        modifiers |= UInt32(NSEvent.ModifierFlags.command.rawValue)
        if needsShiftGlyph {
            text += " ⇧"
            needsShiftGlyph = false
        }
        isCommand = true
        text += " ⌘"
    }

    if let code = keyCode {
        if isShifted && !isCommand {
            let char = shiftedSpecialKeys[NSNumber(value: code)]
            if char != nil {
                return text + " " + char!
            }
        }

        let char = specialKeys[NSNumber(value: code)]
        if char != nil {
            if needsShiftGlyph {
                text += " ⇧"
            }

            return text + " " + char!
    }   
    }

    // Don't log simple keypresses (no modifiers). Only accelerators
    if text.count == 0 {
        return ""
    }

    var buf: [UniChar] = [0,0,0,0]
    var actualStringLength  = 1
    var deadKeys: UInt32 = 0

    let keyboard = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
    let rawLayoutData = TISGetInputSourceProperty(keyboard, kTISPropertyUnicodeKeyLayoutData)
    let layoutData = unsafeBitCast(rawLayoutData, to: CFData.self)
    let layout: UnsafePointer<UCKeyboardLayout> = unsafeBitCast(CFDataGetBytePtr(layoutData), to: UnsafePointer<UCKeyboardLayout>.self)
    let result = UCKeyTranslate(layout, charCode, UInt16(kUCKeyActionDown), (modifiers >> 8) & 0xff, UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysBit), &deadKeys, 4, &actualStringLength, &buf)

    if result != 0 {
        return ""
    }
    
    charCode = CGKeyCode(buf[0])
    text += " " + String(UnicodeScalar(UInt8(charCode)))


    // If this is a command string, put it in uppercase.
    if isCommand {
        return text.uppercased()
    }

    return text
} 

var eventTap: CFMachPort?

class AppDelegate: NSObject, NSApplicationDelegate {
    let window = NSWindow(contentRect: NSMakeRect(200, 200, 400, 200),
                          styleMask: [.titled],
                          backing: .buffered,
                          defer: true,
                          screen: nil)

    let field = NSTextView(frame: .zero)

    weak var timer: Timer?

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

        field.leadingAnchor.constraint(equalTo: constraints.leadingAnchor, constant: 12.0).isActive = true
        field.trailingAnchor.constraint(equalTo: constraints.trailingAnchor, constant: -12.0).isActive = true
        field.topAnchor.constraint(equalTo: constraints.topAnchor, constant: 10.0).isActive = true
        field.bottomAnchor.constraint(equalTo: constraints.bottomAnchor, constant: 10.0).isActive = true
        
        listenToGlobalKeyboardEvents(self)

        guard let screen = window.screen else {
            print("BOOM")
            return
        }

        let windowSize = window.frame.size
        let screenFrame = screen.frame
        let x = (screenFrame.width / 2) - (windowSize.width / 2)
        let y = (screenFrame.height * 0.15) - (windowSize.height / 2)

        window.setFrame(NSMakeRect(x, y, windowSize.width, windowSize.height), display: true)
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
        field.font = NSFont(name:"Helvetica Bold", size:18)
        field.textColor = .textColor
        field.alignment = .center        

        guard let layoutManager = field.layoutManager, let textContainer = field.textContainer else {
            return
        }

        layoutManager.ensureLayout(for: textContainer)
        let computedSize = layoutManager.usedRect(for: textContainer).size
        field.frame.size = computedSize

        // Padding for constraints
        let windowSize = CGSize(width: computedSize.width + 24, height: computedSize.height + 20)

        let x = windowFrame.midX - (windowSize.width / 2)
        let y = windowFrame.midY - (windowSize.height / 2)

        window.setFrame(NSMakeRect(x, y, windowSize.width, windowSize.height), display: true)
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
                        self.updateText(getKeyPressText(event))
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
        let nextTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(AppDelegate.clear), userInfo: nil, repeats: false)
        timer = nextTimer
    }

    @objc func clear() {
        timer?.invalidate()
        timer = nil
        self.updateText("")
    }
}

func listenToGlobalKeyboardEvents(_ delegate: AppDelegate) {
        DispatchQueue.global(qos: .userInteractive).async {
        let eventMask = [CGEventType.keyDown, CGEventType.keyUp, CGEventType.flagsChanged].reduce(CGEventMask(0), { $0 | (1 << $1.rawValue) })
        eventTap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: eventMask,
                callback: { (_, _, event, delegate_) -> Unmanaged<CGEvent>? in
                    let d = Unmanaged<AppDelegate>.fromOpaque(delegate_!).takeUnretainedValue()
                    return d.keyboardHandler(event, d)
                },
                userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(delegate).toOpaque()))
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap!, enable: true)
        CFRunLoopRun()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()