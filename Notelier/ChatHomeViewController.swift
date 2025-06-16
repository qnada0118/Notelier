//
//  ChatHomeViewController.swift
//  Notelier
//
//  Created by 박규나 on 6/6/25.
//

import UIKit

class ChatHomeViewController: UIViewController,
                                    UITableViewDataSource,
                                    UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newChatButton: UIButton!
    
    var chatSessions: [ChatSession] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = nil
        self.title = "Ask"
        
        tableView.dataSource = self
        tableView.delegate = self
        
        chatSessions = ChatStorage.shared.load()
        
        newChatButton.alpha = 0
        tableView.alpha = 0

        animateIntro()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        chatSessions = ChatStorage.shared.load()
        tableView.reloadData()
    }

    func animateIntro() {
        UIView.animate(withDuration: 0.4, delay: 0.3, options: [], animations: {
            self.newChatButton.alpha = 1
        })

        UIView.animate(withDuration: 0.4, delay: 0.6, options: [], animations: {
            self.tableView.alpha = 1
        })
    }
    
    // MARK: - UITableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatSessions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let session = chatSessions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath)
        cell.textLabel?.text = session.title
        cell.detailTextLabel?.text = formattedDate(session.date)
        return cell
    }

    // MARK: - UITableView Delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let session = chatSessions[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatRoomViewController") as? ChatRoomViewController {
            chatVC.messages = session.messages
            chatVC.isReadOnly = true
            chatVC.sessionId = session.id
            self.navigationController?.pushViewController(chatVC, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let deletedSession = chatSessions.remove(at: indexPath.row)
            ChatStorage.shared.delete(deletedSession)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }


    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    @IBAction func newChatTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "ChatRoomViewController") as? ChatRoomViewController {
            vc.isReadOnly = false
            vc.sessionId = UUID()
            vc.messages = []
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
