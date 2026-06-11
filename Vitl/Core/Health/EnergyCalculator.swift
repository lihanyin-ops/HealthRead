import Foundation

enum EnergyCalculator {
    static func calculate(snapshot: DailyHealthSnapshot) -> Int {
        let sleep = clamp(Double(snapshot.sleepScore) / 100)
        let heart = clamp((snapshot.hrv / 60 * 0.6) + ((78 - snapshot.restingHeartRate) / 30 * 0.4))
        let activity = clamp((Double(snapshot.steps) / 10_000 * 0.5) + (snapshot.moveCalories / snapshot.moveGoal * 0.5))
        let oxygen = clamp((snapshot.oxygenSaturation - 92) / 8)
        let nightVitals = clamp((100 - abs(snapshot.nightWristTemperature) * 40) / 100)
        let score = sleep * 35 + heart * 25 + activity * 20 + oxygen * 10 + nightVitals * 10
        return Int(score.rounded())
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
