//
//  UIAlertController.swift
//  RealmApp
//
//  Created by Don Grigory on 02.07.2022.
//  Copyright © 2022 Don Grigory. All rights reserved.
//

import UIKit

private var selectedDateKey: UInt8 = 0

enum Importance: String, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

extension UIAlertController {
    
    private var selectedDate: Date? {
        get {
            return objc_getAssociatedObject(self, &selectedDateKey) as? Date
        }
        set(newValue) {
            objc_setAssociatedObject(self, &selectedDateKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    static func createAlert(withTitle title: String, andMessage message: String) -> UIAlertController {
        UIAlertController(title: title, message: message, preferredStyle: .alert)
    }
    
    func createDatePicker() -> UIDatePicker {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        return datePicker
    }
    
    func action(with taskList: TaskList?, completion: @escaping (String) -> Void) {
        
        let doneButton = taskList == nil ? "Save" : "Update"
        
        let saveAction = UIAlertAction(title: doneButton, style: .default) { _ in
            guard let newValue = self.textFields?.first?.text else { return }
            guard !newValue.isEmpty else { return }
            completion(newValue)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        
        addAction(saveAction)
        addAction(cancelAction)
        addTextField { textField in
            textField.placeholder = "List Name"
            textField.text = taskList?.name
        }
    }
    
    func action(with task: Task?, completion: @escaping (String, String, Date) -> Void) {
        
        //        let datePicker = createDatePicker()
        
        let title = task == nil ? "Save" : "Update"
        
        let saveAction = UIAlertAction(title: title, style: .default) { _ in
            guard let newTask = self.textFields?.first?.text else { return }
            guard !newTask.isEmpty else { return }
            
            let finalSelectedDate = self.selectedDate ?? Date.now
            
            if let note = self.textFields?[1].text, !note.isEmpty {
                completion(newTask, note, finalSelectedDate )
                NotificationCenter.default.post(name: Notification.Name("taskSaved"), object: nil)
                print(finalSelectedDate)
            } else {
                completion(newTask, "", finalSelectedDate )
            }
            NotificationCenter.default.post(name: Notification.Name("taskSaved"), object: nil)
            print(finalSelectedDate)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        
        let importancePicker = UIPickerView()
        importancePicker.delegate = self
        importancePicker.dataSource = self
        
        let importanceTextField = UITextField()
        importanceTextField.placeholder = "Importance"
        importanceTextField.inputView = importancePicker
        
        addAction(saveAction)
        addAction(cancelAction)
        
        addTextField { textField in
            textField.placeholder = "New task"
            textField.text = task?.name
        }
        
        addTextField { textField in
            textField.placeholder = "Note"
            textField.text = task?.note
        }
        
        addTextField { textField in
            textField.placeholder = "Target Date"
            textField.text = task?.date.description // или отформатируйте дату, как вы хотите
            
            textField.addTarget(self, action: #selector(self.dateFieldTapped(textField:)), for: .editingDidBegin)
        }
        
        addTextField { textField in
            textField.placeholder = "Importance"
            if let importance = task?.importance {
                textField.text = importance.rawValue
            }
            textField.inputView = importancePicker
        }
    }
    
    @objc func dateFieldTapped(textField: UITextField) {
        let datePickerAlert = UIAlertController(title: "Select Date", message: "\n\n\n\n\n\n\n\n", preferredStyle: .alert)
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.translatesAutoresizingMaskIntoConstraints = false // включаем Auto Layout
        datePickerAlert.view.addSubview(datePicker)
        
        // Центрирование UIDatePicker
        NSLayoutConstraint.activate([
            datePicker.centerXAnchor.constraint(equalTo: datePickerAlert.view.centerXAnchor),
            datePicker.centerYAnchor.constraint(equalTo: datePickerAlert.view.centerYAnchor)
        ])
        
        let selectAction = UIAlertAction(title: "Select", style: .default) { _ in
            // Здесь вы можете отформатировать дату и установить её в текстовом поле
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            self.selectedDate = datePicker.date
            textField.text = formatter.string(from: datePicker.date)
        }
        datePickerAlert.addAction(selectAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        datePickerAlert.addAction(cancelAction)
        
        self.present(datePickerAlert, animated: true)
    }
}

extension Date {
    func toTimeZone(_ timezone: TimeZone) -> Date {
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
}

extension UIAlertController: UIPickerViewDelegate, UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Importance.allCases.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Importance.allCases[row].rawValue
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.textFields?.last?.text = Importance.allCases[row].rawValue
    }
}


