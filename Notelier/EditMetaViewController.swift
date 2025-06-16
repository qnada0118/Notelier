//  EditMetaViewController.swift
//  Notelier
//
//  Created by 박규나 on 6/6/25.
//

import UIKit

class EditMetaViewController: UIViewController {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var existingTitle: String?
    var existingCourse: String?
    var onSave: ((_ title: String, _ course: String) -> Void)?

    var courses: [String] = []
    var selectedCourse: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        titleTextField.text = existingTitle

        collectionView.delegate = self
        collectionView.dataSource = self

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumInteritemSpacing = 0
            layout.minimumLineSpacing = 8 // 또는 0 (세로 정렬 시 줄 간격)
            layout.sectionInset = .zero // 섹션 내부 여백 제거
        }

        if let saved = UserDefaults.standard.array(forKey: "SavedCourses") as? [[String: String]] {
            courses = saved.compactMap { $0["name"] }
            print("✅ 저장된 과목 이름들: \(courses)")
        } else {
            print("⚠️ 저장된 과목 없음")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadCourses), name: NSNotification.Name("NewCourseAdded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)


        selectedCourse = existingCourse
        collectionView.reloadData()
    }

    @IBAction func doneButtonTapped(_ sender: UIButton) {
        let title = titleTextField.text ?? ""
        let course = selectedCourse ?? ""
        print("📝 저장 시 선택된 과목: \(course.isEmpty ? "없음" : course)")

        onSave?(title, course)
        dismiss(animated: true)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    @objc func reloadCourses() {
        if let saved = UserDefaults.standard.array(forKey: "SavedCourses") as? [[String: String]] {
            courses = saved.compactMap { $0["name"] }
            collectionView.reloadData()
        }
    }
    @objc func keyboardWillShow(_ notification: Notification) {
        guard view.frame.origin.y == 0 else { return }

        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            view.frame.origin.y -= keyboardHeight  // 필요시 비율 조정
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        view.frame.origin.y = 0
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

// MARK: - CollectionView Delegate & DataSource

extension EditMetaViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, CourseCellDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return courses.count + 1 // 마지막 셀은 ➕ 과목 추가 버튼
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CourseCell", for: indexPath) as! CourseCell
        cell.delegate = self
        cell.index = indexPath.item

        if indexPath.item == courses.count {
            // ➕ 과목 추가 셀
            cell.configure(with: "➕ 과목 추가", selected: false, isAddButton: true)
        } else {
            let course = courses[indexPath.item]
            let isSelected = (course == selectedCourse)
            cell.configure(with: course, selected: isSelected, isAddButton: false)
        }

        return cell
    }

    func didTapCourseButton(at index: Int) {
        if index == courses.count {
                // ➕ 버튼이면 화면 이동
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let vc = storyboard.instantiateViewController(withIdentifier: "AddCourseViewController") as? AddCourseViewController {
                    vc.modalPresentationStyle = .formSheet
                    present(vc, animated: true)
                }
            } else {
                let tappedCourse = courses[index]
                if selectedCourse == tappedCourse {
                    // 👉 다시 누르면 선택 취소
                    selectedCourse = nil
                } else {
                    selectedCourse = tappedCourse
                }
                collectionView.reloadData()
            }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let title = indexPath.item == courses.count ? "➕ 과목 추가" : courses[indexPath.item]
        let width = (title as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 14)]).width
        return CGSize(width: width + 24, height: 32)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }

}
