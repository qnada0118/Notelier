//
//  ChatRoom+InputHandling.swift
//  Notelier
//
//  Created by 박규나 on 6/14/25.
//

import UIKit

extension ChatRoomViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == placeholderColor {
            textView.text = ""
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            setupModeBehavior()
        }
    }

    @IBAction func sendTapped(_ sender: UIButton) {
        if isReadOnly {
            let alert = UIAlertController(title: "기록 해제", message: "이 채팅을 이어서 작성할까요?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
                self.isReadOnly = false
                self.setupModeBehavior()
            }))
            present(alert, animated: true)
            return
        }

        guard let text = inputTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty,
              inputTextView.textColor != placeholderColor else { return }

        // ✅ 첨부 노트가 있다면 텍스트 앞에 제목 추가
        var userMessageText = text
        if let note = attachedNote {
            userMessageText = "📎 \(note.title)\n" + text
        }

        addMessage(ChatMessage(isUser: true, text: userMessageText))
        inputTextView.text = ""
        inputTextView.resignFirstResponder()
        textViewDidEndEditing(inputTextView)

        var gptMessages = self.messages

        if let note = attachedNote {
            let noteContext = ChatMessage(
                isUser: true,
                text: "📌 참고 노트:\n\(note.title)\n\(note.body)"
            )
            gptMessages.insert(noteContext, at: 0)
        }

        OpenAI.shared.send(messages: gptMessages, mode: self.mode) { reply in
            DispatchQueue.main.async {
                let answer = reply ?? "응답을 불러오지 못했어요."
                self.addMessage(ChatMessage(isUser: false, text: answer))

                OpenAI.shared.generateAutoTitle(from: self.messages, mode: self.mode) { title in
                    DispatchQueue.main.async {
                        let trimmed = String(title.prefix(20))
                        self.navigationItem.title = trimmed
                        (self.navigationItem.titleView as? UIButton)?.setTitle(trimmed, for: .normal)

                        self.attachedNote = nil
                        self.updateAttachedNoteView()
                        self.saveOrUpdateSession()
                    }
                }
            }
        }
    }


    func addMessage(_ message: ChatMessage) {
        messages.append(message)
        saveOrUpdateSession()
        tableView.reloadData()
        scrollToBottom()
    }

    func scrollToBottom() {
        if messages.count > 0 {
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    func saveOrUpdateSession() {
        let currentTitle = (navigationItem.titleView as? UIButton)?.title(for: .normal) ?? generateTitleFromMode()
        let session = ChatSession(
            id: sessionId,
            title: currentTitle,
            messages: self.messages,
            date: Date(),
            mode: self.mode // ✅ mode 포함
        )
        ChatStorage.shared.saveOrUpdate(session)
    }

}
