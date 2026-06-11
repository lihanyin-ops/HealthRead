import Foundation
import Security

enum AIConfiguration {
    static let apiKeyDefaultsKey = "vitl.ai.apiKey"
    static let endpointDefaultsKey = "vitl.ai.endpoint"
    static let modelDefaultsKey = "vitl.ai.model"
    static let defaultEndpoint = "http://sub2api.10m.com.cn/v1/chat/completions"
    static let defaultModel = "qwen-plus-latest"

    static var apiKey: String? {
        if let keychainKey = AIKeychain.load(), keychainKey.isEmpty == false {
            return keychainKey
        }

        let defaultsKey = UserDefaults.standard.string(forKey: apiKeyDefaultsKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let defaultsKey, defaultsKey.isEmpty == false {
            return defaultsKey
        }

        let bundledKey = (Bundle.main.object(forInfoDictionaryKey: "VitlAIAPIKey") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let bundledKey, bundledKey.isEmpty == false, bundledKey.hasPrefix("$(") == false {
            return bundledKey
        }

        let envKey = ProcessInfo.processInfo.environment["VITL_AI_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        return envKey?.isEmpty == false ? envKey : nil
    }

    static var endpoint: URL {
        let value = UserDefaults.standard.string(forKey: endpointDefaultsKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return URL(string: value?.isEmpty == false ? value! : defaultEndpoint) ?? URL(string: defaultEndpoint)!
    }

    static var model: String {
        let value = UserDefaults.standard.string(forKey: modelDefaultsKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return value?.isEmpty == false ? value! : defaultModel
    }
}

enum AIKeychain {
    private static let service = "com.vitl.prototype.ai"
    private static let account = "apiKey"

    static func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(_ value: String) {
        delete()
        guard value.isEmpty == false, let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum PromptBuilder {
    static func buildSummary(from snapshot: DailyHealthSnapshot, history: [DailyHealthSnapshot], age: Int, height: Double, weight: Double) -> String {
        let recent = history.map { item in
            "\(item.weekday)：能量\(item.energyScore)，睡眠\(String(format: "%.1f", item.sleepTotal))h，HRV \(Int(item.hrv))ms，静息心率\(Int(item.restingHeartRate))BPM，步数\(item.steps)，饮水\(item.waterIntake)mL，压力\(item.stressLevel)"
        }.joined(separator: "\n")

        return """
        你是 Vitl 的健康分析助手，请基于 Apple Health 风格数据生成中文分析。语气专业、温和、可执行，不做医疗诊断，不夸大风险。

        用户基础锚点：\(age)岁，\(Int(height))cm，\(Int(weight))kg。
        今日摘要：能量\(snapshot.energyScore)，睡眠\(snapshot.sleepTotal)小时，HRV \(snapshot.hrv)ms，静息心率\(snapshot.restingHeartRate)BPM，步数\(snapshot.steps)，饮水\(snapshot.waterIntake)mL。
        近7日趋势：
        \(recent)

        请严格只输出 JSON，不要 Markdown，不要代码块，不要额外解释。JSON 结构如下：
        {
          "statusTitle": "8个字以内的状态标题",
          "coreInsight": "围绕睡眠、HRV、静息心率、活动恢复写一段核心洞察",
          "actionableAdvice": "用①②③给出三条今天可执行建议",
          "deepTrend": "基于近7天数据写一段深度趋势分析"
        }
        """
    }
}

final class AIService {
    static let shared = AIService()

    func summarize(snapshot: DailyHealthSnapshot, history: [DailyHealthSnapshot] = VitlMockData.snapshots, age: Int, height: Double, weight: Double) async throws -> AIHealthSummary {
        let content = try await completionContent(
            messages: [
                ChatMessage(role: "system", content: "你是 Vitl 的中文健康分析助手，只输出用户要求的 JSON。"),
                ChatMessage(role: "user", content: PromptBuilder.buildSummary(from: snapshot, history: history, age: age, height: height, weight: weight))
            ],
            maxTokens: 700
        )
        return try parseSummary(from: content)
    }

    func analyzeMetric(label: String, value: String, snapshot: DailyHealthSnapshot, history: [DailyHealthSnapshot]) async throws -> String {
        let historyText = history.map { "\($0.weekday)：能量\($0.energyScore)，睡眠\(String(format: "%.1f", $0.sleepTotal))h，HRV \(Int($0.hrv))，静息心率\(Int($0.restingHeartRate))，步数\($0.steps)" }.joined(separator: "\n")
        let prompt = """
        请用中文为健康指标「\(label)」生成一段 80 字以内的个性化分析。
        当前值：\(value)
        今日关键数据：能量\(snapshot.energyScore)，睡眠\(String(format: "%.1f", snapshot.sleepTotal))h，HRV \(Int(snapshot.hrv))ms，静息心率\(Int(snapshot.restingHeartRate))BPM。
        近7日：
        \(historyText)
        要求：专业、温和、可执行，不做医疗诊断，只输出正文。
        """
        return try await completionContent(
            messages: [
                ChatMessage(role: "system", content: "你是 Vitl 的中文健康分析助手。"),
                ChatMessage(role: "user", content: prompt)
            ],
            maxTokens: 220
        ).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func analyzeJourney(history: [DailyHealthSnapshot]) async throws -> String {
        let historyText = history.map { "\($0.weekday)：能量\($0.energyScore)，睡眠\(String(format: "%.1f", $0.sleepTotal))h，步数\($0.steps)，消耗\(Int($0.moveCalories))kcal，HRV \(Int($0.hrv))，压力\($0.stressLevel)" }.joined(separator: "\n")
        let prompt = """
        请基于 Vitl 近7天健康数据，生成一段 120 字以内的趋势洞察。
        \(historyText)
        要求：指出趋势、关键驱动因素、下周一个具体建议。不做医疗诊断，只输出正文。
        """
        return try await completionContent(
            messages: [
                ChatMessage(role: "system", content: "你是 Vitl 的中文健康趋势分析助手。"),
                ChatMessage(role: "user", content: prompt)
            ],
            maxTokens: 300
        ).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func completionContent(messages: [ChatMessage], maxTokens: Int) async throws -> String {
        guard let apiKey = AIConfiguration.apiKey else {
            throw AIServiceError.missingAPIKey
        }

        let requestBody = ChatCompletionRequest(
            model: AIConfiguration.model,
            messages: messages,
            maxTokens: maxTokens,
            temperature: 0.7
        )

        var request = URLRequest(url: AIConfiguration.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            let message = String(data: data, encoding: .utf8)
            throw AIServiceError.httpError(httpResponse.statusCode, message)
        }

        let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = completion.choices.first?.message.content else {
            throw AIServiceError.emptyContent
        }

        return content
    }

    private func parseSummary(from content: String) throws -> AIHealthSummary {
        let trimmed = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = trimmed.data(using: .utf8) else {
            throw AIServiceError.emptyContent
        }

        do {
            return try JSONDecoder().decode(AIHealthSummary.self, from: data)
        } catch {
            throw AIServiceError.decodingFailed(trimmed)
        }
    }
}

enum AIServiceError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case httpError(Int, String?)
    case emptyContent
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "请先在设置中配置 AI API Key"
        case .invalidResponse:
            return "AI 服务响应无效"
        case .httpError(let statusCode, let message):
            if let message, message.isEmpty == false {
                return "AI 服务请求失败（\(statusCode)）：\(message)"
            }
            return "AI 服务请求失败（\(statusCode)）"
        case .emptyContent:
            return "AI 服务没有返回分析内容"
        case .decodingFailed:
            return "AI 返回内容格式不符合预期"
        }
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let maxTokens: Int
    let temperature: Double

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
        case temperature
    }
}

private struct ChatMessage: Codable {
    let role: String
    let content: String
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: ChatMessage
    }
}
