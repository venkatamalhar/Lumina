import Foundation
import Combine
import AppKit

final class ScheduleManager: ObservableObject {
    static let shared = ScheduleManager()
    
    @Published private(set) var currentKelvin: Double = 6500.0
    @Published private(set) var currentSolarTimes: SolarTimes?
    @Published private(set) var statusDescription: String = "Inactive"
    
    private var checkTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let settings = SettingsStore.shared
    
    private init() {
        startPeriodicCheck()
    }
    
    func start() {
        LocationProvider.shared.requestLocationIfAuthorized()
        LocationProvider.shared.onCoordinateUpdate = { [weak self] _ in
            self?.evaluateSchedule()
        }
        evaluateSchedule()
    }
    
    func toggleFilter() {
        settings.isFilterActive.toggle()
    }
    
    private func startPeriodicCheck() {
        checkTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.evaluateSchedule()
        }
        RunLoop.main.add(timer, forMode: .common)
        checkTimer = timer
    }
    
    func evaluateSchedule(animated: Bool = true) {
        guard settings.isFilterActive else {
            currentKelvin = settings.dayTemperature
            statusDescription = "Disabled"
            GammaController.shared.restoreDisplaySettings(animated: animated, duration: 0.5)
            AppDelegate.shared?.updateStatusIcon(isFiltering: false)
            return
        }
        
        let now = Date()
        
        switch settings.scheduleMode {
        case .manual:
            currentKelvin = settings.nightTemperature
            statusDescription = "Manual warmth: \(Int(currentKelvin)) K"
            
        case .solar:
            let coords = LocationProvider.shared.currentCoordinates()
            let solar = SolarCalculator.calculate(for: now, latitude: coords.latitude, longitude: coords.longitude)
            currentSolarTimes = solar
            
            if let solar = solar {
                let (targetTemp, status) = computeSolarTemperature(now: now, sunrise: solar.sunrise, sunset: solar.sunset)
                currentKelvin = targetTemp
                statusDescription = status
            } else {
                currentKelvin = settings.nightTemperature
                statusDescription = "Solar calculation unavailable"
            }
            
        case .custom:
            let (targetTemp, status) = computeCustomScheduleTemperature(now: now)
            currentKelvin = targetTemp
            statusDescription = status
        }
        
        let multipliers = ColorMath.multipliers(forTemperature: currentKelvin)
        GammaController.shared.apply(multipliers: multipliers, animated: animated, duration: 0.8)
        AppDelegate.shared?.updateStatusIcon(isFiltering: currentKelvin < settings.dayTemperature)
    }
    
    private func computeSolarTemperature(now: Date, sunrise: Date, sunset: Date) -> (Double, String) {
        let transitionSecs = max(60.0, settings.transitionDurationMinutes * 60.0)
        let dayTemp = settings.dayTemperature
        let nightTemp = settings.nightTemperature
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        // Transition around sunset
        if now >= sunset.addingTimeInterval(-transitionSecs / 2) && now <= sunset.addingTimeInterval(transitionSecs / 2) {
            let elapsed = now.timeIntervalSince(sunset.addingTimeInterval(-transitionSecs / 2))
            let factor = elapsed / transitionSecs
            let temp = dayTemp + (nightTemp - dayTemp) * factor
            return (temp, "Transitioning to night mode")
        }
        
        // Transition around sunrise
        if now >= sunrise.addingTimeInterval(-transitionSecs / 2) && now <= sunrise.addingTimeInterval(transitionSecs / 2) {
            let elapsed = now.timeIntervalSince(sunrise.addingTimeInterval(-transitionSecs / 2))
            let factor = elapsed / transitionSecs
            let temp = nightTemp + (dayTemp - nightTemp) * factor
            return (temp, "Transitioning to day mode")
        }
        
        if now > sunset {
            let coords = LocationProvider.shared.currentCoordinates()
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
            let nextSunrise = SolarCalculator.calculate(for: tomorrow, latitude: coords.latitude, longitude: coords.longitude)?.sunrise ?? sunrise
            return (nightTemp, "Active until sunrise (\(formatter.string(from: nextSunrise)))")
        } else if now < sunrise {
            return (nightTemp, "Active until sunrise (\(formatter.string(from: sunrise)))")
        } else {
            return (dayTemp, "Daylight active until sunset (\(formatter.string(from: sunset)))")
        }
    }
    
    private func computeCustomScheduleTemperature(now: Date) -> (Double, String) {
        let calendar = Calendar.current
        let currentMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let start = settings.customStartMinutes
        let end = settings.customEndMinutes
        
        let isNightTime: Bool
        if start < end {
            isNightTime = currentMinutes >= start && currentMinutes < end
        } else {
            // Spans midnight, e.g. 21:00 (1260) to 07:00 (420)
            isNightTime = currentMinutes >= start || currentMinutes < end
        }
        
        let startFormatted = String(format: "%02d:%02d", start / 60, start % 60)
        let endFormatted = String(format: "%02d:%02d", end / 60, end % 60)
        
        if isNightTime {
            return (settings.nightTemperature, "Active until \(endFormatted)")
        } else {
            return (settings.dayTemperature, "Inactive until \(startFormatted)")
        }
    }
}
