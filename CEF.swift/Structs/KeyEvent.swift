//
//  KeyEvent.swift
//  CEF.swift
//
//  Created by Tamas Lustyik on 2015. 07. 30..
//  Copyright © 2015. Tamas Lustyik. All rights reserved.
//

import Foundation

/// Structure representing keyboard event information.
public struct KeyEvent {
    /// The type of keyboard event.
    public var type: KeyEventType = .RawKeyDown

    /// Bit flags describing any pressed modifier keys. See
    /// cef_event_flags_t for values.
    public var modifiers: EventFlags = .None

    /// The Windows key code for the key event. This value is used by the DOM
    /// specification. Sometimes it comes directly from the event (i.e. on
    /// Windows) and sometimes it's determined using a mapping function. See
    /// WebCore/platform/chromium/KeyboardCodes.h for the list of values.
    public var windowsKeyCode: Int32 = 0
    
    /// The actual key code genenerated by the platform.
    public var nativeKeyCode: Int32 = 0
    
    /// Indicates whether the event is considered a "system key" event (see
    /// http://msdn.microsoft.com/en-us/library/ms646286(VS.85).aspx for details).
    /// This value will always be false on non-Windows platforms.
    public var isSystemKey: Bool = false
    
    /// The character generated by the keystroke.
    public var character: UInt16 = 0
    
    /// Same as |character| but unmodified by any concurrently-held modifiers
    /// (except shift). This is useful for working out shortcut keys.
    public var unmodifiedCharacter: UInt16 = 0
    
    /// True if the focus is currently on an editable field on the page. This is
    /// useful for determining if standard key events should be intercepted.
    public var focusOnEditableField: Bool = false
}

extension KeyEvent {
    func toCEF() -> cef_key_event_t {
        var cefStruct = cef_key_event_t()
        
        cefStruct.type = type.toCEF()
        cefStruct.modifiers = modifiers.toCEF().rawValue
        cefStruct.windows_key_code = windowsKeyCode
        cefStruct.native_key_code = nativeKeyCode
        cefStruct.is_system_key = isSystemKey ? 1 : 0
        cefStruct.character = character
        cefStruct.unmodified_character = unmodifiedCharacter
        cefStruct.focus_on_editable_field = focusOnEditableField ? 1 : 0
        
        return cefStruct
    }
    
    static func fromCEF(value: cef_key_event_t) -> KeyEvent {
        return KeyEvent(
            type: KeyEventType.fromCEF(value.type),
            modifiers: EventFlags.fromCEF(cef_event_flags_t(rawValue: value.modifiers)),
            windowsKeyCode: value.windows_key_code,
            nativeKeyCode: value.native_key_code,
            isSystemKey: value.is_system_key != 0,
            character: value.character,
            unmodifiedCharacter: value.unmodified_character,
            focusOnEditableField: value.focus_on_editable_field != 0
        )
    }
}