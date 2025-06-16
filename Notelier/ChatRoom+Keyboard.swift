//
//  ChatRoom+Keyboard.swift
//  Notelier
//
//  Created by 박규나 on 6/14/25.
//

import UIKit

extension ChatRoomViewController {
    func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        print("🧠 키보드 올림 감지됨!")

        
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
           let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {

            let adjustment = keyboardFrame.height - view.safeAreaInsets.bottom
            print("🧪 bottomConstraint:", self.bottomConstraint)
            print("🧪 tableView:", self.tableView)
            print("🧪 view:", self.view)
            UIView.animate(withDuration: duration) {
                self.bottomConstraint.constant = adjustment

                self.tableView.contentInset.bottom = adjustment
                self.tableView.verticalScrollIndicatorInsets.bottom = adjustment

                self.view.layoutIfNeeded()

                if self.messages.count > 0 {
                    let lastIndex = IndexPath(row: self.messages.count - 1, section: 0)
                    self.tableView.scrollToRow(at: lastIndex, at: .bottom, animated: true)
                }
            }
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        if let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval {
            UIView.animate(withDuration: duration) {
                self.bottomConstraint.constant = 0
                self.tableView.contentInset.bottom = 0
                self.tableView.verticalScrollIndicatorInsets.bottom = 0
                self.view.layoutIfNeeded()
            }
        }
    }


    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
