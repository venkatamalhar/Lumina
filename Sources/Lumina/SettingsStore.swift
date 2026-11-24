import Foundation
import Combine

enum ScheduleMode: String, CaseIterable, Identifiable {
    case manual = "Manual"
    case solar = "Sunset to Sunrise"
    case custom = "Custom Schedule"
    
    var id: String { rawValue }
}

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let isFilterActive = "lumina_is_filter_active"
        static let nightTemperature = "lumina_night_temperature"
        static let dayTemperature = "lumina_day_temperature"
        static let scheduleMode = "lumina_schedule_mode"
        static let customStartMinutes = "lumina_custom_start_minutes"
        static let customEndMinutes = "lumina_custom_end_minutes"
        static let transitionDurationMinutes = "lumina_transition_minutes"
    }
    
    @Published var isFilterActive: Bool {
        didSet {
            defaults.set(isFilterActive, forKey: Keys.isFilterActive)
            ScheduleManager.shared.evaluateSchedule(animated: true)
        }
    }
    
    @Published var nightTemperature: Double {
        didSet {
            defaults.set(nightTemperature, forKey: Keys.nightTemperature)
            if isFilterActive {
                ScheduleManager.shared.evaluateSchedule(animated: false)
            }
        }
    }
    
    @Published var dayTemperature: Double {
        didSet {
            defaults.set(dayTemperature, forKey: Keys.dayTemperature)
            ScheduleManager.shared.evaluateSchedule(animated: true)
        }
    }
    
    @Published var scheduleMode: ScheduleMode {
        didSet {
            defaults.set(scheduleMode.rawValue, forKey: Keys.scheduleMode)
            ScheduleManager.shared.evaluateSchedule(animated: true)
        }
    }
    
    @Published var customStartMinutes: Int {
        didSet {
            defaults.set(customStartMinutes, forKey: Keys.customStartMinutes)
            if scheduleMode == .custom {
                ScheduleManager.shared.evaluateSchedule(animated: true)
            }
        }
    }
    
    @Published var customEndMinutes: Int {
        didSet {
            defaults.set(customEndMinutes, forKey: Keys.customEndMinutes)
            if scheduleMode == .custom {
                ScheduleManager.shared.evaluateSchedule(animated: true)
            }
        }
    }
    
    @Published var transitionDurationMinutes: Double {
        didSet {
            defaults.set(transitionDurationMinutes, forKey: Keys.transitionDurationMinutes)
            ScheduleManager.shared.evaluateSchedule(animated: true)
        }
    }
    
    @Published var launchAtLogin: Bool {
        didSet { LaunchAtLoginManager.isEnabled = launchAtLogin }
    }
    
    private init() {
        self.isFilterActive = defaults.object(forKey: Keys.isFilterActive) as? Bool ?? true
        self.nightTemperature = defaults.object(forKey: Keys.nightTemperature) as? Double ?? 3400.0
        self.dayTemperature = defaults.object(forKey: Keys.dayTemperature) as? Double ?? 6500.0
        
        if let modeString = defaults.string(forKey: Keys.scheduleMode),
           let mode = ScheduleMode(rawValue: modeString) {
            self.scheduleMode = mode
        } else {
            self.scheduleMode = .solar
        }
        
        self.customStartMinutes = defaults.object(forKey: Keys.customStartMinutes) as? Int ?? (21 * 60)
        self.customEndMinutes = defaults.object(forKey: Keys.customEndMinutes) as? Int ?? (7 * 60)
        self.transitionDurationMinutes = defaults.object(forKey: Keys.transitionDurationMinutes) as? Double ?? 30.0
        self.launchAtLogin = LaunchAtLoginManager.isEnabled
    }
}
