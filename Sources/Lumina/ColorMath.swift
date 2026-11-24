import Foundation

struct ColorMultipliers: Equatable {
    let red: Float
    let green: Float
    let blue: Float
    
    static let neutral = ColorMultipliers(red: 1.0, green: 1.0, blue: 1.0)
    
    func interpolated(to target: ColorMultipliers, progress: Float) -> ColorMultipliers {
        let clamped = max(0.0, min(1.0, progress))
        return ColorMultipliers(
            red: red + (target.red - red) * clamped,
            green: green + (target.green - green) * clamped,
            blue: blue + (target.blue - blue) * clamped
        )
    }
}

enum ColorMath {
    // Calculates RGB gamma multipliers for a correlated color temperature between 1000K and 6500K.
    // Based on blackbody radiation curves normalized so 6500K produces unity multipliers (1.0, 1.0, 1.0).
    static func multipliers(forTemperature kelvin: Double) -> ColorMultipliers {
        let temp = max(1000.0, min(6500.0, kelvin)) / 100.0
        
        let red: Double
        if temp <= 66.0 {
            red = 255.0
        } else {
            let r = temp - 60.0
            red = 329.698727446 * pow(r, -0.1332047592)
        }
        
        let green: Double
        if temp <= 66.0 {
            green = 99.4708025861 * log(temp) - 161.1195681661
        } else {
            let g = temp - 60.0
            green = 288.1221695283 * pow(g, -0.0755148492)
        }
        
        let blue: Double
        if temp >= 66.0 {
            blue = 255.0
        } else if temp <= 19.0 {
            blue = 0.0
        } else {
            let b = temp - 10.0
            blue = 138.5177312231 * log(b) - 305.0447927307
        }
        
        // Normalize against standard 6500K daylight values to prevent dimming red at baseline.
        let clampedR = max(0.0, min(255.0, red))
        let clampedG = max(0.0, min(255.0, green))
        let clampedB = max(0.0, min(255.0, blue))
        
        return ColorMultipliers(
            red: Float(clampedR / 255.0),
            green: Float(clampedG / 255.0),
            blue: Float(clampedB / 255.0)
        )
    }
}
