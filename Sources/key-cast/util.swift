import AppKit
import Cocoa
import Carbon.HIToolbox.Events
import Foundation
import SwiftCLI

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

func getKeyPressText(_ event: NSEvent, keyCombinationsOnly: Bool) -> String {
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
    if text.count == 0 && keyCombinationsOnly {
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

func getWindowSize(for size: Size) -> WindowSize {
    switch size {
        case .small:
            return WindowSize(fontSize: 18.0, paddingVertical: 10.0, paddingHorizontal: 12.0)
        case .large:
            return WindowSize(fontSize: 26.0, paddingVertical: 16.0, paddingHorizontal: 20.0)
        default:
            return WindowSize(fontSize: 22.0, paddingVertical: 14.0, paddingHorizontal: 18.0)
    }
}
