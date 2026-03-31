import Foundation

struct ForecastSnapshot: Equatable, Sendable {
    let estimatedCycleDays: Int
    let predictedOutDate: Date
    let daysRemaining: Int
    let urgency: UrgencyLevel
    let confidence: ForecastConfidence
    let usableCycleCount: Int
}
