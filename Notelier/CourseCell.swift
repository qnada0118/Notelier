//  CourseCell.swift
//  Notelier

import UIKit

protocol CourseCellDelegate: AnyObject {
    func didTapCourseButton(at index: Int)
}

class CourseCell: UICollectionViewCell {

    @IBOutlet weak var courseButton: UIButton!

    weak var delegate: CourseCellDelegate?
    var index: Int?

    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        backgroundColor = .clear

        // 버튼 터치 이벤트 연결
        courseButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    @objc private func buttonTapped() {
        if let index = index {
            delegate?.didTapCourseButton(at: index)
        }
    }

    func configure(with title: String, selected: Bool, isAddButton: Bool) {
        courseButton.setTitle(title, for: .normal)

        if isAddButton {
            // ➕ 과목 추가 버튼
            courseButton.setTitleColor(.white, for: .normal)
            courseButton.backgroundColor = UIColor(red: 0.0, green: 0.77, blue: 0.55, alpha: 1.0) // 민트
        } else {
            if selected {
                courseButton.setTitleColor(.white, for: .normal)
                courseButton.backgroundColor = UIColor(red: 0.18, green: 0.66, blue: 0.66, alpha: 1.0) // 블루그린
            } else {
                courseButton.setTitleColor(UIColor(red: 0.20, green: 0.62, blue: 0.56, alpha: 1.0), for: .normal) // 텍스트 민트
                courseButton.backgroundColor = UIColor(red: 0.87, green: 0.96, blue: 0.95, alpha: 1.0) // 밝은 민트 회색
            }
        }



        courseButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        courseButton.layer.cornerRadius = 16
        courseButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
    }
}
