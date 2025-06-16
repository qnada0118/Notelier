//
//  ChatRoom+TableView.swift
//  Notelier
//
//  Created by 박규나 on 6/14/25.
//

import UIKit

extension ChatRoomViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let cellId = message.isUser ? "UserCell" : "GPTCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        cell.textLabel?.text = message.text
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.textAlignment = message.isUser ? .right : .left
        return cell
    }
}
