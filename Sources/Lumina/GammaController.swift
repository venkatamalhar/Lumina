import Foundation
import CoreGraphics
import AppKit

final class GammaController: @unchecked Sendable {
    static let shared = GammaController()
    
    private let tableCapacity: UInt32 = 256
    private var baselineTables: [CGDirectDisplayID: ([CGGammaValue], [CGGammaValue], [CGGammaValue])] = [:]
    private var currentMultipliers: ColorMultipliers = .neutral
    private var transitionTimer: Timer?
    private let lock = NSLock()
    
    private init() {
        registerReconfigurationCallback()
    }
    
    deinit {
        CGDisplayRemoveReconfigurationCallback(reconfigurationCallback, nil)
        restoreDisplaySettings()
    }
    
    func apply(multipliers: ColorMultipliers, animated: Bool = true, duration: TimeInterval = 0.8) {
        lock.lock()
        transitionTimer?.invalidate()
        transitionTimer = nil
        
        let start = currentMultipliers
        let target = multipliers
        
        guard animated && duration > 0 else {
            currentMultipliers = target
            applyCurrentMultipliersToAllDisplays()
            lock.unlock()
            return
        }
        
        let startTime = Date()
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let rawProgress = Float(elapsed / duration)
            let progress = min(1.0, rawProgress)
            // Ease in-out timing curve for subtle transitions
            let smoothed = progress * progress * (3.0 - 2.0 * progress)
            
            self.lock.lock()
            self.currentMultipliers = start.interpolated(to: target, progress: smoothed)
            self.applyCurrentMultipliersToAllDisplays()
            
            if progress >= 1.0 {
                timer.invalidate()
                self.transitionTimer = nil
            }
            self.lock.unlock()
        }
        
        RunLoop.main.add(timer, forMode: .common)
        transitionTimer = timer
        lock.unlock()
    }
    
    func restoreDisplaySettings(animated: Bool = true, duration: TimeInterval = 0.5) {
        lock.lock()
        transitionTimer?.invalidate()
        transitionTimer = nil
        
        let start = currentMultipliers
        let target = ColorMultipliers.neutral
        
        guard animated && duration > 0 else {
            currentMultipliers = target
            CGDisplayRestoreColorSyncSettings()
            baselineTables.removeAll()
            lock.unlock()
            return
        }
        
        let startTime = Date()
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let rawProgress = Float(elapsed / duration)
            let progress = min(1.0, rawProgress)
            let smoothed = progress * progress * (3.0 - 2.0 * progress)
            
            self.lock.lock()
            self.currentMultipliers = start.interpolated(to: target, progress: smoothed)
            self.applyCurrentMultipliersToAllDisplays()
            
            if progress >= 1.0 {
                timer.invalidate()
                self.transitionTimer = nil
                CGDisplayRestoreColorSyncSettings()
                self.baselineTables.removeAll()
                self.currentMultipliers = .neutral
            }
            self.lock.unlock()
        }
        
        RunLoop.main.add(timer, forMode: .common)
        transitionTimer = timer
        lock.unlock()
    }
    
    private func activeDisplayIDs() -> [CGDirectDisplayID] {
        var displayCount: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &displayCount) == .success, displayCount > 0 else {
            return [CGMainDisplayID()]
        }
        
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        guard CGGetActiveDisplayList(displayCount, &displays, &displayCount) == .success else {
            return [CGMainDisplayID()]
        }
        
        return displays
    }
    
    private func getOrCaptureBaseline(for displayID: CGDirectDisplayID) -> ([CGGammaValue], [CGGammaValue], [CGGammaValue]) {
        if let cached = baselineTables[displayID] {
            return cached
        }
        
        // Ensure display is in clean native state before sampling baseline calibration.
        CGDisplayRestoreColorSyncSettings()
        
        var sampleCount: UInt32 = 0
        var red = [CGGammaValue](repeating: 0, count: Int(tableCapacity))
        var green = [CGGammaValue](repeating: 0, count: Int(tableCapacity))
        var blue = [CGGammaValue](repeating: 0, count: Int(tableCapacity))
        
        let result = CGGetDisplayTransferByTable(displayID, tableCapacity, &red, &green, &blue, &sampleCount)
        
        // If current table read fails or is flat, generate an identity ramp from 0.0 to 1.0.
        let isValid = result == .success && sampleCount > 1 && (red.last ?? 0) > 0.5
        let baseline: ([CGGammaValue], [CGGammaValue], [CGGammaValue])
        
        if isValid {
            baseline = (red, green, blue)
        } else {
            let identityRamp = (0..<tableCapacity).map { CGGammaValue($0) / CGGammaValue(tableCapacity - 1) }
            baseline = (identityRamp, identityRamp, identityRamp)
        }
        
        baselineTables[displayID] = baseline
        return baseline
    }
    
    private func applyCurrentMultipliersToAllDisplays() {
        let displays = activeDisplayIDs()
        let mult = currentMultipliers
        
        for displayID in displays {
            let baseline = getOrCaptureBaseline(for: displayID)
            let count = baseline.0.count
            
            var newRed = [CGGammaValue](repeating: 0, count: count)
            var newGreen = [CGGammaValue](repeating: 0, count: count)
            var newBlue = [CGGammaValue](repeating: 0, count: count)
            
            for i in 0..<count {
                newRed[i] = baseline.0[i] * mult.red
                newGreen[i] = baseline.1[i] * mult.green
                newBlue[i] = baseline.2[i] * mult.blue
            }
            
            CGSetDisplayTransferByTable(displayID, UInt32(count), newRed, newGreen, newBlue)
        }
    }
    
    private func registerReconfigurationCallback() {
        CGDisplayRegisterReconfigurationCallback(reconfigurationCallback, nil)
    }
    
    fileprivate func handleReconfiguration(flags: CGDisplayChangeSummaryFlags) {
        // Only react once configuration finishes to prevent tearing during resolution changes.
        if !flags.contains(.beginConfigurationFlag) {
            lock.lock()
            baselineTables.removeAll()
            applyCurrentMultipliersToAllDisplays()
            lock.unlock()
        }
    }
}

private func reconfigurationCallback(
    display: CGDirectDisplayID,
    flags: CGDisplayChangeSummaryFlags,
    userInfo: UnsafeMutableRawPointer?
) {
    DispatchQueue.main.async {
        GammaController.shared.handleReconfiguration(flags: flags)
    }
}
