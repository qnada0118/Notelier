//
//  NewNoteViewController.swift
//  Notelier
//
//  Created by 박규나 on 6/6/25.
//

import UIKit

class NewNoteViewController: UIViewController {

    var receivedText: String?
    var selectedCourse: String?

    @IBOutlet weak var memoTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTitleButton()

        memoTextView.font = UIFont.systemFont(ofSize: 12)
        memoTextView.text = ""
        memoTextView.backgroundColor = .systemBackground
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "저장",
            style: .done,
            target: self,
            action: #selector(saveMemo)
        )
    }

    func setupTitleButton() {
        let titleButton = UIButton(type: .system)
        titleButton.setTitle(receivedText ?? "제목 없음", for: .normal)
        titleButton.setTitleColor(.label, for: .normal) // 또는 .black
        titleButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        titleButton.addTarget(self, action: #selector(presentEditSheet), for: .touchUpInside)
        self.navigationItem.titleView = titleButton
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc func presentEditSheet() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "EditMetaViewController") as! EditMetaViewController
        vc.modalPresentationStyle = .pageSheet

        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.custom(resolver: { _ in return 300 })]
            //sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.largestUndimmedDetentIdentifier = nil
        }
        vc.existingTitle = receivedText
        vc.existingCourse = selectedCourse
        vc.onSave = { newTitle, newCourse in
            self.receivedText = newTitle
            self.selectedCourse = newCourse
            (self.navigationItem.titleView as? UIButton)?.setTitle(newTitle, for: .normal)
        }
        present(vc, animated: true)

    }

    @objc func saveMemo() {
        let title = receivedText ?? "No title"
        let body = memoTextView.text ?? ""
        let course = selectedCourse ?? "No selected course"
        let today = getTodayString()

        let newNote: [String: String] = [
            "title": title,
            "body": body,
            "course": course
        ]

        var savedNotes = UserDefaults.standard.dictionary(forKey: "savedNotes") as? [String: [String: String]] ?? [:]
        savedNotes[today] = newNote
        UserDefaults.standard.set(savedNotes, forKey: "savedNotes")

        NotificationCenter.default.post(name: NSNotification.Name("NewNoteSaved"), object: nil)
        print("✅ 저장된 메모: [\(title)] \(body), 과목: \(course)")

        let alert = UIAlertController(title: nil, message: "저장되었습니다!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
            self.tabBarController?.selectedIndex = 0
            self.navigationController?.popViewController(animated: false)
        }))
        present(alert, animated: true)
    }

    func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
}
