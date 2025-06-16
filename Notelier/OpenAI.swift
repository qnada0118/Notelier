//  OpenAI.swift
//  Notelier

import Foundation

class OpenAI {
    static let shared = OpenAI()
    private let apiKey = Bundle.main.infoDictionary?["OpenAI_API_Key"] as? String ?? ""
    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!

    private let session = URLSession.shared

    // MARK: - GPT 기본 요청
    private func requestChat(messages: [[String: String]], temperature: Double = 0.7, completion: @escaping (String?) -> Void) {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messages,
            "temperature": temperature
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 요청 에러:", error.localizedDescription)
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("📡 상태 코드:", httpResponse.statusCode)
            }

            guard let data = data else {
                completion(nil)
                return
            }

            if let responseString = String(data: data, encoding: .utf8) {
                print("📨 응답 원본:\n\(responseString)")
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
            } else {
                print("⚠️ 응답 파싱 실패")
                completion(nil)
            }
        }.resume()
    }

    // MARK: - 💬 일반 대화 전송
    func send(messages: [ChatMessage], mode: String, completion: @escaping (String?) -> Void) {
        let systemPrompt = """
        너는 대학생의 필기 노트를 요약하거나, 이해를 돕는 퀴즈를 생성해주는 학습 도우미야. \
        사용자의 요청에 맞춰 요약, 퀴즈 생성, 질문 응답을 수행해줘.
        """
        let systemMessage: [String: String] = ["role": "system", "content": systemPrompt]

        let chatMessages = messages.map {
            ["role": $0.isUser ? "user" : "assistant", "content": $0.text]
        }

        requestChat(messages: [systemMessage] + chatMessages, completion: completion)
    }

    // MARK: - 🧠 대화 목적 감지 (요약 / 질문 / 퀴즈)
    func detectPurpose(from messages: [ChatMessage], completion: @escaping (String) -> Void) {
        let systemPrompt = """
        다음은 사용자와 AI의 대화야. 이 대화의 목적이 '요약', '질문', '퀴즈' 중 무엇인지 한 단어로만 정확히 말해줘.
        다른 설명 없이 한 단어만 반환해.
        """

        let chatMessages = messages.suffix(4).map {
            ["role": $0.isUser ? "user" : "assistant", "content": $0.text]
        }

        requestChat(messages: [["role": "system", "content": systemPrompt]] + chatMessages) { result in
            let normalized = (result ?? "").lowercased()
            if normalized.contains("요약") {
                completion("요약")
            } else if normalized.contains("퀴즈") {
                completion("퀴즈")
            } else {
                completion("질문")
            }
        }
    }


    // MARK: - 📝 자동 제목 생성
    func generateAutoTitle(from messages: [ChatMessage], mode: String, completion: @escaping (String) -> Void) {
        let recentMessages = messages.suffix(4)
        let systemMessage: [String: String] = [
            "role": "system",
            "content": "다음은 사용자와 AI의 대화야. 이 대화의 흐름을 반영한 제목을 지어야 해. 과목명을 추측해서 말해줘. 단, 목적(요약/질문/퀴즈)은 따로 처리하므로 언급하지 마.그리고 부제목 같은건 필요없어. 최대한 단순하게 과목명만 담아줘"
        ]

        let chatMessages = recentMessages.map {
            ["role": $0.isUser ? "user" : "assistant", "content": $0.text]
        }

        requestChat(messages: [systemMessage] + chatMessages, temperature: 0.5) { result in
            let baseTitle = result?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "새로운 대화"
            let lowercasedTitle = baseTitle.lowercased()

            let alreadyContainsMode = ["요약", "질문", "퀴즈"].contains { lowercasedTitle.hasSuffix($0) }

            let finalTitle = alreadyContainsMode ? baseTitle : "\(baseTitle) \(mode)"
            completion(finalTitle)
        }
    }

}
