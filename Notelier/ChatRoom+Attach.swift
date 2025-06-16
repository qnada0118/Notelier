//
//  ChatRoom+Attach.swift
//  Notelier
//
//  Created by 박규나 on 6/14/25.
//

import UIKit
import UniformTypeIdentifiers

extension ChatRoomViewController {
    func setupAttachMenu() {
        let menu = UIMenu(title: "", children: [
            UIAction(title: "노트 선택", image: UIImage(systemName: "note.text")) { _ in
                self.presentNoteSelection()

            }
        ])
        attachButton.menu = menu
        attachButton.showsMenuAsPrimaryAction = true
    }
    
    func presentNoteSelection() {
        let notes = NoteStorage.shared.loadAll() // UserDefaults에서 모든 노트 로드
        let alert = UIAlertController(title: "노트 선택", message: nil, preferredStyle: .actionSheet)

        for note in notes {
            alert.addAction(UIAlertAction(title: note.title, style: .default, handler: { _ in
                self.attachedNote = note
                self.updateAttachedNoteView()
            }))
        }

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    
    func openImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        present(picker, animated: true)
    }

    func openDocumentPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.item], asCopy: true)
        picker.delegate = self
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            print("파일 첨부됨: \(url.lastPathComponent)")
        }
    }
}
