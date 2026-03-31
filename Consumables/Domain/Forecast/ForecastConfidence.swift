import Foundation

enum ForecastConfidence: String, Codable, Sendable {
    case manualOnly
    case historyBacked
}
