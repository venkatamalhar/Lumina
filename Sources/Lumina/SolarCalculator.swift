import Foundation

struct SolarTimes {
    let sunrise: Date
    let sunset: Date
}

enum SolarCalculator {
    // Standard astronomical zenith for official sunrise and sunset: 90 degrees 50 arcminutes.
    private static let officialZenith = 90.8333 * .pi / 180.0

    static func calculate(for date: Date = Date(), latitude: Double, longitude: Double) -> SolarTimes? {
        let calendar = Calendar(identifier: .gregorian)
        guard let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) else {
            return nil
        }
        
        let latRad = latitude * .pi / 180.0
        
        guard let sunriseUTC = calculateEventTime(dayOfYear: Double(dayOfYear), latitude: latRad, longitude: longitude, isSunrise: true),
              let sunsetUTC = calculateEventTime(dayOfYear: Double(dayOfYear), latitude: latRad, longitude: longitude, isSunrise: false) else {
            return nil
        }
        
        var dateComponents = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
        dateComponents.nanosecond = 0
        
        dateComponents.hour = Int(sunriseUTC)
        dateComponents.minute = Int((sunriseUTC.truncatingRemainder(dividingBy: 1.0)) * 60.0)
        dateComponents.second = Int((sunriseUTC * 3600.0).truncatingRemainder(dividingBy: 60.0))
        guard let sunriseDate = calendar.date(from: dateComponents) else { return nil }
        
        dateComponents.hour = Int(sunsetUTC)
        dateComponents.minute = Int((sunsetUTC.truncatingRemainder(dividingBy: 1.0)) * 60.0)
        dateComponents.second = Int((sunsetUTC * 3600.0).truncatingRemainder(dividingBy: 60.0))
        guard let sunsetDate = calendar.date(from: dateComponents) else { return nil }
        
        return SolarTimes(sunrise: sunriseDate, sunset: sunsetDate)
    }
    
    private static func calculateEventTime(dayOfYear: Double, latitude: Double, longitude: Double, isSunrise: Bool) -> Double? {
        let lngHour = longitude / 15.0
        let t = isSunrise ? dayOfYear + ((6.0 - lngHour) / 24.0) : dayOfYear + ((18.0 - lngHour) / 24.0)
        
        let m = (0.9856 * t) - 3.289
        let mRad = m * .pi / 180.0
        
        var l = m + (1.916 * sin(mRad)) + (0.020 * sin(2.0 * mRad)) + 282.634
        if l >= 360.0 { l -= 360.0 }
        if l < 0.0 { l += 360.0 }
        let lRad = l * .pi / 180.0
        
        var ra = atan(0.91764 * tan(lRad)) * 180.0 / .pi
        if ra >= 360.0 { ra -= 360.0 }
        if ra < 0.0 { ra += 360.0 }
        
        // Match right ascension to the same quadrant as true longitude.
        let lQuadrant = floor(l / 90.0) * 90.0
        let raQuadrant = floor(ra / 90.0) * 90.0
        ra = (ra + (lQuadrant - raQuadrant)) / 15.0
        
        let sinDec = 0.39782 * sin(lRad)
        let cosDec = cos(asin(sinDec))
        
        let cosH = (cos(officialZenith) - (sinDec * sin(latitude))) / (cosDec * cos(latitude))
        
        // Handle midnight sun or polar night conditions gracefully.
        if cosH > 1.0 || cosH < -1.0 {
            return nil
        }
        
        var hDeg = acos(cosH) * 180.0 / .pi
        if isSunrise {
            hDeg = 360.0 - hDeg
        }
        let h = hDeg / 15.0
        
        let localMeanTime = h + ra - (0.06571 * t) - 6.622
        var ut = localMeanTime - lngHour
        if ut >= 24.0 { ut -= 24.0 }
        if ut < 0.0 { ut += 24.0 }
        
        return ut
    }
}
