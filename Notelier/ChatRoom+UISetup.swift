//
//  ChatRoom+UISetup.swift
//  Notelier
//
//  Created by 박규나 on 6/14/25.
//

import UIKit

extension ChatRoomViewController {
    func setupInputTextView() {
        inputTextView.layer.cornerRadius = 8
        inputTextView.delegate = self
    }

    func setupModeBehavior() {
        inputTextView.textColor = placeholderColor
        sendButton.setTitle("", for: .normal)

        if isReadOnly {
            inputTextView.text = "기록 보기 모드입니다"
            inputTextView.isEditable = false
            attachButton.isHidden = true
            sendButton.setImage(UIImage(systemName: "lock"), for: .normal)
            sendButton.setImage(nil, for: .highlighted)
        } else {
            inputTextView.text = "내용을 입력하세요"
            inputTextView.isEditable = true
            attachButton.isHidden = false
            sendButton.setImage(UIImage(systemName: "paperplane"), for: .normal)
        }

        sendButton.isEnabled = true
        sendButton.isHidden = false
    }

    func generateTitleFromMode() -> String {
        return isReadOnly ? "📂 기록 열람" : "💬 새로운 대화"
    }

    func setupTitleEditable() {
        let titleButton = UIButton(type: .system)
        titleButton.setTitle(navigationItem.title, for: .normal)
        titleButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        titleButton.addTarget(self, action: #selector(editTitleTapped), for: .touchUpInside)
        navigationItem.titleView = titleButton
    }

    @objc func editTitleTapped() {
        let alert = UIAlertController(title: "제목 수정", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.text = self.navigationItem.title }

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "저장", style: .default, handler: { _ in
            if let newTitle = alert.textFields?.first?.text, !newTitle.isEmpty {
                self.navigationItem.title = newTitle
                (self.navigationItem.titleView as? UIButton)?.setTitle(newTitle, for: .normal)
                self.saveOrUpdateSession()
            }
        }))

        present(alert, animated: true)
    }
}
