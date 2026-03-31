import Foundation

enum UrgencyLevel: String, Codable, Sendable {
    case red
    case yellow
    case green

    static func from(daysRemaining: Int, thresholdDays: Int) -> UrgencyLevel {
        let safeThreshold = max(1, thresholdDays)
        switch daysRemaining {
        case ...0:
            return .red
        case 1...safeThreshold:
            return .yellow
        default:
            return .green
        }
    }
}
