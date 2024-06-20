import Foundation

extension Date {
    
    /// example return : "Friday"
    func dayOfWeek() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: self).capitalized
        // or use capitalized(with: locale) if you want
    }
    
    /// shows relative name for "today", "yesterday"; otherwise fallback to longer date, like "Fri. 12/15"
    var relativeDateString:  String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EE. M/d" // Custom format for non-relative dates
        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else {
            return dateFormatter.string(from: self)
        }
    }
    
    /// 45 minutes or 1h 2m
    static func formatMillisecondsConditional(_ milliseconds: Int) -> String {
        // Create a DateComponentsFormatter instance
        let formatter = DateComponentsFormatter()
        
        // Convert milliseconds to seconds
        let seconds = Double(milliseconds) / 1000.0
        
        // Determine the formatting style based on duration
        if seconds < 3600 { // Less than an hour
            formatter.allowedUnits = [.minute]
            formatter.unitsStyle = .full
        } else { // An hour or more
            formatter.allowedUnits = [.hour, .minute]
            formatter.unitsStyle = .abbreviated
        }
        
        // Use the formatter to generate the formatted string
        return formatter.string(from: seconds) ?? "Formatting failed"
    }
    
    /// example return : "Fri"
    func dayOfTheWeekShortened() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEEEEE"
        return dateFormatter.string(from: self)
    }
    
    /// true for any hour starting from bottom of this hour
    /// example: now it's 3:30pm; 2pm is false, 3pm is true, 4pm is true
    var isCurrentHourOrLater: Bool {
        return self >= .now.roundedDownToHour()
    }
    
    /// example: `date` is 3:27pm; any time 3-4pm is true
    func clockHourContains(_ date: Date) -> Bool {
        let bottomOfCurrentHour = self.roundedDownToHour()
        let bottomOfNextHour =  Calendar.current.date(
            byAdding: .hour,
            value: 1,
            to: self)!.roundedDownToHour()
        
        return bottomOfCurrentHour <= date && bottomOfNextHour > date
    }
    
    func isWithin(nHours n: Int) -> Bool {
        // Get the current date and time
        let now = Date()

        // Use Calendar to calculate the difference between now and the start date
        let difference = Calendar.current.dateComponents([.hour], from: self, to: now)

        // Check if the difference is within three hours
        guard let hourDifference = difference.hour, hourDifference >= 0 && hourDifference < n else {
            return false
        }
        return true
    }

    private func roundedDownToHour() -> Date {
        var components = NSCalendar.current.dateComponents([.minute, .second, .nanosecond], from: self)
        let minute = components.minute ?? 0
        let second = components.second ?? 0
        let nanosecond = components.nanosecond ?? 0
        components.minute = -minute
        components.second = -second
        components.nanosecond = -nanosecond
        return Calendar.current.date(byAdding: components, to: self)!
    }
}
