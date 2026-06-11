import Foundation

struct AIHealthSummary: Codable, Equatable {
    var statusTitle: String
    var coreInsight: String
    var actionableAdvice: String
    var deepTrend: String

    static func fallback(for snapshot: DailyHealthSnapshot) -> AIHealthSummary {
        AIHealthSummary(
            statusTitle: "电量不足，需要回血",
            coreInsight: "你昨晚睡眠\(String(format: "%.1f", snapshot.sleepTotal))小时，深睡比例正常，但 HRV \(Int(snapshot.hrv))ms 略低于你的7日均值，提示身体恢复尚未完全到位。静息心率\(Int(snapshot.restingHeartRate)) BPM，建议今天以轻度活动为主。",
            actionableAdvice: "① 今天避免高强度有氧训练，可以选择瑜伽或散步。② 午休20分钟有助于下午的精力恢复。③ 今日饮水量偏低，建议在下午3点前补充至少500mL。",
            deepTrend: "根据你近7天的数据趋势，心肺健康（VO₂ max）正在缓慢提升，从上周的41.2提升至本周的42.0。这与你近期规律的有氧运动直接相关。建议将锻炼时间固定在下午4-6点之间。"
        )
    }
}

enum AvatarType: String, CaseIterable, Identifiable, Codable {
    case man
    case woman
    case alien
    case monster
    case dog
    case cat

    var id: String { rawValue }

    var label: String {
        switch self {
        case .man: return "男人"
        case .woman: return "女人"
        case .alien: return "外星人"
        case .monster: return "怪兽"
        case .dog: return "狗"
        case .cat: return "猫"
        }
    }

    var emoji: String {
        switch self {
        case .man: return "🧑"
        case .woman: return "👩"
        case .alien: return "👽"
        case .monster: return "👾"
        case .dog: return "🐕"
        case .cat: return "🐈"
        }
    }
}

struct DailyHealthSnapshot: Codable, Identifiable, Hashable {
    let id: UUID
    var day: Int
    var weekday: String
    var isToday: Bool
    var energyScore: Int

    var moveCalories: Double
    var moveGoal: Double
    var exerciseMinutes: Double
    var exerciseGoal: Double
    var standHours: Int
    var standGoal: Int

    var workoutType: String
    var workoutDuration: Double
    var workoutCalories: Double
    var workoutDistance: Double

    var steps: Int
    var walkingRunningDistance: Double
    var flightsClimbed: Int
    var walkingSpeed: Double
    var walkingStepLength: Double
    var walkingDoubleSupportTime: Double
    var walkingAsymmetry: Double

    var restingHeartRate: Double
    var walkingHeartRateAvg: Double
    var heartRateMax: Double
    var heartRateMin: Double
    var hrv: Double
    var cardioFitness: Double
    var highHeartRateAlert: Bool
    var lowHeartRateAlert: Bool
    var irregularRhythmAlert: Bool

    var oxygenSaturation: Double
    var sleepTotal: Double
    var sleepDeep: Double
    var sleepREM: Double
    var sleepLight: Double
    var sleepAwake: Double
    var sleepEfficiency: Double
    var sleepOnset: Double
    var sleepScore: Int

    var nightHeartRateAvg: Double
    var nightRespiratoryRate: Double
    var nightWristTemperature: Double
    var nightOxygenSaturation: Double
    var environmentalNoise: Double
    var timeInDaylight: Double
    var headphoneAudioLevel: Double
    var headphoneAudioExposure: Double

    var waterIntake: Int
    var stressLevel: Int

    init(
        day: Int,
        weekday: String,
        isToday: Bool = false,
        energyScore: Int,
        moveCalories: Double,
        moveGoal: Double = 500,
        exerciseMinutes: Double,
        exerciseGoal: Double = 30,
        standHours: Int,
        standGoal: Int = 12,
        workoutType: String,
        workoutDuration: Double,
        workoutCalories: Double,
        workoutDistance: Double,
        steps: Int,
        walkingRunningDistance: Double,
        flightsClimbed: Int,
        walkingSpeed: Double,
        walkingStepLength: Double,
        walkingDoubleSupportTime: Double,
        walkingAsymmetry: Double,
        restingHeartRate: Double,
        walkingHeartRateAvg: Double,
        heartRateMax: Double,
        heartRateMin: Double,
        hrv: Double,
        cardioFitness: Double,
        oxygenSaturation: Double,
        sleepTotal: Double,
        sleepDeep: Double,
        sleepREM: Double,
        sleepLight: Double,
        sleepAwake: Double,
        sleepEfficiency: Double,
        sleepOnset: Double,
        sleepScore: Int,
        nightHeartRateAvg: Double,
        nightRespiratoryRate: Double,
        nightWristTemperature: Double,
        nightOxygenSaturation: Double,
        environmentalNoise: Double,
        timeInDaylight: Double,
        headphoneAudioLevel: Double,
        headphoneAudioExposure: Double,
        waterIntake: Int,
        stressLevel: Int
    ) {
        self.id = UUID()
        self.day = day
        self.weekday = weekday
        self.isToday = isToday
        self.energyScore = energyScore
        self.moveCalories = moveCalories
        self.moveGoal = moveGoal
        self.exerciseMinutes = exerciseMinutes
        self.exerciseGoal = exerciseGoal
        self.standHours = standHours
        self.standGoal = standGoal
        self.workoutType = workoutType
        self.workoutDuration = workoutDuration
        self.workoutCalories = workoutCalories
        self.workoutDistance = workoutDistance
        self.steps = steps
        self.walkingRunningDistance = walkingRunningDistance
        self.flightsClimbed = flightsClimbed
        self.walkingSpeed = walkingSpeed
        self.walkingStepLength = walkingStepLength
        self.walkingDoubleSupportTime = walkingDoubleSupportTime
        self.walkingAsymmetry = walkingAsymmetry
        self.restingHeartRate = restingHeartRate
        self.walkingHeartRateAvg = walkingHeartRateAvg
        self.heartRateMax = heartRateMax
        self.heartRateMin = heartRateMin
        self.hrv = hrv
        self.cardioFitness = cardioFitness
        self.highHeartRateAlert = false
        self.lowHeartRateAlert = false
        self.irregularRhythmAlert = false
        self.oxygenSaturation = oxygenSaturation
        self.sleepTotal = sleepTotal
        self.sleepDeep = sleepDeep
        self.sleepREM = sleepREM
        self.sleepLight = sleepLight
        self.sleepAwake = sleepAwake
        self.sleepEfficiency = sleepEfficiency
        self.sleepOnset = sleepOnset
        self.sleepScore = sleepScore
        self.nightHeartRateAvg = nightHeartRateAvg
        self.nightRespiratoryRate = nightRespiratoryRate
        self.nightWristTemperature = nightWristTemperature
        self.nightOxygenSaturation = nightOxygenSaturation
        self.environmentalNoise = environmentalNoise
        self.timeInDaylight = timeInDaylight
        self.headphoneAudioLevel = headphoneAudioLevel
        self.headphoneAudioExposure = headphoneAudioExposure
        self.waterIntake = waterIntake
        self.stressLevel = stressLevel
    }
}
