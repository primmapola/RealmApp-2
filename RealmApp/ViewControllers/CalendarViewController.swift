//
//  CalendarViewController.swift
//  RealmApp
//
//  Created by Grigory Don on 12.08.2023.
//  Copyright © 2023 Alexey Efimov. All rights reserved.
//

import Foundation
import FSCalendar
import UIKit
import RealmSwift

class CalendarViewController: UIViewController {
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    var calendarHeightConstraint: NSLayoutConstraint!
    var tasks: Results<Task>?
    var selectedTasks: [Task] = []
    
    private var calendar: FSCalendar = {
        let calendar = FSCalendar()
        calendar.translatesAutoresizingMaskIntoConstraints = false
        return calendar
    }()
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Europe/Moscow")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    
    var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    let showHideButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Открыть календарь", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont(name: "Avenir Next Demi Bold", size: 14)
        return button
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        title = "Расписание"
        
        calendar.delegate = self
        calendar.dataSource = self
        calendar.scope = .week
        
        setConstraints()
        swipeAction()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "taskCell")
        
        showHideButton.addTarget(self, action: #selector(showHideButtonTapped), for: .touchUpInside)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: Notification.Name("taskDeleted"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: Notification.Name("taskSaved"), object: nil)
    }
    
    func loadData() {
        do {
            let realm = try Realm()
            tasks = realm.objects(Task.self).sorted(byKeyPath: "date", ascending: true)
            
            guard let unwrappedTasks = tasks else { return }
            
            for task in unwrappedTasks {
                print("Дата из базы данных: \(task.date)")
            }
            
            print("Success")
        } catch {
            print("Error initializing Realm: \(error)")
        }
    }

    
    @objc func refreshData() {
        loadData()
        filterTasks(for: Date())
        tableView.reloadData()
    }
    
    @objc func showHideButtonTapped() {
        if calendar.scope == .week {
            calendar.setScope(.month, animated: true)
            showHideButton.setTitle("Закрыть", for: .normal)
        } else {
            calendar.setScope(.week, animated: true)
            showHideButton.setTitle("Открыть", for: .normal)
        }
    }
    
    func swipeAction() {
        let swipeUP = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeUP.direction = .up
        calendar.addGestureRecognizer(swipeUP)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeDown.direction = .down
        calendar.addGestureRecognizer(swipeDown)
    }
    
    @objc func handleSwipe(gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .up, .down:
            showHideButtonTapped()
        default:
            break
        }
    }
}

//MARK: FSCalendarDelegate, FSCalendarDataSource

extension CalendarViewController: FSCalendarDelegate, FSCalendarDataSource {
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        calendarHeightConstraint.constant = bounds.height
        view.layoutIfNeeded()
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        let selectedDateString = dateFormatter.string(from: date)
        print("Выбранная дата: \(selectedDateString), Что показывает календарь \(date)")
        filterTasks(for: date)
        tableView.reloadData()
    }
    
    func filterTasks(for date: Date) {
        guard let tasks = tasks else { return }
        
        let selectedDateString = dateFormatter.string(from: date)
        selectedTasks = tasks.filter { dateFormatter.string(from: $0.date) == selectedDateString }
    }
}

extension CalendarViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedTasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let task = selectedTasks[indexPath.row]
        
        // Проверка на валидность объекта
        guard !task.isInvalidated else {
            // Можете возвращать пустую ячейку или делать другие действия
            return cell
        }
        
        content.text = task.name
        content.secondaryText = task.note
        cell.contentConfiguration = content
        return cell
    }
    
    func setConstraints() {
        calendarHeightConstraint = NSLayoutConstraint(item: calendar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 300)
        calendar.addConstraint(calendarHeightConstraint)
        
        view.addSubview(calendar)
        NSLayoutConstraint.activate([
            calendar.topAnchor.constraint(equalTo: view.topAnchor, constant: 90),
            calendar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            calendar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
        ])
        
        view.addSubview(showHideButton)
        NSLayoutConstraint.activate([
            showHideButton.topAnchor.constraint(equalTo: calendar.bottomAnchor, constant: 0),
            showHideButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            showHideButton.widthAnchor.constraint(equalToConstant: 100),
            showHideButton.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: showHideButton.bottomAnchor, constant: 10),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}
