import Foundation
import ServiceManagement

enum LaunchAtLoginManager {
    static var isSupported: Bool {
        if #available(macOS 13.0, *) {
            return true
        }
        return false
    }
    
    static var isEnabled: Bool {
        get {
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            }
            return false
        }
        set {
            if #available(macOS 13.0, *) {
                do {
                    if newValue {
                        if SMAppService.mainApp.status != .enabled {
                            try SMAppService.mainApp.register()
                        }
                    } else {
                        if SMAppService.mainApp.status == .enabled {
                            try SMAppService.mainApp.unregister()
                        }
                    }
                } catch {
                    // System will prompt user in System Settings if blocked.
                }
            }
        }
    }
}
