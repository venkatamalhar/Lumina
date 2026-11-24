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
    
    var body: some View {
        VStack(spacing: 0) {
            // macOS-native top segmented switcher
            Picker("", selection: $settings.selectedTab) {
                ForEach(SettingsTab.allCases) { tab in
                    Label(tab.title, systemImage: tab.icon).tag(tab.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 14)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch settings.selectedTab {
                    case 1:
                        scheduleContent
                    case 2:
                        calibrationContent
                    default:
                        generalContent
                    }
                }
                .padding(24)
            }
        }
        .frame(width: 500, height: 420)
    }
    
    private var generalContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            GroupBox("Startup & Controls") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Launch Lumina at login", isOn: $settings.launchAtLogin)
                        .disabled(!LaunchAtLoginManager.isSupported)
                    
                    Divider()
                    
                    HStack {
                        Text("Global Shortcut")
                        Spacer()
                        Text("⌥⇧B (Option + Shift + B)")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(10)
            }
            
            GroupBox("Monitors") {
                VStack(alignment: .leading, spacing: 10) {
                    let displayCount = getActiveDisplayCount()
                    HStack {
                        Text("Active Displays")
                        Spacer()
                        Text("\(displayCount) display\(displayCount == 1 ? "" : "s") detected")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Lumina automatically synchronizes gamma tables across all connected monitors and handles display reconnection.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(10)
            }
        }
    }
    
    private var scheduleContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            GroupBox("Automation") {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Schedule Mode", selection: $settings.scheduleMode) {
                        ForEach(ScheduleMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }
                .padding(10)
            }
            
            if settings.scheduleMode == .solar {
                GroupBox("Solar Parameters") {
                    VStack(alignment: .leading, spacing: 12) {
                        if let solar = scheduler.currentSolarTimes {
                            let formatter = solarDateFormatter
                            HStack {
                                Text("Calculated Sunrise")
                                Spacer()
                                Text(formatter.string(from: solar.sunrise))
                                    .foregroundColor(.secondary)
                            }
                            Divider()
                            HStack {
                                Text("Calculated Sunset")
                                Spacer()
                                Text(formatter.string(from: solar.sunset))
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("Solar calculation in progress...")
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Transition Duration")
                            Spacer()
                            Slider(value: $settings.transitionDurationMinutes, in: 10...60, step: 5)
                                .frame(width: 140)
                            Text("\(Int(settings.transitionDurationMinutes)) min")
                                .monospacedDigit()
                                .frame(width: 55, alignment: .trailing)
                        }
                    }
                    .padding(10)
                }
            } else if settings.scheduleMode == .custom {
                GroupBox("Custom Window") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Start Time")
                            Spacer()
                            TimePickerView(minutesFromMidnight: $settings.customStartMinutes)
                        }
                        Divider()
                        HStack {
                            Text("End Time")
                            Spacer()
                            TimePickerView(minutesFromMidnight: $settings.customEndMinutes)
                        }
                    }
                    .padding(10)
                }
            }
        }
    }
    
    private var calibrationContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            GroupBox("Warmth Level") {
                VStack(alignment: .leading, spacing: 12) {
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
                .padding(10)
            }
            
            GroupBox("Color Physics") {
                Text("Display transfer tables modulate hardware RGB lookup tables via Core Graphics (`CGSetDisplayTransferByTable`). Values are normalized relative to standard D65 6500K daylight.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(10)
            }
        }
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
