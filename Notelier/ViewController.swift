//  ViewController.swift
//  Notelier
//
//  Created by 박규나 on 6/6/25.
//


import UIKit

class ViewController: UIViewController, UITextViewDelegate,
                      UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var starredCollectionView: UICollectionView!
    @IBOutlet weak var datePicker: UIDatePicker!

    var selectedMode: Int = 0 {
        didSet { updatePlaceholder() }
    }

    let placeholders = [
        0: "무엇을 기록할까요?",
        1: "궁금한 점을 입력해보세요",
    ]

    var starredNotes: [Note] = []
    var lastSelectedDate: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        logoImageView.image = UIImage(named: "logo")
        inputTextView.delegate = self
        updatePlaceholder()

        starredCollectionView.dataSource = self
        starredCollectionView.delegate = self
        if let layout = starredCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }

        segmentedControl.removeAllSegments()
        segmentedControl.insertSegment(withTitle: "노트", at: 0, animated: false)
        segmentedControl.insertSegment(withTitle: "질문", at: 1, animated: false)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)

        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .inline
        datePicker.addTarget(self, action: #selector(datePicked(_:)), for: .allEvents)

        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissTap.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissTap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetForm()
        inputTextView.resignFirstResponder()
        loadStarredNotes()
        starredCollectionView.reloadData()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        datePicker.setDate(Date(), animated: false)
        lastSelectedDate = nil
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    func resetForm() {
        selectedMode = 0
        segmentedControl.selectedSegmentIndex = 0
        inputTextView.text = ""
        updatePlaceholder()
        lastSelectedDate = nil
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func updatePlaceholder() {
        if inputTextView.text.isEmpty || inputTextView.textColor == .lightGray {
            inputTextView.text = placeholders[selectedMode]
            inputTextView.textColor = .lightGray
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = ""
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            updatePlaceholder()
        }
    }

    func loadStarredNotes() {
        let allNotes = NoteStorage.shared.loadAll()
        starredNotes = allNotes.filter { $0.isFavorite }
    }

    @objc func segmentChanged(_ sender: UISegmentedControl) {
        selectedMode = sender.selectedSegmentIndex
    }

    @IBAction func tapCheck(_ sender: UIButton) {
        let text = inputTextView.text ?? ""
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return }

        if selectedMode == 1 { // 질문 모드
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatRoomViewController") as? ChatRoomViewController {
                chatVC.initialQuestion = text
                chatVC.isNewSession = true
                chatVC.mode = "질문"           
                chatVC.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(chatVC, animated: true)
            }
        } else {
            // 기존 메모 작성 로직
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let nextVC = storyboard.instantiateViewController(withIdentifier: "NewNoteViewController") as? NewNoteViewController {
                nextVC.receivedText = text
                nextVC.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(nextVC, animated: true)
            }
        }
    }


    @IBAction func datePicked(_ sender: UIDatePicker) {
        let selectedDate = sender.date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd (E)"
        let selectedString = formatter.string(from: selectedDate)
        print("📆 선택된 날짜: \(selectedString)")

        if let last = lastSelectedDate,
           Calendar.current.isDate(last, inSameDayAs: selectedDate) {
            // 같은 날짜를 선택한 경우 → 오늘이라도 중복 방지
            if Calendar.current.isDateInToday(selectedDate) == false {
                return
            }
        }

        // 이동 및 저장
        goToNotesList(for: selectedDate)
        lastSelectedDate = selectedDate
    }


    func goToNotesList(for date: Date) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let notesVC = storyboard.instantiateViewController(withIdentifier: "NotesListViewController") as? NotesListViewController {
            notesVC.filteredDate = date
            self.navigationController?.pushViewController(notesVC, animated: true)
        }
    }

    // MARK: ⭐️ UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return starredNotes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StarredCell", for: indexPath)
        
        if let titleLabel = cell.contentView.viewWithTag(1) as? UILabel {
            titleLabel.text = starredNotes[indexPath.item].title
            titleLabel.isUserInteractionEnabled = false
        }

        cell.contentView.layer.cornerRadius = 10
        cell.contentView.layer.borderWidth = 1
        cell.contentView.layer.borderColor = UIColor.systemGray5.cgColor

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedNote = starredNotes[indexPath.item]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "NoteDetailViewController") as? NoteDetailViewController {
            detailVC.note = selectedNote
            detailVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
    }

    // MARK: ⭐️ UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    }
}
