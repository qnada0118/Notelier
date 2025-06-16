//  NoteDetailViewController.swift
//  Notelier

import UIKit

class NoteDetailViewController: UIViewController, UITextViewDelegate {

    var note: Note? {
        didSet {
            updateTitleView()
        }
    }

    var saveButton: UIBarButtonItem?

    @IBOutlet weak var bodyTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        bodyTextView.text = note?.body
        bodyTextView.font = UIFont.systemFont(ofSize: 16)
        bodyTextView.isEditable = true
        bodyTextView.delegate = self

        let moreMenu = UIMenu(title: "", children: [
            UIAction(title: "Quiz", image: UIImage(systemName: "doc.text.magnifyingglass")) { _ in
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatRoomViewController") as? ChatRoomViewController {
                    chatVC.attachedNote = self.note
                    chatVC.initialQuestion = "이 노트를 바탕으로 퀴즈를 만들어줘"
                    chatVC.mode = "퀴즈"
                    chatVC.isNewSession = true
                    chatVC.sessionId = UUID()
                    self.navigationController?.pushViewController(chatVC, animated: true)
                }
            },
            UIAction(title: "Summary", image: UIImage(systemName: "text.alignleft")) { _ in
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatRoomViewController") as? ChatRoomViewController {
                    chatVC.attachedNote = self.note
                    chatVC.initialQuestion = "이 노트를 요약해줘"
                    chatVC.mode = "요약"
                    chatVC.isNewSession = true
                    chatVC.sessionId = UUID()
                    self.navigationController?.pushViewController(chatVC, animated: true)
                }
            },
            UIAction(title: "삭제", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.confirmDelete()
            }
        ])

        let moreButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: nil,
            action: nil
        )
        moreButton.menu = moreMenu
        navigationItem.rightBarButtonItem = moreButton

        updateTitleView()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

        saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveContent))
    }

    func updateTitleView() {
        let titleButton = UIButton(type: .system)
        titleButton.setTitle(note?.title ?? "제목 없음", for: .normal)
        titleButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        titleButton.setTitleColor(.label, for: .normal)
        titleButton.addTarget(self, action: #selector(editMetaTapped), for: .touchUpInside)
        navigationItem.titleView = titleButton
    }

    func confirmDelete() {
        let alert = UIAlertController(title: "정말 삭제할까요?", message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive, handler: { _ in
            guard let date = self.note?.date else { return }
            
            var savedNotes = UserDefaults.standard.dictionary(forKey: "savedNotes") as? [String: [String: String]] ?? [:]
            savedNotes.removeValue(forKey: date)
            UserDefaults.standard.set(savedNotes, forKey: "savedNotes")
            
            var favorites = UserDefaults.standard.array(forKey: "favoriteNotes") as? [String] ?? []
            favorites.removeAll { $0 == date }
            UserDefaults.standard.set(favorites, forKey: "favoriteNotes")
            
            NotificationCenter.default.post(name: NSNotification.Name("NewNoteSaved"), object: nil)
            
            self.navigationController?.popViewController(animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }


    @objc func editMetaTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "EditMetaViewController") as! EditMetaViewController
        vc.modalPresentationStyle = .pageSheet

        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.custom(resolver: { _ in return 300 })]
            sheet.prefersGrabberVisible = true
        }

        vc.existingTitle = note?.title
        vc.existingCourse = note?.course

        vc.onSave = { newTitle, newCourse in
            guard let oldDate = self.note?.date else { return }

            var savedNotes = UserDefaults.standard.dictionary(forKey: "savedNotes") as? [String: [String: String]] ?? [:]

            if var noteDict = savedNotes[oldDate] {
                noteDict["title"] = newTitle
                noteDict["course"] = newCourse
                savedNotes[oldDate] = noteDict
                UserDefaults.standard.set(savedNotes, forKey: "savedNotes")

                self.note = Note(date: oldDate, title: newTitle, body: self.bodyTextView.text ?? "", course: newCourse)
                self.updateTitleView()

                NotificationCenter.default.post(name: NSNotification.Name("NewNoteSaved"), object: nil)
            }
        }

        present(vc, animated: true)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        navigationItem.rightBarButtonItem = saveButton
    }

    @objc func saveContent() {
        guard let oldDateKey = note?.date else { return }
        let newBody = bodyTextView.text ?? ""

        var savedNotes = UserDefaults.standard.dictionary(forKey: "savedNotes") as? [String: [String: String]] ?? [:]
        savedNotes.removeValue(forKey: oldDateKey)

        let newDateKey = getTodayString()
        let newNote: [String: String] = [
            "title": note?.title ?? "(제목 없음)",
            "body": newBody,
            "course": note?.course ?? "no selected course"
        ]

        savedNotes[newDateKey] = newNote
        UserDefaults.standard.set(savedNotes, forKey: "savedNotes")

        note = Note(date: newDateKey, title: newNote["title"]!, body: newNote["body"]!, course: newNote["course"]!)
        NotificationCenter.default.post(name: NSNotification.Name("NewNoteSaved"), object: nil)

        bodyTextView.resignFirstResponder()
        navigationItem.rightBarButtonItem = nil
    }

    func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
}
