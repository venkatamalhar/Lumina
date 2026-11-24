import SwiftUI
import CoreGraphics

enum SettingsTab: Int, CaseIterable, Identifiable {
    case general = 0
    case schedule = 1
    case calibration = 2
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .general: return "General"
        case .schedule: return "Schedule"
        case .calibration: return "Calibration"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .schedule: return "clock"
        case .calibration: return "slider.horizontal.3"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settings = SettingsStore.shared
    @ObservedObject var scheduler = ScheduleManager.shared
    
    @AppStorage("lumina_settings_tab") private var selectedTab: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // macOS-native top segmented switcher
            Picker("", selection: $selectedTab) {
                ForEach(SettingsTab.allCases) { tab in
                    Label(tab.title, systemImage: tab.icon).tag(tab.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
            
            // Tab content container
            Group {
                switch selectedTab {
                case 1:
                    scheduleContent
                case 2:
                    calibrationContent
                default:
                    generalContent
                }
            }
            .padding(20)
            
            Spacer(minLength: 0)
        }
        .frame(width: 480, height: 380)
    }
    
    private var generalContent: some View {
        Form {
            Section {
                Toggle("Launch Lumina at login", isOn: $settings.launchAtLogin)
                    .disabled(!LaunchAtLoginManager.isSupported)
                
                LabeledContent("Global Toggle Shortcut") {
                    Text("⌥⇧B (Option + Shift + B)")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Startup & Controls")
            }
            
            Section {
                let displayCount = getActiveDisplayCount()
                LabeledContent("Active Displays") {
                    Text("\(displayCount) display\(displayCount == 1 ? "" : "s") detected")
                        .foregroundColor(.secondary)
                }
                
                Text("Lumina automatically synchronizes gamma tables across all connected monitors and handles display reconnection.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Monitors")
            }
        }
        .formStyle(.grouped)
    }
    
    private var scheduleContent: some View {
        Form {
            Section {
                Picker("Schedule Mode", selection: $settings.scheduleMode) {
                    ForEach(ScheduleMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
            } header: {
                Text("Automation")
            }
            
            if settings.scheduleMode == .solar {
                Section {
                    if let solar = scheduler.currentSolarTimes {
                        let formatter = solarDateFormatter
                        LabeledContent("Calculated Sunrise") {
                            Text(formatter.string(from: solar.sunrise))
                        }
                        LabeledContent("Calculated Sunset") {
                            Text(formatter.string(from: solar.sunset))
                        }
                    } else {
                        Text("Solar calculation in progress...")
                            .foregroundColor(.secondary)
                    }
                    
                    LabeledContent("Transition Duration") {
                        HStack {
                            Slider(value: $settings.transitionDurationMinutes, in: 10...60, step: 5)
                            Text("\(Int(settings.transitionDurationMinutes)) min")
                                .monospacedDigit()
                                .frame(width: 55, alignment: .trailing)
                        }
                    }
                } header: {
                    Text("Solar Parameters")
                }
            } else if settings.scheduleMode == .custom {
                Section {
                    HStack {
                        Text("Start Time")
                        Spacer()
                        TimePickerView(minutesFromMidnight: $settings.customStartMinutes)
                    }
                    
                    HStack {
                        Text("End Time")
                        Spacer()
                        TimePickerView(minutesFromMidnight: $settings.customEndMinutes)
                    }
                } header: {
                    Text("Custom Window")
                }
            }
        }
        .formStyle(.grouped)
    }
    
    private var calibrationContent: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Night Temperature")
                        Spacer()
                        Text("\(Int(settings.nightTemperature)) K")
                            .monospacedDigit()
                            .fontWeight(.medium)
                    }
                    
                    Slider(value: $settings.nightTemperature, in: 1900...6500)
                        .tint(.orange)
                    
                    let mult = ColorMath.multipliers(forTemperature: settings.nightTemperature)
                    HStack(spacing: 12) {
                        ColorChannelBadge(channel: "R", value: mult.red)
                        ColorChannelBadge(channel: "G", value: mult.green)
                        ColorChannelBadge(channel: "B", value: mult.blue)
                    }
                }
            } header: {
                Text("Warmth Level")
            }
            
            Section {
                Text("Display transfer tables modulate hardware RGB lookup tables via Core Graphics (`CGSetDisplayTransferByTable`). Values are normalized relative to standard D65 6500K daylight.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Color Physics")
            }
        }
        .formStyle(.grouped)
    }
    
    private var solarDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private func getActiveDisplayCount() -> Int {
        var count: UInt32 = 0
        if CGGetActiveDisplayList(0, nil, &count) == .success {
            return Int(count)
        }
        return 1
    }
}

struct ColorChannelBadge: View {
    let channel: String
    let value: Float
    
    var body: some View {
        HStack(spacing: 4) {
            Text(channel)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            Text(String(format: "%.2f", value))
                .font(.caption2)
                .monospacedDigit()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(4)
    }
}

struct TimePickerView: View {
    @Binding var minutesFromMidnight: Int
    
    private var hourBinding: Binding<Int> {
        Binding(
            get: { minutesFromMidnight / 60 },
            set: { minutesFromMidnight = ($0 * 60) + (minutesFromMidnight % 60) }
        )
    }
    
    private var minuteBinding: Binding<Int> {
        Binding(
            get: { minutesFromMidnight % 60 },
            set: { minutesFromMidnight = ((minutesFromMidnight / 60) * 60) + $0 }
        )
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Picker("", selection: hourBinding) {
                ForEach(0..<24, id: \.self) { hour in
                    Text(String(format: "%02d", hour)).tag(hour)
                }
            }
            .labelsHidden()
            .frame(width: 55)
            
            Text(":")
            
            Picker("", selection: minuteBinding) {
                ForEach(0..<60, id: \.self) { minute in
                    Text(String(format: "%02d", minute)).tag(minute)
                }
            }
            .labelsHidden()
            .frame(width: 55)
        }
    }
}
