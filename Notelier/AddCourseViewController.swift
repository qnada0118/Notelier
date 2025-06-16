//
//  AddCourseViewController.swift
//  Notelier
//
//  Created by 박규나 on 6/6/25.
//

import UIKit

class AddCourseViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var semesterTextField: UITextField!

    let semesterOptions = ["No select", "2024-1", "2024-2", "2025-1", "2025-2", "2026-1", "2026-2"]
    let pickerView = UIPickerView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupSemesterPicker()
    }

    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "취소",
            style: .plain,
            target: self,
            action: #selector(didTapCancel)
        )
    }

    private func setupSemesterPicker() {
        pickerView.delegate = self
        pickerView.dataSource = self
        semesterTextField.inputView = pickerView

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePickingSemester))
        toolbar.setItems([doneButton], animated: false)
        semesterTextField.inputAccessoryView = toolbar
    }

    @objc func donePickingSemester() {
        let selectedRow = pickerView.selectedRow(inComponent: 0)
        semesterTextField.text = semesterOptions[selectedRow]
        semesterTextField.resignFirstResponder()
    }

    @IBAction func didTapSave(_ sender: UIButton) {
        guard let name = nameTextField.text, !name.isEmpty else {
            showAlert("과목 이름을 입력해주세요.")
            return
        }

        let semester = semesterTextField.text ?? ""
        let newCourse: [String: String] = [
            "name": name,
            "semester": semester
        ]

        saveCourse(newCourse)

        NotificationCenter.default.post(name: NSNotification.Name("NewCourseAdded"), object: nil, userInfo: newCourse)
        dismiss(animated: true)
    }

    @objc func didTapCancel() {
        dismiss(animated: true)
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    /// ✅ UserDefaults에 과목 정보 저장
    func saveCourse(_ course: [String: String]) {
        var savedCourses = UserDefaults.standard.array(forKey: "SavedCourses") as? [[String: String]] ?? []

        // 중복 방지 (이미 존재하는 경우 저장 안 함)
        if !savedCourses.contains(where: { $0["name"] == course["name"] }) {
            savedCourses.append(course)
            UserDefaults.standard.set(savedCourses, forKey: "SavedCourses")
        }
    }
}

// MARK: - UIPickerViewDelegate & DataSource
extension AddCourseViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        semesterOptions.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        semesterOptions[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        semesterTextField.text = semesterOptions[row]
    }
}
