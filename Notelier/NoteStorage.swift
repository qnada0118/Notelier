//
//  NoteStorage.swift
//  Notelier
//
//  Created by 박규나 on 6/14/25.
//

import Foundation

struct Note: Codable {
    let date: String
    let title: String
    let body: String
    let course: String?
    
    var isFavorite: Bool {
        let favorites = UserDefaults.standard.array(forKey: "favoriteNotes") as? [String] ?? []
        return favorites.contains(date)
    }
}
class NoteStorage {
    static let shared = NoteStorage()
    private let key = "savedNotes"
    private var isInitialized = false

    private init() {}

    func loadAll() -> [Note] {
        // ✅ 초기 메모 삽입 (최초 1회만)
        if !isInitialized {
            insertSampleNotesIfNeeded()
            isInitialized = true
        }

        guard let raw = UserDefaults.standard.dictionary(forKey: key) as? [String: [String: String]] else {
            return []
        }

        return raw.map { (date, dict) in
            Note(
                date: date,
                title: dict["title"] ?? "(제목 없음)",
                body: dict["body"] ?? "",
                course: dict["course"]
            )
        }.sorted(by: { $0.date > $1.date })
    }

    func save(_ note: Note) {
        var savedNotes = UserDefaults.standard.dictionary(forKey: key) as? [String: [String: String]] ?? [:]
        savedNotes[note.date] = [
            "title": note.title,
            "body": note.body,
            "course": note.course ?? ""
        ]
        UserDefaults.standard.set(savedNotes, forKey: key)
    }

    func delete(_ note: Note) {
        var savedNotes = UserDefaults.standard.dictionary(forKey: key) as? [String: [String: String]] ?? [:]
        savedNotes.removeValue(forKey: note.date)
        UserDefaults.standard.set(savedNotes, forKey: key)
    }

    private func insertSampleNotesIfNeeded() {
        var savedNotes = UserDefaults.standard.dictionary(forKey: key) as? [String: [String: String]] ?? [:]

        if savedNotes["2025-06-14 10:00:00"] == nil {
            savedNotes["2025-06-14 10:00:00"] = [
                "title": "운영체제 - 프로세스와 스레드",
                "body": """
    - 프로세스(Process): 실행 중인 프로그램. 독립된 메모리 공간을 가짐.
    - 스레드(Thread): 프로세스 내의 실행 단위. 코드, 데이터, 힙은 공유하고 스택은 독립적.
    - 장점: 스레드는 생성/전환 비용이 적고, 자원 공유가 쉬움.
    - 단점: 동기화가 필수이며, 공유 자원에 대한 접근 충돌 가능성 존재.
    - Context Switching: CPU가 한 프로세스에서 다른 프로세스로 전환하는 과정. 오버헤드 있음.

    💡 실습에서는 pthread 라이브러리를 사용하여 다중 스레드 생성 실습 진행.
    """,
                "course": "운영체제"
            ]
        }

        if savedNotes["2025-06-13 15:30:00"] == nil {
            savedNotes["2025-06-13 15:30:00"] = [
                "title": "컴퓨터 네트워크 - TCP와 UDP 비교",
                "body": """
    - TCP (Transmission Control Protocol)
      • 연결형(3-way handshake), 신뢰성 보장, 흐름제어, 혼잡제어 존재
      • 순서 보장, 재전송 기능
      • 예시: 웹브라우징(HTTP), 이메일(SMTP), 파일전송(FTP)

    - UDP (User Datagram Protocol)
      • 비연결형, 신뢰성 없음, 순서 보장 없음, 오버헤드 적음
      • 빠른 전송이 중요한 실시간 서비스에 사용
      • 예시: 실시간 스트리밍(RTP), 온라인 게임

    📌 시험 대비 포인트: TCP의 흐름제어 vs 혼잡제어 구분할 것!
    """,
                "course": "컴퓨터 네트워크"
            ]
        }

        UserDefaults.standard.set(savedNotes, forKey: key)
    }

}
