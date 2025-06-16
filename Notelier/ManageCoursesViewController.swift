//
//  ManageCoursesViewController.swift
//  Notelier
//
//  Created by 박규나 on 6/7/25.
//

import UIKit

class ManageCoursesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    var courses: [String] = []
    var favoriteCourses: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "과목 관리"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CourseCell")

        loadCourses()
    }

    @objc func close() {
        NotificationCenter.default.post(name: NSNotification.Name("FavoriteCoursesChanged"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("CourseListChanged"), object: nil)
        dismiss(animated: true)
    }

    func loadCourses() {
        let savedCourses = UserDefaults.standard.array(forKey: "SavedCourses") as? [[String: String]] ?? []
        courses = savedCourses.compactMap { $0["name"] }
        favoriteCourses = UserDefaults.standard.array(forKey: "favoriteCourses") as? [String] ?? []
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return courses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CourseCell", for: indexPath)
        let name = courses[indexPath.row]
        cell.textLabel?.text = favoriteCourses.contains(name) ? "★ \(name)" : name
        return cell
    }

    // 즐겨찾기 & 삭제 지원
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let courseToModify = courses[indexPath.row]
        let savedNotes = UserDefaults.standard.dictionary(forKey: "savedNotes") as? [String: [String: String]] ?? [:]
        let notesInCourse = savedNotes.filter { $0.value["course"] == courseToModify }

        let isFavorite = favoriteCourses.contains(courseToModify)
        let favoriteAction = UIContextualAction(style: .normal, title: isFavorite ? "즐겨찾기 해제" : "즐겨찾기") { (_, _, completion) in
            if isFavorite {
                self.favoriteCourses.removeAll { $0 == courseToModify }
            } else {
                self.favoriteCourses.append(courseToModify)
            }
            UserDefaults.standard.set(self.favoriteCourses, forKey: "favoriteCourses")
            tableView.reloadRows(at: [indexPath], with: .automatic)
            completion(true)
        }
        favoriteAction.backgroundColor = .systemYellow

        let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { (_, _, completion) in
            if !notesInCourse.isEmpty {
                let alert = UIAlertController(title: "노트 포함", message: "해당 과목에 포함된 노트도 함께 삭제됩니다. 계속하시겠습니까?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "예", style: .destructive) { _ in
                    self.deleteCourseAndNotes(courseToModify, notesToDelete: notesInCourse.keys.map { $0 }, indexPath: indexPath)
                    completion(true)
                })
                alert.addAction(UIAlertAction(title: "아니오", style: .cancel) { _ in
                    completion(false)
                })
                self.present(alert, animated: true)
            } else {
                self.deleteCourseAndNotes(courseToModify, notesToDelete: [], indexPath: indexPath)
                completion(true)
            }
        }

        return UISwipeActionsConfiguration(actions: [deleteAction, favoriteAction])
    }

    func deleteCourseAndNotes(_ courseName: String, notesToDelete: [String], indexPath: IndexPath) {
        // 과목 삭제
        courses.remove(at: indexPath.row)
        var savedCourses = UserDefaults.standard.array(forKey: "SavedCourses") as? [[String: String]] ?? []
        savedCourses.removeAll { $0["name"] == courseName }
        UserDefaults.standard.set(savedCourses, forKey: "SavedCourses")

        // 즐겨찾기 제거
        favoriteCourses.removeAll { $0 == courseName }
        UserDefaults.standard.set(favoriteCourses, forKey: "favoriteCourses")

        // 노트 삭제
        var savedNotes = UserDefaults.standard.dictionary(forKey: "savedNotes") as? [String: [String: String]] ?? [:]
        for date in notesToDelete {
            savedNotes.removeValue(forKey: date)
        }
        UserDefaults.standard.set(savedNotes, forKey: "savedNotes")

        var favorites = UserDefaults.standard.array(forKey: "favoriteNotes") as? [String] ?? []
        favorites.removeAll { notesToDelete.contains($0) }
        UserDefaults.standard.set(favorites, forKey: "favoriteNotes")

        tableView.deleteRows(at: [indexPath], with: .automatic)
        NotificationCenter.default.post(name: NSNotification.Name("CourseListChanged"), object: nil)

    }
}
