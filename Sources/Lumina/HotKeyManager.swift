import Foundation
import Carbon

final class HotKeyManager: @unchecked Sendable {
    static let shared = HotKeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    var onHotKeyPressed: (() -> Void)?
    
    private init() {}
    
    deinit {
        unregister()
    }
    
    // Registers a global hotkey with zero accessibility permissions required.
    // Default: Option + Shift + B (Key code 11 for 'B' in standard US keyboard layout).
    func registerDefaultToggleKey(keyCode: UInt32 = 11, modifiers: UInt32 = UInt32(optionKey | shiftKey)) {
        unregister()
        
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            { (_, event, _) -> OSStatus in
                HotKeyManager.shared.onHotKeyPressed?()
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )
        
        guard status == noErr else { return }
        
        let hotKeyID = EventHotKeyID(signature: OSType(0x4C554D49), id: 1) // 'LUMI'
        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
    }
    
    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }
}
