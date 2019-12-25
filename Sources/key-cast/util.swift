import Cocoa
import Carbon.HIToolbox.Events

private let shiftedSpecialKeys = [
    48: "⇤",
    50: "~",
    27: "_",
    24: "+",
    33: "{",
    30: "}",
    41: ":",
    39: "\"",
    43: "<",
    47: ">",
    44: "?",
    42: "|",
    29: ")",
    18: "!",
    19: "@",
    20: "#",
    21: "$",
    23: "%",
    22: "^",
    26: "&",
    28: "*",
    25: "(",
    0: "A",
    11: "B",
    8: "C",
    2: "D",
    14: "E",
    3: "F",
    5: "G",
    4: "H",
    34: "I",
    38: "J",
    40: "K",
    37: "L",
    46: "M",
    45: "N",
    31: "O",
    35: "P",
    12: "Q",
    15: "R",
    1: "S",
    17: "T",
    32: "U",
    9: "V",
    13: "W",
    7: "X",
    16: "Y",
    6: "Z"
]

private let specialKeys = [
    126: "↑",
    125: "↓",
    124: "→",
    123: "←",
    48: "⇥",
    53: "⎋",
    71: "⎋",
    51: "⌫",
    117: "⌦",
    114: "?",
    115: "↖",
    119: "↘",
    116: "⇞",
    121: "⇟",
    36: "↩",
    76: "↩",
    122: "F1",
    120: "F2",
    99: "F3",
    118: "F4",
    96: "F5",
    97: "F6",
    98: "F7",
    100: "F8",
    101: "F9",
    109: "F10",
    103: "F11",
    111: "F12",
    105: "F13",
    107: "F14",
    113: "F15",
    106: "F16",
    49: "␣"
]

func getKeyPressText(_ event: NSEvent, keyCombinationsOnly: Bool) -> String {
    let command = event.modifierFlags.contains(.command)
    let shift = event.modifierFlags.contains(.shift)
    let option = event.modifierFlags.contains(.option)
    let control = event.modifierFlags.contains(.control)

    var modifiers: UInt32 = 0
    var keyCode: CGKeyCode?

    if let cgEvent = event.cgEvent {
        keyCode = CGKeyCode(cgEvent.getIntegerValueField(.keyboardEventKeycode))
    }

    var characterCode = keyCode ?? 0
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
            let character = shiftedSpecialKeys[Int(code)]
            if character != nil {
                return text + " " + character!
            }
        }

        let character = specialKeys[Int(code)]
        if character != nil {
            if needsShiftGlyph {
                text += " ⇧"
            }

            return text + " " + character!
        }
    }

    // Don't log simple keypresses (no modifiers). Only accelerators.
    if text.count == 0 && keyCombinationsOnly {
        return ""
    }

    var buffer: [UniChar] = [0, 0, 0, 0]
    var actualStringLength  = 1
    var deadKeys: UInt32 = 0

    let keyboard = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
    let rawLayoutData = TISGetInputSourceProperty(keyboard, kTISPropertyUnicodeKeyLayoutData)
    let layoutData = unsafeBitCast(rawLayoutData, to: CFData.self)
    let layout: UnsafePointer<UCKeyboardLayout> = unsafeBitCast(CFDataGetBytePtr(layoutData), to: UnsafePointer<UCKeyboardLayout>.self)
    let result = UCKeyTranslate(layout, characterCode, UInt16(kUCKeyActionDown), (modifiers >> 8) & 0xff, UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysBit), &deadKeys, 4, &actualStringLength, &buffer)
 
    if result != 0 {
        return ""
    }

    characterCode = CGKeyCode(buffer[0])
    text += " " + String(UnicodeScalar(UInt8(characterCode)))

    // If this is a command string, put it in uppercase.
    if isCommand {
        return text.uppercased()
    }

    return text
}

