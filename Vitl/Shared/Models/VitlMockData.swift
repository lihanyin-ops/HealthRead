import Foundation
import SwiftUI

enum VitlMockData {
    static let snapshots: [DailyHealthSnapshot] = [
        .init(day: 2, weekday: "周一", energyScore: 42, moveCalories: 210, exerciseMinutes: 12, standHours: 7, workoutType: "", workoutDuration: 0, workoutCalories: 0, workoutDistance: 0, steps: 4200, walkingRunningDistance: 3.1, flightsClimbed: 4, walkingSpeed: 4.8, walkingStepLength: 72, walkingDoubleSupportTime: 26.4, walkingAsymmetry: 3.2, restingHeartRate: 76, walkingHeartRateAvg: 95, heartRateMax: 112, heartRateMin: 55, hrv: 38, cardioFitness: 38.2, oxygenSaturation: 97, sleepTotal: 5.5, sleepDeep: 0.8, sleepREM: 1.0, sleepLight: 3.4, sleepAwake: 0.3, sleepEfficiency: 78, sleepOnset: 28, sleepScore: 62, nightHeartRateAvg: 68, nightRespiratoryRate: 17, nightWristTemperature: -0.3, nightOxygenSaturation: 96, environmentalNoise: 72, timeInDaylight: 18, headphoneAudioLevel: 74, headphoneAudioExposure: 71, waterIntake: 800, stressLevel: 72),
        .init(day: 3, weekday: "周二", energyScore: 78, moveCalories: 520, exerciseMinutes: 45, standHours: 11, workoutType: "跑步", workoutDuration: 38, workoutCalories: 380, workoutDistance: 5.2, steps: 9800, walkingRunningDistance: 7.2, flightsClimbed: 12, walkingSpeed: 5.4, walkingStepLength: 76, walkingDoubleSupportTime: 24.8, walkingAsymmetry: 2.1, restingHeartRate: 66, walkingHeartRateAvg: 88, heartRateMax: 158, heartRateMin: 52, hrv: 55, cardioFitness: 42.1, oxygenSaturation: 98, sleepTotal: 7.5, sleepDeep: 1.5, sleepREM: 1.8, sleepLight: 3.8, sleepAwake: 0.4, sleepEfficiency: 88, sleepOnset: 14, sleepScore: 84, nightHeartRateAvg: 58, nightRespiratoryRate: 14, nightWristTemperature: 0.1, nightOxygenSaturation: 98, environmentalNoise: 58, timeInDaylight: 42, headphoneAudioLevel: 68, headphoneAudioExposure: 69, waterIntake: 1800, stressLevel: 28),
        .init(day: 4, weekday: "周三", energyScore: 91, moveCalories: 680, exerciseMinutes: 62, standHours: 13, workoutType: "力量训练", workoutDuration: 55, workoutCalories: 420, workoutDistance: 0, steps: 12400, walkingRunningDistance: 9.1, flightsClimbed: 18, walkingSpeed: 5.8, walkingStepLength: 78, walkingDoubleSupportTime: 23.6, walkingAsymmetry: 1.8, restingHeartRate: 63, walkingHeartRateAvg: 84, heartRateMax: 172, heartRateMin: 50, hrv: 62, cardioFitness: 44.5, oxygenSaturation: 99, sleepTotal: 8.2, sleepDeep: 2.0, sleepREM: 2.1, sleepLight: 3.7, sleepAwake: 0.4, sleepEfficiency: 93, sleepOnset: 8, sleepScore: 95, nightHeartRateAvg: 54, nightRespiratoryRate: 13, nightWristTemperature: 0.2, nightOxygenSaturation: 99, environmentalNoise: 52, timeInDaylight: 68, headphoneAudioLevel: 62, headphoneAudioExposure: 65, waterIntake: 2200, stressLevel: 18),
        .init(day: 5, weekday: "周四", energyScore: 65, moveCalories: 310, exerciseMinutes: 28, standHours: 9, workoutType: "步行", workoutDuration: 25, workoutCalories: 120, workoutDistance: 2.1, steps: 7200, walkingRunningDistance: 5.3, flightsClimbed: 8, walkingSpeed: 5.1, walkingStepLength: 74, walkingDoubleSupportTime: 25.2, walkingAsymmetry: 2.5, restingHeartRate: 70, walkingHeartRateAvg: 91, heartRateMax: 128, heartRateMin: 54, hrv: 48, cardioFitness: 41.8, oxygenSaturation: 98, sleepTotal: 7.0, sleepDeep: 1.2, sleepREM: 1.5, sleepLight: 3.9, sleepAwake: 0.4, sleepEfficiency: 85, sleepOnset: 18, sleepScore: 78, nightHeartRateAvg: 62, nightRespiratoryRate: 15, nightWristTemperature: -0.1, nightOxygenSaturation: 97, environmentalNoise: 64, timeInDaylight: 35, headphoneAudioLevel: 71, headphoneAudioExposure: 70, waterIntake: 1200, stressLevel: 45),
        .init(day: 6, weekday: "周五", energyScore: 88, moveCalories: 620, exerciseMinutes: 55, standHours: 12, workoutType: "骑行", workoutDuration: 48, workoutCalories: 510, workoutDistance: 18.4, steps: 11000, walkingRunningDistance: 8.1, flightsClimbed: 15, walkingSpeed: 5.6, walkingStepLength: 77, walkingDoubleSupportTime: 24.2, walkingAsymmetry: 2.0, restingHeartRate: 64, walkingHeartRateAvg: 86, heartRateMax: 165, heartRateMin: 51, hrv: 58, cardioFitness: 43.8, oxygenSaturation: 99, sleepTotal: 8.0, sleepDeep: 1.8, sleepREM: 2.0, sleepLight: 3.8, sleepAwake: 0.4, sleepEfficiency: 91, sleepOnset: 11, sleepScore: 92, nightHeartRateAvg: 56, nightRespiratoryRate: 13, nightWristTemperature: 0.0, nightOxygenSaturation: 98, environmentalNoise: 55, timeInDaylight: 58, headphoneAudioLevel: 65, headphoneAudioExposure: 67, waterIntake: 2000, stressLevel: 22),
        .init(day: 7, weekday: "周六", energyScore: 73, moveCalories: 420, exerciseMinutes: 38, standHours: 10, workoutType: "瑜伽", workoutDuration: 40, workoutCalories: 180, workoutDistance: 0, steps: 8500, walkingRunningDistance: 6.2, flightsClimbed: 10, walkingSpeed: 5.3, walkingStepLength: 75, walkingDoubleSupportTime: 24.9, walkingAsymmetry: 2.3, restingHeartRate: 68, walkingHeartRateAvg: 89, heartRateMax: 145, heartRateMin: 53, hrv: 51, cardioFitness: 42.5, oxygenSaturation: 98, sleepTotal: 7.2, sleepDeep: 1.4, sleepREM: 1.7, sleepLight: 3.7, sleepAwake: 0.4, sleepEfficiency: 87, sleepOnset: 15, sleepScore: 82, nightHeartRateAvg: 60, nightRespiratoryRate: 14, nightWristTemperature: -0.1, nightOxygenSaturation: 97, environmentalNoise: 61, timeInDaylight: 44, headphoneAudioLevel: 68, headphoneAudioExposure: 68, waterIntake: 1500, stressLevel: 35),
        .init(day: 8, weekday: "今天", isToday: true, energyScore: 72, moveCalories: 456, exerciseMinutes: 35, standHours: 10, workoutType: "跑步", workoutDuration: 30, workoutCalories: 310, workoutDistance: 4.8, steps: 8234, walkingRunningDistance: 6.0, flightsClimbed: 9, walkingSpeed: 5.2, walkingStepLength: 75, walkingDoubleSupportTime: 25.0, walkingAsymmetry: 2.2, restingHeartRate: 69, walkingHeartRateAvg: 90, heartRateMax: 148, heartRateMin: 53, hrv: 52, cardioFitness: 42.0, oxygenSaturation: 98, sleepTotal: 7.5, sleepDeep: 1.5, sleepREM: 1.8, sleepLight: 3.8, sleepAwake: 0.4, sleepEfficiency: 88, sleepOnset: 13, sleepScore: 85, nightHeartRateAvg: 59, nightRespiratoryRate: 14, nightWristTemperature: 0.0, nightOxygenSaturation: 98, environmentalNoise: 63, timeInDaylight: 40, headphoneAudioLevel: 70, headphoneAudioExposure: 69, waterIntake: 1500, stressLevel: 35)
    ]

    static var today: DailyHealthSnapshot { snapshots.last! }
}

struct MetricItem: Identifiable {
    let id: String
    let label: String
    let unit: String
    let max: Double
    let color: Color
    let value: (DailyHealthSnapshot) -> Double
    let insight: String?
}

struct MetricGroup: Identifiable {
    let id: String
    let label: String
    let icon: String
    let color: Color
    let metrics: [MetricItem]
}

enum VitlMetricCatalog {
    static let groups: [MetricGroup] = [
        .init(id: "rings", label: "活动圆环", icon: "circle.hexagongrid.fill", color: .vitlRed, metrics: [
            .init(id: "move", label: "消耗（Move）", unit: "千卡", max: 800, color: .vitlRed, value: { $0.moveCalories }, insight: "今日活动消耗456千卡，完成目标的91%。傍晚再步行15分钟即可完全闭合 Move 环。"),
            .init(id: "exercise", label: "锻炼（Exercise）", unit: "分钟", max: 60, color: .green, value: { $0.exerciseMinutes }, insight: "锻炼35分钟，超过WHO推荐的每日30分钟标准，Exercise环已闭合。"),
            .init(id: "stand", label: "站立（Stand）", unit: "小时", max: 12, color: .cyan, value: { Double($0.standHours) }, insight: nil)
        ]),
        .init(id: "steps", label: "步数与距离", icon: "figure.walk", color: .vitlGreen, metrics: [
            .init(id: "steps", label: "步数", unit: "步", max: 12000, color: .vitlGreen, value: { Double($0.steps) }, insight: "今日步数8,234步，完成目标的82%。你的步行节奏均匀，提示心肺状态良好。"),
            .init(id: "distance", label: "步行+跑步距离", unit: "km", max: 12, color: .green, value: { $0.walkingRunningDistance }, insight: nil),
            .init(id: "flights", label: "爬楼层数", unit: "层", max: 20, color: .vitlOrange, value: { Double($0.flightsClimbed) }, insight: nil)
        ]),
        .init(id: "heart", label: "心率", icon: "heart.fill", color: .vitlRed, metrics: [
            .init(id: "resting", label: "静息心率", unit: "BPM", max: 100, color: .vitlRed, value: { $0.restingHeartRate }, insight: "静息心率69 BPM，处于正常范围。与上周相比下降2 BPM，提示有氧能力在缓慢提升。"),
            .init(id: "hrv", label: "心率变异性（HRV）", unit: "ms", max: 80, color: .pink, value: { $0.hrv }, insight: "HRV 52ms处于你个人基线附近，提示自主神经系统恢复状态良好。"),
            .init(id: "vo2", label: "心肺健康（VO₂ max）", unit: "mL/kg/min", max: 60, color: .red, value: { $0.cardioFitness }, insight: "VO₂ max 42.0 mL/kg/min，处于同龄人群的良好水平。")
        ]),
        .init(id: "sleep", label: "睡眠", icon: "moon.fill", color: .vitlPurple, metrics: [
            .init(id: "score", label: "睡眠评分", unit: "分", max: 100, color: .vitlPurple, value: { Double($0.sleepScore) }, insight: "今晚睡眠评分85分，属于良好水平。睡眠结构均衡，深睡和REM比例达标。"),
            .init(id: "total", label: "总睡眠时长", unit: "小时", max: 10, color: .purple, value: { $0.sleepTotal }, insight: "总睡眠7.5小时，达到成人推荐的7-9小时标准。"),
            .init(id: "efficiency", label: "睡眠效率", unit: "%", max: 100, color: .indigo, value: { $0.sleepEfficiency }, insight: nil)
        ]),
        .init(id: "oxygen", label: "血氧", icon: "lungs.fill", color: .vitlTeal, metrics: [
            .init(id: "oxygen", label: "血氧饱和度", unit: "%", max: 100, color: .vitlTeal, value: { $0.oxygenSaturation }, insight: "血氧98%，处于正常范围，提示肺功能和循环系统运作正常。")
        ]),
        .init(id: "environment", label: "环境与音频", icon: "leaf.fill", color: .mint, metrics: [
            .init(id: "noise", label: "环境噪声", unit: "dB(A)", max: 90, color: .mint, value: { $0.environmentalNoise }, insight: nil),
            .init(id: "daylight", label: "日照时间", unit: "分钟", max: 90, color: .yellow, value: { $0.timeInDaylight }, insight: nil),
            .init(id: "audio", label: "耳机音量", unit: "dB(A)", max: 90, color: .orange, value: { $0.headphoneAudioLevel }, insight: nil)
        ])
    ]
}
