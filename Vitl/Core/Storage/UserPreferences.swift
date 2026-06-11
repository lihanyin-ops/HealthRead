import Foundation
import SwiftUI
import WatchConnectivity

@MainActor
final class UserPreferences: ObservableObject {
    @AppStorage("user.weight") var weight: Double = 68
    @AppStorage("user.height") var height: Double = 175
    @AppStorage("user.age") var age: Int = 28
    @AppStorage("user.gender") var gender: String = "male"
    @AppStorage("user.avatar") var avatarRawValue: String = AvatarType.man.rawValue
    @AppStorage("user.waterGoal") var waterGoal: Int = 2000

    var avatarType: AvatarType {
        get { AvatarType(rawValue: avatarRawValue) ?? .man }
        set { avatarRawValue = newValue.rawValue }
    }
}

struct HRZone: Codable, Identifiable, Equatable {
    var id: Int
    var label: String
    var min: Int
    var max: Int

    static let defaults: [HRZone] = [
        .init(id: 1, label: "热身", min: 50, max: 60),
        .init(id: 2, label: "燃脂", min: 60, max: 70),
        .init(id: 3, label: "有氧", min: 70, max: 80),
        .init(id: 4, label: "无氧", min: 80, max: 90),
        .init(id: 5, label: "极限", min: 90, max: 100)
    ]
}

struct VitlPersistedState: Codable {
    var snapshots: [DailyHealthSnapshot]
    var aiSummary: AIHealthSummary?
    var metricInsights: [String: String]
    var journeyInsight: String?
    var hrZones: [HRZone]
    var updatedAt: Date

    static var initial: VitlPersistedState {
        VitlPersistedState(
            snapshots: VitlMockData.snapshots,
            aiSummary: nil,
            metricInsights: [:],
            journeyInsight: nil,
            hrZones: HRZone.defaults,
            updatedAt: Date()
        )
    }
}

@MainActor
final class AppStateStore: ObservableObject {
    @Published private(set) var state: VitlPersistedState

    private let defaultsKey = "vitl.persisted.state.v1"
    private var syncManager: WatchSyncManager?

    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder.vitl.decode(VitlPersistedState.self, from: data) {
            state = decoded
        } else {
            state = .initial
            persist(shouldSync: false)
        }
    }

    func attachSyncManager(_ manager: WatchSyncManager = .shared) {
        syncManager = manager
        manager.configure(store: self)
    }

    var snapshots: [DailyHealthSnapshot] {
        state.snapshots
    }

    var today: DailyHealthSnapshot {
        state.snapshots.last ?? VitlMockData.today
    }

    func snapshot(for day: Int) -> DailyHealthSnapshot {
        state.snapshots.first { $0.day == day } ?? today
    }

    func replaceSnapshots(_ snapshots: [DailyHealthSnapshot]) {
        guard snapshots.isEmpty == false else { return }
        state.snapshots = snapshots
        state.updatedAt = Date()
        persist()
    }

    func updateToday(_ snapshot: DailyHealthSnapshot) {
        upsert(snapshot)
    }

    func addWater(amount: Int, day: Int) {
        guard amount > 0 else { return }
        var snapshot = self.snapshot(for: day)
        snapshot.waterIntake += amount
        upsert(snapshot)
    }

    func setAISummary(_ summary: AIHealthSummary) {
        state.aiSummary = summary
        state.updatedAt = Date()
        persist()
    }

    func setMetricInsight(_ insight: String, for key: String) {
        state.metricInsights[key] = insight
        state.updatedAt = Date()
        persist()
    }

    func setJourneyInsight(_ insight: String) {
        state.journeyInsight = insight
        state.updatedAt = Date()
        persist()
    }

    func updateHRZone(_ zone: HRZone) {
        if let index = state.hrZones.firstIndex(where: { $0.id == zone.id }) {
            state.hrZones[index] = zone
        } else {
            state.hrZones.append(zone)
            state.hrZones.sort { $0.id < $1.id }
        }
        state.updatedAt = Date()
        persist()
    }

    func applyIncomingState(_ incoming: VitlPersistedState) {
        if incoming.updatedAt > state.updatedAt {
            state = incoming
            persist(shouldSync: false)
        } else {
            syncManager?.send(state)
        }
    }

    private func upsert(_ snapshot: DailyHealthSnapshot) {
        if let index = state.snapshots.firstIndex(where: { $0.day == snapshot.day }) {
            state.snapshots[index] = snapshot
        } else {
            state.snapshots.append(snapshot)
            state.snapshots.sort { $0.day < $1.day }
        }
        state.updatedAt = Date()
        persist()
    }

    private func persist(shouldSync: Bool = true) {
        if let data = try? JSONEncoder.vitl.encode(state) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
        if shouldSync {
            syncManager?.send(state)
        }
    }
}

final class WatchSyncManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSyncManager()

    private weak var store: AppStateStore?
    private let payloadKey = "vitlState"

    func configure(store: AppStateStore) {
        self.store = store
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        Task { @MainActor in send(store.state) }
    }

    func send(_ state: VitlPersistedState) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated,
              let data = try? JSONEncoder.vitl.encode(state) else { return }

        let payload = [payloadKey: data]
        #if os(iOS)
        if WCSession.default.isWatchAppInstalled {
            try? WCSession.default.updateApplicationContext(payload)
            if WCSession.default.isReachable {
                WCSession.default.sendMessageData(data, replyHandler: nil)
            }
        }
        #else
        try? WCSession.default.updateApplicationContext(payload)
        if WCSession.default.isReachable {
            WCSession.default.sendMessageData(data, replyHandler: nil)
        }
        #endif
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        applyPayload(applicationContext[payloadKey] as? Data)
    }

    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        applyPayload(messageData)
    }

    private nonisolated func applyPayload(_ data: Data?) {
        guard let data,
              let incoming = try? JSONDecoder.vitl.decode(VitlPersistedState.self, from: data) else { return }
        Task { @MainActor in
            self.store?.applyIncomingState(incoming)
        }
    }
}

extension JSONEncoder {
    static var vitl: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var vitl: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
