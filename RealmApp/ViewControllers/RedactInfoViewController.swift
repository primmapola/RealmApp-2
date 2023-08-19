//
//  RedactInfoViewController.swift
//  RealmApp
//
//  Created by Grigory Don on 19.08.2023.
//  Copyright © 2023 Alexey Efimov. All rights reserved.
//

import Foundation
import RealmSwift
import UIKit

class RedactInfoViewController: UIViewController {
    
    var task: Task?
    
    private var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false // Важно для использования AutoLayout
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isEditable = true
        view.backgroundColor = .white
        view.addSubview(textView)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Сохранить", style: .done, target: self, action: #selector(saveChanges))
        
        if let task = task {
            // Создание жирного шрифта для названия
            let boldFont = UIFont.boldSystemFont(ofSize: 22)
            let regularFont = UIFont.systemFont(ofSize: 16)
            
            // Создание атрибутированной строки для названия
            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: boldFont
            ]
            let nameAttributedString = NSMutableAttributedString(string: task.name, attributes: nameAttributes)
            
            // Создание атрибутированной строки для заметки
            let noteAttributes: [NSAttributedString.Key: Any] = [
                .font: regularFont
            ]
            let noteAttributedString = NSAttributedString(string: "\n" + task.note, attributes: noteAttributes)
            
            // Объединение двух атрибутированных строк
            nameAttributedString.append(noteAttributedString)
            
            // Установка атрибутированной строки в textView
            textView.attributedText = nameAttributedString
        }
        
        print(task)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    @objc private func saveChanges() {
        // Разделим атрибутированный текст на две части: название и заметку
        guard let fullText = textView.text else { return }
        let components = fullText.components(separatedBy: "\n")
        guard !components.isEmpty else { return }
        
        let name = components[0]
        let note = components.dropFirst().joined(separator: "\n") // Объединяем оставшиеся компоненты в одну строку, разделенную "\n"
        
        do {
            let realm = try Realm()
            try realm.write {
                task?.name = name
                task?.note = note
            }
            navigationController?.popViewController(animated: true) // Возвращаемся к предыдущему контроллеру после сохранения
        } catch {
            print("Error saving changes: \(error)")
        }
    }

}

