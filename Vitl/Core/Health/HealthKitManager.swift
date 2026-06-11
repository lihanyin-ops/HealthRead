import Foundation
import HealthKit

@MainActor
final class HealthKitManager: ObservableObject {
    @Published var authorizationStatus: String = "未请求"

    private let healthStore = HKHealthStore()

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = "当前设备不可用"
            return
        }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
            HKQuantityType.quantityType(forIdentifier: .appleExerciseTime),
            HKQuantityType.quantityType(forIdentifier: .appleStandTime),
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
            HKQuantityType.quantityType(forIdentifier: .flightsClimbed),
            HKQuantityType.quantityType(forIdentifier: .walkingSpeed),
            HKQuantityType.quantityType(forIdentifier: .walkingStepLength),
            HKQuantityType.quantityType(forIdentifier: .walkingDoubleSupportPercentage),
            HKQuantityType.quantityType(forIdentifier: .walkingAsymmetryPercentage),
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate),
            HKQuantityType.quantityType(forIdentifier: .walkingHeartRateAverage),
            HKQuantityType.quantityType(forIdentifier: .heartRate),
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
            HKQuantityType.quantityType(forIdentifier: .vo2Max),
            HKQuantityType.quantityType(forIdentifier: .oxygenSaturation),
            HKQuantityType.quantityType(forIdentifier: .respiratoryRate),
            HKQuantityType.quantityType(forIdentifier: .appleSleepingWristTemperature),
            HKQuantityType.quantityType(forIdentifier: .environmentalAudioExposure),
            HKQuantityType.quantityType(forIdentifier: .timeInDaylight),
            HKQuantityType.quantityType(forIdentifier: .headphoneAudioExposure),
            HKQuantityType.quantityType(forIdentifier: .dietaryWater),
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)
        ].compactMap { $0 }.reduce(into: Set<HKObjectType>()) { $0.insert($1) }

        let writeTypes: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .dietaryWater)
        ].compactMap { $0 }.reduce(into: Set<HKSampleType>()) { $0.insert($1) }

        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            authorizationStatus = "已授权 \(readTypes.count) 项数据"
        } catch {
            authorizationStatus = "授权失败"
        }
    }

    func fetchTodaySnapshot() async -> DailyHealthSnapshot {
        let history = await fetchRecentSnapshots(days: 1)
        return history.last ?? VitlMockData.today
    }

    func fetchRecentSnapshots(days: Int = 7) async -> [DailyHealthSnapshot] {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationStatus = "当前设备不可用，使用本地数据"
            return VitlMockData.snapshots
        }

        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        var snapshots: [DailyHealthSnapshot] = []

        for offset in stride(from: max(days - 1, 0), through: 0, by: -1) {
            guard let start = calendar.date(byAdding: .day, value: -offset, to: todayStart),
                  let end = calendar.date(byAdding: .day, value: 1, to: start) else { continue }
            let fallback = fallbackSnapshot(for: start, isToday: offset == 0)
            let snapshot = await snapshot(start: start, end: end, fallback: fallback)
            snapshots.append(snapshot)
        }

        authorizationStatus = "已同步 \(snapshots.count) 天数据"
        return snapshots
    }

    func addWater(amount: Int, date: Date = Date()) async {
        guard amount > 0,
              HKHealthStore.isHealthDataAvailable(),
              let type = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return }
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: Double(amount))
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try? await healthStore.save(sample)
    }

    private func snapshot(start: Date, end: Date, fallback: DailyHealthSnapshot) async -> DailyHealthSnapshot {
        async let steps = sum(.stepCount, unit: .count(), start: start, end: end)
        async let moveCalories = sum(.activeEnergyBurned, unit: .kilocalorie(), start: start, end: end)
        async let exerciseMinutes = sum(.appleExerciseTime, unit: .minute(), start: start, end: end)
        async let standMinutes = sum(.appleStandTime, unit: .minute(), start: start, end: end)
        async let distance = sum(.distanceWalkingRunning, unit: .meter(), start: start, end: end)
        async let flights = sum(.flightsClimbed, unit: .count(), start: start, end: end)
        async let walkingSpeed = average(.walkingSpeed, unit: HKUnit.meter().unitDivided(by: .second()), start: start, end: end)
        async let stepLength = average(.walkingStepLength, unit: .meter(), start: start, end: end)
        async let doubleSupport = average(.walkingDoubleSupportPercentage, unit: .percent(), start: start, end: end)
        async let asymmetry = average(.walkingAsymmetryPercentage, unit: .percent(), start: start, end: end)
        async let restingHeartRate = average(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: start, end: end)
        async let walkingHeartRateAvg = average(.walkingHeartRateAverage, unit: HKUnit.count().unitDivided(by: .minute()), start: start, end: end)
        async let heartRateAvg = average(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: start, end: end)
        async let heartRateMax = discrete(.heartRate, option: .discreteMax, unit: HKUnit.count().unitDivided(by: .minute()), start: start, end: end)
        async let heartRateMin = discrete(.heartRate, option: .discreteMin, unit: HKUnit.count().unitDivided(by: .minute()), start: start, end: end)
        async let hrv = average(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), start: start, end: end)
        async let cardioFitness = average(.vo2Max, unit: HKUnit(from: "ml/kg*min"), start: start, end: end)
        async let oxygen = average(.oxygenSaturation, unit: .percent(), start: start, end: end)
        async let respiratory = average(.respiratoryRate, unit: HKUnit.count().unitDivided(by: .minute()), start: start, end: end)
        async let wristTemperature = average(.appleSleepingWristTemperature, unit: .degreeCelsius(), start: start, end: end)
        async let noise = average(.environmentalAudioExposure, unit: HKUnit.decibelAWeightedSoundPressureLevel(), start: start, end: end)
        async let daylight = sum(.timeInDaylight, unit: .minute(), start: start, end: end)
        async let headphone = average(.headphoneAudioExposure, unit: HKUnit.decibelAWeightedSoundPressureLevel(), start: start, end: end)
        async let water = sum(.dietaryWater, unit: .literUnit(with: .milli), start: start, end: end)
        async let sleep = sleepSegments(start: start, end: end)

        let resolvedSteps = await Int(steps ?? Double(fallback.steps))
        let resolvedMove = await moveCalories ?? fallback.moveCalories
        let resolvedExercise = await exerciseMinutes ?? fallback.exerciseMinutes
        let resolvedStand = await Int(((standMinutes ?? Double(fallback.standHours * 60)) / 60).rounded())
        let resolvedDistance = await ((distance ?? fallback.walkingRunningDistance * 1000) / 1000)
        let resolvedFlights = await Int(flights ?? Double(fallback.flightsClimbed))
        let resolvedWalkingSpeed = await ((walkingSpeed ?? fallback.walkingSpeed / 3.6) * 3.6)
        let resolvedStepLength = await ((stepLength ?? fallback.walkingStepLength / 100) * 100)
        let resolvedDoubleSupport = await ((doubleSupport ?? fallback.walkingDoubleSupportTime / 100) * 100)
        let resolvedAsymmetry = await ((asymmetry ?? fallback.walkingAsymmetry / 100) * 100)
        let resolvedResting = await restingHeartRate ?? fallback.restingHeartRate
        let resolvedWalkingHR = await walkingHeartRateAvg ?? fallback.walkingHeartRateAvg
        let resolvedHRAvg = await heartRateAvg ?? fallback.nightHeartRateAvg
        let resolvedHRMax = await heartRateMax ?? fallback.heartRateMax
        let resolvedHRMin = await heartRateMin ?? fallback.heartRateMin
        let resolvedHRV = await hrv ?? fallback.hrv
        let resolvedVO2 = await cardioFitness ?? fallback.cardioFitness
        let resolvedOxygen = await ((oxygen ?? fallback.oxygenSaturation / 100) * 100)
        let resolvedRespiratory = await respiratory ?? fallback.nightRespiratoryRate
        let resolvedWristTemp = await wristTemperature ?? fallback.nightWristTemperature
        let resolvedNoise = await noise ?? fallback.environmentalNoise
        let resolvedDaylight = await daylight ?? fallback.timeInDaylight
        let resolvedHeadphone = await headphone ?? fallback.headphoneAudioLevel
        let resolvedWater = await Int(water ?? Double(fallback.waterIntake))
        let resolvedSleep = await sleep ?? SleepSegments(fallback: fallback)

        var snapshot = DailyHealthSnapshot(
            day: fallback.day,
            weekday: fallback.weekday,
            isToday: fallback.isToday,
            energyScore: fallback.energyScore,
            moveCalories: resolvedMove,
            moveGoal: fallback.moveGoal,
            exerciseMinutes: resolvedExercise,
            exerciseGoal: fallback.exerciseGoal,
            standHours: resolvedStand,
            standGoal: fallback.standGoal,
            workoutType: fallback.workoutType,
            workoutDuration: fallback.workoutDuration,
            workoutCalories: fallback.workoutCalories,
            workoutDistance: fallback.workoutDistance,
            steps: resolvedSteps,
            walkingRunningDistance: resolvedDistance,
            flightsClimbed: resolvedFlights,
            walkingSpeed: resolvedWalkingSpeed,
            walkingStepLength: resolvedStepLength,
            walkingDoubleSupportTime: resolvedDoubleSupport,
            walkingAsymmetry: resolvedAsymmetry,
            restingHeartRate: resolvedResting,
            walkingHeartRateAvg: resolvedWalkingHR,
            heartRateMax: resolvedHRMax,
            heartRateMin: resolvedHRMin,
            hrv: resolvedHRV,
            cardioFitness: resolvedVO2,
            oxygenSaturation: resolvedOxygen,
            sleepTotal: resolvedSleep.total,
            sleepDeep: resolvedSleep.deep,
            sleepREM: resolvedSleep.rem,
            sleepLight: resolvedSleep.light,
            sleepAwake: resolvedSleep.awake,
            sleepEfficiency: resolvedSleep.efficiency,
            sleepOnset: fallback.sleepOnset,
            sleepScore: resolvedSleep.score,
            nightHeartRateAvg: resolvedHRAvg,
            nightRespiratoryRate: resolvedRespiratory,
            nightWristTemperature: resolvedWristTemp,
            nightOxygenSaturation: resolvedOxygen,
            environmentalNoise: resolvedNoise,
            timeInDaylight: resolvedDaylight,
            headphoneAudioLevel: resolvedHeadphone,
            headphoneAudioExposure: resolvedHeadphone,
            waterIntake: resolvedWater,
            stressLevel: stressLevel(restingHeartRate: resolvedResting, hrv: resolvedHRV, sleepScore: resolvedSleep.score)
        )
        snapshot.energyScore = EnergyCalculator.calculate(snapshot: snapshot)
        return snapshot
    }

    private func fallbackSnapshot(for date: Date, isToday: Bool) -> DailyHealthSnapshot {
        let calendar = Calendar.current
        var snapshot = VitlMockData.snapshots[min(max(calendar.component(.weekday, from: date) - 1, 0), VitlMockData.snapshots.count - 1)]
        snapshot.day = calendar.component(.day, from: date)
        snapshot.weekday = isToday ? "今天" : weekdayString(for: date)
        snapshot.isToday = isToday
        return snapshot
    }

    private func weekdayString(for date: Date) -> String {
        let symbols = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return symbols[Calendar.current.component(.weekday, from: date) - 1]
    }

    private func stressLevel(restingHeartRate: Double, hrv: Double, sleepScore: Int) -> Int {
        let heartPenalty = max(0, restingHeartRate - 58) * 1.1
        let hrvPenalty = max(0, 65 - hrv) * 0.65
        let sleepPenalty = max(0, 88 - Double(sleepScore)) * 0.45
        return Int(min(max(heartPenalty + hrvPenalty + sleepPenalty, 8), 95).rounded())
    }

    private func sum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double? {
        await statistics(identifier, options: .cumulativeSum, unit: unit, start: start, end: end)
    }

    private func average(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double? {
        await statistics(identifier, options: .discreteAverage, unit: unit, start: start, end: end)
    }

    private func discrete(_ identifier: HKQuantityTypeIdentifier, option: HKStatisticsOptions, unit: HKUnit, start: Date, end: Date) async -> Double? {
        await statistics(identifier, options: option, unit: unit, start: start, end: end)
    }

    private func statistics(_ identifier: HKQuantityTypeIdentifier, options: HKStatisticsOptions, unit: HKUnit, start: Date, end: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: options) { _, result, _ in
                let quantity: HKQuantity?
                if options.contains(.cumulativeSum) {
                    quantity = result?.sumQuantity()
                } else if options.contains(.discreteMin) {
                    quantity = result?.minimumQuantity()
                } else if options.contains(.discreteMax) {
                    quantity = result?.maximumQuantity()
                } else {
                    quantity = result?.averageQuantity()
                }
                continuation.resume(returning: quantity?.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }

    private func sleepSegments(start: Date, end: Date) async -> SleepSegments? {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample], samples.isEmpty == false else {
                    continuation.resume(returning: nil)
                    return
                }

                var deep = 0.0
                var rem = 0.0
                var light = 0.0
                var awake = 0.0

                for sample in samples {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600
                    switch sample.value {
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                        deep += duration
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                        rem += duration
                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                         HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                        light += duration
                    case HKCategoryValueSleepAnalysis.awake.rawValue:
                        awake += duration
                    default:
                        break
                    }
                }

                let total = deep + rem + light
                let inBed = total + awake
                guard total > 0 else {
                    continuation.resume(returning: nil)
                    return
                }
                let efficiency = inBed > 0 ? total / inBed * 100 : 0
                let score = Int(min(max((total / 8.0 * 50) + (efficiency / 100 * 35) + (deep / max(total, 0.1) * 15), 0), 100).rounded())
                continuation.resume(returning: SleepSegments(total: total, deep: deep, rem: rem, light: light, awake: awake, efficiency: efficiency, score: score))
            }
            healthStore.execute(query)
        }
    }
}

private struct SleepSegments {
    var total: Double
    var deep: Double
    var rem: Double
    var light: Double
    var awake: Double
    var efficiency: Double
    var score: Int

    init(total: Double, deep: Double, rem: Double, light: Double, awake: Double, efficiency: Double, score: Int) {
        self.total = total
        self.deep = deep
        self.rem = rem
        self.light = light
        self.awake = awake
        self.efficiency = efficiency
        self.score = score
    }

    init(fallback: DailyHealthSnapshot) {
        total = fallback.sleepTotal
        deep = fallback.sleepDeep
        rem = fallback.sleepREM
        light = fallback.sleepLight
        awake = fallback.sleepAwake
        efficiency = fallback.sleepEfficiency
        score = fallback.sleepScore
    }
}
