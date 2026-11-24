import SwiftUI

struct MenuBarView: View {
    @ObservedObject var settings = SettingsStore.shared
    @ObservedObject var scheduler = ScheduleManager.shared
    
    var onOpenSettings: () -> Void
    var onQuit: () -> Void
    
    private var roundedKelvin: Int {
        Int((settings.nightTemperature / 25.0).rounded() * 25.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with primary toggle
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemSymbolName: "sun.max.fill")
                            .foregroundColor(.orange)
                            .imageScale(.medium)
                        Text("Lumina")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    Text(scheduler.statusDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 12)
                Toggle("", isOn: $settings.isFilterActive)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            
            Divider()
            
            // Warmth slider (continuous, no tick marks)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Color Temperature")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(roundedKelvin) K")
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: $settings.nightTemperature,
                    in: 1900...6500
                )
                .tint(.orange)
                
                HStack {
                    Text("Warm (1900K)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Daylight (6500K)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .opacity(settings.isFilterActive ? 1.0 : 0.45)
            .disabled(!settings.isFilterActive)
            
            Divider()
            
            // Schedule Mode Selection
            VStack(alignment: .leading, spacing: 6) {
                Text("Schedule Mode")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $settings.scheduleMode) {
                    ForEach(ScheduleMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            
            Divider()
            
            // Footer actions and shortcut reminder
            HStack(alignment: .center) {
                Button("Preferences…") {
                    onOpenSettings()
                }
                .buttonStyle(.plain)
                .font(.footnote)
                
                Spacer()
                
                Text("⌥⇧B")
                    .font(.caption2)
                    .monospaced()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(4)
                    .foregroundColor(.secondary)
                
                Button("Quit") {
                    onQuit()
                }
                .buttonStyle(.plain)
                .font(.footnote)
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(width: 330)
    }
}

private extension Image {
    init(systemSymbolName: String) {
        self.init(systemName: systemSymbolName)
    }
}
