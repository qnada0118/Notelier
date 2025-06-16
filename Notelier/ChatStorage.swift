// ChatStorage.swift
// Notelier

import Foundation

struct ChatMessage: Codable {
    let isUser: Bool
    let text: String
}

struct ChatSession: Codable {
    let id: UUID
    let title: String
    let messages: [ChatMessage]
    let date: Date
    let mode: String
}

class ChatStorage {
    static let shared = ChatStorage()

    private let key = "ChatSessions"

    func save(_ sessions: [ChatSession]) {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func load() -> [ChatSession] {
        if let data = UserDefaults.standard.data(forKey: key),
           let sessions = try? JSONDecoder().decode([ChatSession].self, from: data) {
            return sessions
        }
        return []
    }

    func delete(_ session: ChatSession) {
        var sessions = load()
        sessions.removeAll { $0.id == session.id }
        save(sessions)
    }
    
    func saveOrUpdate(_ session: ChatSession) {
        var sessions = load()

        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.insert(session, at: 0)
        }

        save(sessions)
    }
}
