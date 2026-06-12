import Foundation

enum PeerMetricType: String, Codable, CaseIterable, Identifiable {
    case energy
    case restingHeartRate
    case hrv
    case sleepDuration
    case sleepEfficiency
    case activityMinutes
    case steps
    case cardioFitness

    var id: String { rawValue }
}

enum PeerRangeStatus: String, Codable {
    case below
    case healthy
    case ideal
    case above
    case limited

    var label: String {
        switch self {
        case .below: return "偏低"
        case .healthy: return "健康"
        case .ideal: return "理想"
        case .above: return "偏高"
        case .limited: return "参考"
        }
    }
}

struct PeerMetricInsight: Codable, Identifiable, Hashable {
    var id: String { metric.rawValue }

    let metric: PeerMetricType
    let label: String
    let value: Double
    let unit: String
    let low: Double
    let normalLow: Double
    let normalHigh: Double
    let high: Double
    let status: PeerRangeStatus
    let message: String

    var normalizedPosition: Double {
        guard high > low else { return 0.5 }
        return min(max((value - low) / (high - low), 0), 1)
    }

    var isInHealthyRange: Bool {
        if status == .healthy || status == .ideal { return true }
        if status == .above {
            return [.energy, .hrv, .sleepEfficiency, .activityMinutes, .cardioFitness].contains(metric)
        }
        if status == .below, metric == .restingHeartRate, value >= low {
            return true
        }
        return false
    }

    var formattedValue: String {
        if value.rounded() == value {
            return "\(Int(value))\(unit)"
        }
        return "\(String(format: "%.1f", value))\(unit)"
    }

    var formattedHealthyRange: String {
        "\(format(normalLow))-\(format(normalHigh))\(unit)"
    }

    var statusLabel: String {
        if status == .above, [.energy, .hrv, .sleepEfficiency, .cardioFitness].contains(metric) {
            return "优于参考"
        }
        if status == .above, metric == .activityMinutes {
            return "高于建议"
        }
        if status == .below, metric == .restingHeartRate, value >= low {
            return "偏低但常见"
        }
        return status.label
    }

    private func format(_ value: Double) -> String {
        value.rounded() == value ? "\(Int(value))" : String(format: "%.1f", value)
    }
}

struct DailyPeerInsight: Codable, Equatable {
    static let rangeVersion = "peer-range-v2"

    let dateKey: String
    let snapshotFingerprint: String
    let age: Int
    let gender: String
    let ageBand: String
    let rangeVersion: String
    let generatedAt: Date
    let metrics: [PeerMetricInsight]
    let summary: String

    var healthyCount: Int {
        metrics.filter(\.isInHealthyRange).count
    }

    var needsAttentionCount: Int {
        metrics.count - healthyCount
    }

    func matches(snapshot: DailyHealthSnapshot, age: Int, gender: String) -> Bool {
        dateKey == Self.dateKey(for: snapshot)
        && snapshotFingerprint == Self.fingerprint(for: snapshot)
        && self.age == age
        && self.gender == gender
        && rangeVersion == Self.rangeVersion
    }

    static func dateKey(for snapshot: DailyHealthSnapshot) -> String {
        "\(snapshot.day)-\(snapshot.weekday)"
    }

    static func fingerprint(for snapshot: DailyHealthSnapshot) -> String {
        [
            snapshot.energyScore,
            Int(snapshot.restingHeartRate.rounded()),
            Int(snapshot.hrv.rounded()),
            Int((snapshot.sleepTotal * 10).rounded()),
            Int(snapshot.sleepEfficiency.rounded()),
            Int(snapshot.exerciseMinutes.rounded()),
            Int((snapshot.cardioFitness * 10).rounded())
        ].map(String.init).joined(separator: "-")
    }
}

enum PeerBenchmarkService {
    static func makeInsight(snapshot: DailyHealthSnapshot, history: [DailyHealthSnapshot], age: Int, gender: String) -> DailyPeerInsight {
        let ageBand = ageBand(for: age)
        let metrics = [
            metric(.energy, label: "能量分", value: Double(snapshot.energyScore), unit: "分", range: .init(low: 40, normalLow: 68, normalHigh: 88, high: 100)),
            metric(.restingHeartRate, label: "静息心率", value: snapshot.restingHeartRate, unit: "BPM", range: restingHeartRateRange(history: history)),
            metric(.hrv, label: "HRV", value: snapshot.hrv, unit: "ms", range: personalBaselineRange(values: history.map(\.hrv), fallback: hrvPopulationFallback(age: age))),
            metric(.sleepDuration, label: "睡眠时长", value: snapshot.sleepTotal, unit: "h", range: sleepDurationRange(age: age)),
            metric(.sleepEfficiency, label: "睡眠效率", value: snapshot.sleepEfficiency, unit: "%", range: personalBaselineRange(values: history.map(\.sleepEfficiency), fallback: .init(low: 70, normalLow: 85, normalHigh: 96, high: 100))),
            metric(.activityMinutes, label: "运动分钟", value: snapshot.exerciseMinutes, unit: "分钟", range: .init(low: 0, normalLow: 21, normalHigh: 43, high: 90)),
            metric(.cardioFitness, label: "心肺体能", value: snapshot.cardioFitness, unit: "ml/kg/min", range: cardioFitnessRange(age: age, gender: gender))
        ]

        return DailyPeerInsight(
            dateKey: DailyPeerInsight.dateKey(for: snapshot),
            snapshotFingerprint: DailyPeerInsight.fingerprint(for: snapshot),
            age: age,
            gender: gender,
            ageBand: ageBand,
            rangeVersion: DailyPeerInsight.rangeVersion,
            generatedAt: Date(),
            metrics: metrics,
            summary: summary(for: metrics, ageBand: ageBand)
        )
    }

    static func promptContext(for insight: DailyPeerInsight) -> String {
        let rows = insight.metrics.map { metric in
            "\(metric.label)：用户\(metric.formattedValue)，同龄健康参考范围\(metric.formattedHealthyRange)，状态\(metric.statusLabel)。\(metric.message)"
        }.joined(separator: "\n")

        return """
        同龄健康参考范围：年龄段\(insight.ageBand)，参考版本\(insight.rangeVersion)。范围综合公开健康指南、同龄同性别人群参考和用户个人历史基线；不能新增百分位或声称来自真实平台用户分布。
        \(rows)
        本地总评：\(insight.summary)
        """
    }

    private static func metric(_ type: PeerMetricType, label: String, value: Double, unit: String, range: ReferenceRange) -> PeerMetricInsight {
        let status = status(for: value, range: range)
        return PeerMetricInsight(
            metric: type,
            label: label,
            value: value,
            unit: unit,
            low: range.low,
            normalLow: range.normalLow,
            normalHigh: range.normalHigh,
            high: range.high,
            status: status,
            message: message(label: label, value: value, unit: unit, status: status, range: range)
        )
    }

    private static func status(for value: Double, range: ReferenceRange) -> PeerRangeStatus {
        if value < range.low || value > range.high { return .limited }
        if value < range.normalLow { return .below }
        if value > range.normalHigh { return .above }

        let center = (range.normalLow + range.normalHigh) / 2
        let idealRadius = (range.normalHigh - range.normalLow) * 0.25
        return abs(value - center) <= idealRadius ? .ideal : .healthy
    }

    private static func message(label: String, value: Double, unit: String, status: PeerRangeStatus, range: ReferenceRange) -> String {
        let healthyRange = "\(format(range.normalLow))-\(format(range.normalHigh))\(unit)"
        switch status {
        case .below:
            if label == "HRV" || label == "睡眠效率" {
                return "\(label)低于你的近期个人基线，建议结合压力、饮酒、训练负荷和睡眠连续性观察。"
            }
            if label == "运动分钟" {
                return "\(label)低于成年人每日运动建议折算值，今天可以用散步或轻有氧补足。"
            }
            if label == "静息心率", value >= range.low {
                return "\(label)低于普通成人常见范围，但在运动人群中并不少见；若伴随不适需咨询医生。"
            }
            return "\(label)低于同龄健康参考范围，建议结合睡眠、压力和近期活动量一起观察。"
        case .healthy:
            return "\(label)处在同龄健康参考范围内，当前表现稳定。"
        case .ideal:
            return "\(label)接近同龄健康参考范围的理想区间，可以继续保持当前节奏。"
        case .above:
            if label == "HRV" || label == "心肺体能" {
                return "\(label)高于同龄健康参考范围，通常代表恢复储备或心肺基础较好。"
            }
            if label == "睡眠效率" || label == "能量分" {
                return "\(label)高于同龄健康参考范围，当前表现积极，可以继续保持。"
            }
            if label == "运动分钟" {
                return "\(label)高于每日建议折算值，活动量充足，注意结合恢复和疲劳感调整强度。"
            }
            return "\(label)高于同龄健康参考范围，建议关注恢复、补水和训练强度。"
        case .limited:
            return "\(label)超出参考边界，本范围仅作健康趋势参考，健康范围约为\(healthyRange)。"
        }
    }

    private static func summary(for metrics: [PeerMetricInsight], ageBand: String) -> String {
        let healthy = metrics.filter(\.isInHealthyRange).count
        let attention = metrics.count - healthy
        let strongest = metrics.first { $0.status == .ideal } ?? metrics.first
        let watchList = metrics.filter { $0.isInHealthyRange == false }.map(\.label).prefix(2).joined(separator: "、")

        if attention == 0 {
            return "你的\(metrics.count)项指标均位于\(ageBand)同龄健康参考范围内，\(strongest?.label ?? "整体状态")表现最稳。"
        }
        return "你的\(metrics.count)项指标中有\(healthy)项位于\(ageBand)同龄健康参考范围内，\(watchList)建议继续观察。"
    }

    private static func ageBand(for age: Int) -> String {
        switch age {
        case ..<25: return "18-24"
        case 25..<35: return "25-34"
        case 35..<45: return "35-44"
        case 45..<55: return "45-54"
        default: return "55+"
        }
    }

    private static func restingHeartRateRange(history: [DailyHealthSnapshot]) -> ReferenceRange {
        let guideline = ReferenceRange(low: 40, normalLow: 60, normalHigh: 100, high: 110)
        let values = history.map(\.restingHeartRate).filter { $0 > 0 }
        guard values.count >= 5 else { return guideline }

        let average = values.reduce(0, +) / Double(values.count)
        let personalLow = max(40, average - 8)
        let personalHigh = min(100, average + 8)
        return .init(
            low: guideline.low,
            normalLow: min(guideline.normalLow, personalLow),
            normalHigh: max(personalHigh, min(guideline.normalHigh, average + 12)),
            high: guideline.high
        )
    }

    private static func hrvPopulationFallback(age: Int) -> ReferenceRange {
        switch age {
        case ..<25: return .init(low: 18, normalLow: 45, normalHigh: 95, high: 130)
        case 25..<35: return .init(low: 16, normalLow: 38, normalHigh: 85, high: 120)
        case 35..<45: return .init(low: 14, normalLow: 32, normalHigh: 75, high: 105)
        case 45..<55: return .init(low: 12, normalLow: 26, normalHigh: 65, high: 95)
        default: return .init(low: 10, normalLow: 20, normalHigh: 55, high: 85)
        }
    }

    private static func sleepDurationRange(age: Int) -> ReferenceRange {
        if age >= 65 {
            return .init(low: 5.5, normalLow: 7, normalHigh: 8, high: 10)
        }
        return .init(low: 5.5, normalLow: 7, normalHigh: 9, high: 10.5)
    }

    private static func cardioFitnessRange(age: Int, gender: String) -> ReferenceRange {
        let isFemale = gender.lowercased().contains("female") || gender == "woman"

        switch age {
        case ..<30:
            return isFemale
                ? .init(low: 22, normalLow: 31, normalHigh: 42, high: 55)
                : .init(low: 25, normalLow: 35, normalHigh: 48, high: 62)
        case 30..<40:
            return isFemale
                ? .init(low: 20, normalLow: 29, normalHigh: 39, high: 52)
                : .init(low: 23, normalLow: 32, normalHigh: 45, high: 58)
        case 40..<50:
            return isFemale
                ? .init(low: 18, normalLow: 26, normalHigh: 36, high: 48)
                : .init(low: 21, normalLow: 29, normalHigh: 42, high: 54)
        case 50..<60:
            return isFemale
                ? .init(low: 16, normalLow: 23, normalHigh: 33, high: 44)
                : .init(low: 19, normalLow: 26, normalHigh: 38, high: 50)
        default:
            return isFemale
                ? .init(low: 14, normalLow: 20, normalHigh: 29, high: 39)
                : .init(low: 17, normalLow: 23, normalHigh: 34, high: 45)
        }
    }

    private static func personalBaselineRange(values: [Double], fallback: ReferenceRange) -> ReferenceRange {
        let cleaned = values.filter { $0 > 0 }.sorted()
        guard cleaned.count >= 5 else { return fallback }

        let p25 = percentile(cleaned, 0.25)
        let p75 = percentile(cleaned, 0.75)
        let spread = max(p75 - p25, 1)

        return .init(
            low: max(0, p25 - spread * 1.2),
            normalLow: p25,
            normalHigh: p75,
            high: p75 + spread * 1.8
        )
    }

    private static func percentile(_ sorted: [Double], _ percentile: Double) -> Double {
        guard sorted.isEmpty == false else { return 0 }
        let position = percentile * Double(sorted.count - 1)
        let lower = Int(floor(position))
        let upper = Int(ceil(position))
        if lower == upper { return sorted[lower] }
        let weight = position - Double(lower)
        return sorted[lower] * (1 - weight) + sorted[upper] * weight
    }

    private static func format(_ value: Double) -> String {
        value.rounded() == value ? "\(Int(value))" : String(format: "%.1f", value)
    }
}

private struct ReferenceRange {
    let low: Double
    let normalLow: Double
    let normalHigh: Double
    let high: Double
}
