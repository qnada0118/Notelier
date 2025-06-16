//
//  NoteCell.swift
//  Notelier
//
//  Created by 박규나 on 6/15/25.
//

import UIKit

class NoteCell: UITableViewCell {

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 0.5
        contentView.layer.borderColor = UIColor.systemGray5.cgColor

        backgroundColor = .clear
    }
}
