//  NotesListViewController.swift
//  Notelier
//
//  Created by 박규나 on 6/6/25.

import UIKit

class NotesListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    var allNotes: [Note] = []
    var groupedNotes: [String?: [Note]] = [:]
    var sectionTitles: [String?] = []
    var sectionExpanded: [String?: Bool] = [:]
    var filteredDate: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "All"

        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60

        let menuItems: [UIAction] = [
            UIAction(title: "노트 추가", image: UIImage(systemName: "square.and.pencil")) { _ in
                let newNoteVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NewNoteViewController")
                newNoteVC.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(newNoteVC, animated: true)
            },
            UIAction(title: "과목 추가", image: UIImage(systemName: "plus")) { _ in
                let addCourseVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddCourseViewController")
                let navVC = UINavigationController(rootViewController: addCourseVC)
                navVC.modalPresentationStyle = .formSheet
                self.present(navVC, animated: true)
            },
            UIAction(title: "과목 관리", image: UIImage(systemName: "list.bullet")) { _ in
                let courseManagerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ManageCoursesViewController")
                let navVC = UINavigationController(rootViewController: courseManagerVC)
                navVC.modalPresentationStyle = .formSheet
                self.present(navVC, animated: true)
            }
        ]

        let menu = UIMenu(title: "", children: menuItems)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "ellipsis.circle"), primaryAction: nil, menu: menu)

        NotificationCenter.default.addObserver(self, selector: #selector(loadNotes), name: NSNotification.Name("NewNoteSaved"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewCourse(_:)), name: NSNotification.Name("NewCourseAdded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableView), name: NSNotification.Name("FavoriteCoursesChanged"), object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loadNotes),
            name: NSNotification.Name("CourseListChanged"),
            object: nil
        )


        loadNotes()
    }

    @objc func reloadTableView() {
        tableView.reloadData()
    }

    @objc func loadNotes() {
        var loadedNotes = NoteStorage.shared.loadAll()

        if let filterDate = filteredDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let targetString = formatter.string(from: filterDate)

            loadedNotes = loadedNotes.filter {
                let noteDateString = String($0.date.prefix(10))
                return noteDateString == targetString
            }
            self.navigationItem.title = targetString
        } else {
            self.navigationItem.title = "All"
        }

        allNotes = loadedNotes
        groupedNotes = Dictionary(grouping: allNotes, by: { $0.course })
        loadSavedCourses()

        sectionTitles = groupedNotes.keys.sorted { lhs, rhs in
            switch (lhs, rhs) {
            case (nil, _): return true
            case (_, nil): return false
            default: return (lhs ?? "") < (rhs ?? "")
            }
        }

        for key in sectionTitles {
            sectionExpanded[key] = true
        }

        tableView.reloadData()
    }

    func loadSavedCourses() {
        let savedCourses = UserDefaults.standard.array(forKey: "SavedCourses") as? [[String: String]] ?? []
        for course in savedCourses {
            if let name = course["name"], !groupedNotes.keys.contains(name) {
                groupedNotes[name] = []
            }
        }
    }

    @objc func handleNewCourse(_ notification: Notification) {
        guard let courseInfo = notification.userInfo as? [String: String],
              let courseName = courseInfo["name"] else { return }

        if !groupedNotes.keys.contains(courseName) {
            groupedNotes[courseName] = []
        }

        sectionTitles = groupedNotes.keys.sorted {
            switch ($0, $1) {
            case (nil, _): return true
            case (_, nil): return false
            default: return ($0 ?? "") < ($1 ?? "")
            }
        }

        for key in sectionTitles {
            sectionExpanded[key] = true
        }

        tableView.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let courseKey = sectionTitles[section]
        guard sectionExpanded[courseKey] == true else { return 0 }
        return groupedNotes[courseKey]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell", for: indexPath) as? NoteCell else {
            return UITableViewCell()
        }

        let courseKey = sectionTitles[indexPath.section]
        guard let note = groupedNotes[courseKey]?[indexPath.row] else { return cell }

        cell.textLabel?.text = note.isFavorite ? "★ \(note.title)" : note.title
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        cell.detailTextLabel?.text = note.date
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 13)
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.detailTextLabel?.numberOfLines = 2
        cell.selectionStyle = .none

        return cell
    }


    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        let courseName = sectionTitles[section] ?? "지정되지 않음"
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .label

        let favoriteCourses = UserDefaults.standard.array(forKey: "favoriteCourses") as? [String] ?? []
        let isFavorite = favoriteCourses.contains(courseName)
        titleLabel.text = isFavorite ? "★ \(courseName)" : courseName

        let arrowButton = UIButton(type: .system)
        let isExpanded = sectionExpanded[sectionTitles[section]] ?? true
        let imageName = isExpanded ? "chevron.down" : "chevron.right"
        arrowButton.setImage(UIImage(systemName: imageName), for: .normal)
        arrowButton.tintColor = .gray
        arrowButton.tag = section
        arrowButton.addTarget(self, action: #selector(toggleSection(_:)), for: .touchUpInside)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        arrowButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        headerView.addSubview(arrowButton)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -10),

            arrowButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            arrowButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            arrowButton.widthAnchor.constraint(equalToConstant: 24),
            arrowButton.heightAnchor.constraint(equalToConstant: 24)
        ])

        return headerView
    }

    @objc func toggleSection(_ sender: UIButton) {
        let section = sender.tag
        let key = sectionTitles[section]
        sectionExpanded[key]?.toggle()
        tableView.reloadSections(IndexSet(integer: section), with: .automatic)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let courseKey = sectionTitles[indexPath.section]
        guard let note = groupedNotes[courseKey]?[indexPath.row] else { return nil }

        var favorites = UserDefaults.standard.array(forKey: "favoriteNotes") as? [String] ?? []
        let favoriteTitle = note.isFavorite ? "해제" : "즐겨찾기"

        let favoriteAction = UIContextualAction(style: .normal, title: favoriteTitle) { (_, _, completionHandler) in
            var favorites = UserDefaults.standard.array(forKey: "favoriteNotes") as? [String] ?? []
            if note.isFavorite {
                favorites.removeAll { $0 == note.date }
            } else {
                favorites.append(note.date)
            }
            UserDefaults.standard.set(favorites, forKey: "favoriteNotes")
            tableView.reloadRows(at: [indexPath], with: .automatic)
            completionHandler(true)
        }
        favoriteAction.backgroundColor = .systemYellow

        let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { (_, _, completionHandler) in
            var savedNotes = UserDefaults.standard.dictionary(forKey: "savedNotes") as? [String: [String: String]] ?? [:]
            savedNotes.removeValue(forKey: note.date)
            UserDefaults.standard.set(savedNotes, forKey: "savedNotes")

            favorites.removeAll { $0 == note.date }
            UserDefaults.standard.set(favorites, forKey: "favoriteNotes")

            self.loadNotes()
            completionHandler(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction, favoriteAction])
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showNoteDetail",
           let destination = segue.destination as? NoteDetailViewController,
           let indexPath = tableView.indexPathForSelectedRow {

            let courseKey = sectionTitles[indexPath.section]
            if let note = groupedNotes[courseKey]?[indexPath.row] {
                destination.note = note
            }
        }
    }
}
