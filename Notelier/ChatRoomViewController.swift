import UIKit
import UniformTypeIdentifiers

class ChatRoomViewController: UIViewController,
                              UINavigationControllerDelegate,
                              UIImagePickerControllerDelegate,
                              UIDocumentPickerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var attachButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var attachedNoteView: UIStackView!
    @IBOutlet weak var attachedNoteLabel: UILabel!

    var sessionId: UUID = UUID()
    var isReadOnly: Bool = false
    var messages: [ChatMessage] = []
    var attachedNote: Note?
    var initialQuestion: String?
    var isNewSession: Bool = false
    var mode: String = "질문"
    let placeholderColor: UIColor = .lightGray

    override func viewDidLoad() {
        super.viewDidLoad()

        if messages.isEmpty {
            navigationItem.title = generateTitleFromMode()
        }

        if isNewSession, let question = initialQuestion {

            var gptMessages: [ChatMessage] = []
            if let note = attachedNote {
                let context = ChatMessage(
                    isUser: true,
                    text: "📌 참고 노트:\n\(note.title)\n\(note.body)"
                )
                gptMessages.append(context)
            }
            let originalUserMessage = ChatMessage(isUser: true, text: question)
            gptMessages.append(originalUserMessage)

            OpenAI.shared.detectPurpose(from: gptMessages) { inferredMode in
                self.mode = inferredMode
                self.sendMessageToAI(gptMessages: gptMessages)
                self.saveOrUpdateSession()
                self.attachedNote = nil
                self.updateAttachedNoteView()
            }
        }

        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60

        setupTitleEditable()
        setupAttachMenu()
        setupKeyboardNotifications()
        setupInputTextView()
        setupModeBehavior()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView.addGestureRecognizer(longPress)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    // MARK: - GPT 메시지 전송
    func sendMessageToAI(gptMessages: [ChatMessage]) {

        var updatedGptMessages = gptMessages

        if let note = attachedNote {
            let noteContext = ChatMessage(
                isUser: true,
                text: "📌 참고 노트:\n\(note.title)\n\(note.body)"
            )
            updatedGptMessages.insert(noteContext, at: 0)
        }

        if let lastUserMessage = gptMessages.last(where: { $0.isUser }) {
            let displayText: String
            if let note = attachedNote {
                displayText = "📎 참고 노트: \(note.title)\n\(lastUserMessage.text)"
            } else {
                displayText = lastUserMessage.text
            }

            let displayMessage = ChatMessage(isUser: true, text: displayText)
            self.messages.append(displayMessage)
            self.tableView.reloadData()
            self.saveOrUpdateSession()
        }

        OpenAI.shared.send(messages: updatedGptMessages, mode: self.mode) { response in
            DispatchQueue.main.async {
                guard let reply = response else { return }

                let botReply = ChatMessage(isUser: false, text: reply)
                self.messages.append(botReply)
                self.tableView.reloadData()
                self.saveOrUpdateSession()
                self.attachedNote = nil
                self.updateAttachedNoteView()
            }
        }
    }



    // MARK: - 첨부 노트 처리
    func updateAttachedNoteView() {
        DispatchQueue.main.async {
            if let note = self.attachedNote {
                self.attachedNoteLabel.text = " 📎  \(note.title)"
                self.attachedNoteView.isHidden = false
                self.attachedNoteView.backgroundColor = .systemBackground
            } else {
                self.attachedNoteLabel.text = ""
                self.attachedNoteView.isHidden = true
                self.attachedNoteView.backgroundColor = .clear
            }
        }
    }


    @IBAction func removeAttachedNoteTapped(_ sender: UIButton) {
        attachedNote = nil
        updateAttachedNoteView()
    }

    // MARK: - 답변 길게 눌러 메모로 저장
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let point = gestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point),
              !messages[indexPath.row].isUser,
              gestureRecognizer.state == .began else { return }

        let message = messages[indexPath.row]

        let alert = UIAlertController(title: "메모로 저장", message: "이 답변을 메모에 추가할까요?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "저장", style: .default, handler: { _ in
            self.saveMessageToNote(message: message)
        }))
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    func saveMessageToNote(message: ChatMessage) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let formattedDate = formatter.string(from: Date())

        let newNote = Note(
            date: formattedDate,
            title: "GPT Note",
            body: message.text,
            course: "GPT"
        )
        NoteStorage.shared.save(newNote)

        let alert = UIAlertController(title: "저장 완료", message: "답변이 메모로 저장되었습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)

        NotificationCenter.default.post(name: NSNotification.Name("NewNoteSaved"), object: nil)
    }
}
