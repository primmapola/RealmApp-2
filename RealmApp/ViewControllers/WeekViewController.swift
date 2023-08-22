import UIKit
import RealmSwift

class WeekViewController: UITableViewController {
    
    //MARK: - Properties
    
    var tasks: Results<Task>?
    var originalTasksGroupedByDay: [String: [Task]] = [:]
    var tasksGroupedByDay: [String: [Task]] = [:]
    
    private let sections = [
        "Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье", "Встречи", "Звонки"
    ]
    
    private let sectionsletters = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс", "Вст", "Зв"]
    
    var searchController = UISearchController(searchResultsController: nil)
    var isSearchActive: Bool {
        return searchController.isActive && !isSearchEmpty
    }
    var isSearchEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    //MARK: - Lifesycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
        groupTasksByWeekday()
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Поиск по задачам"
        navigationItem.leftBarButtonItem = editButtonItem
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    // MARK: - Setup
    
    func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Поиск по задачам"
        navigationItem.leftBarButtonItem = editButtonItem
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    // MARK: - Helper Methods
    
    private func getWeekday(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: date).capitalized
    }
    
    func getWeekDates() -> [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Понедельник
        calendar.timeZone = TimeZone(secondsFromGMT: 3 * 3600)! // GMT-3

        guard let (startDate, _) = getCurrentWeekDateRange() else {
            print("Error getting current week range.")
            return []
        }

        return (0...6).compactMap { calendar.date(byAdding: .day, value: $0, to: startDate) }
    }
    
    // MARK: - Editing
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
    
    // MARK: - Data Management
    
    func loadData() {
        do {
            guard let (startDate, endDate) = getCurrentWeekDateRange() else {
                print("Error getting current week range.")
                return
            }
            
            let realm = try Realm()
            
            print("Начальная дата: \(startDate), Конечная дата: \(endDate)")
            
            tasks = realm.objects(Task.self)
                .filter("date >= %@ AND date <= %@", startDate, endDate)
                .sorted(byKeyPath: "date", ascending: true)
            
            guard let unwrappedTasks = tasks else { return }
            
            for task in unwrappedTasks {
                print("Дата из базы данных: \(task.date)")
            }
            
            print("Success")
        } catch {
            print("Error initializing Realm: \(error)")
        }
    }
    
    func getCurrentWeekDateRange() -> (startDate: Date, endDate: Date)? {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 3 * 3600)!
        calendar.firstWeekday = 2 // Понедельник
            
        let today = Date()
        guard let weekday = calendar.dateComponents([.weekday], from: today).weekday else { return nil }
            
        // Теперь понедельник имеет индекс 1, вторник - 2, и так далее.
        // Если сегодня понедельник, не меняем дату, в противном случае вернемся назад на необходимое количество дней.
        let daysToSubtract = weekday == 2 ? 0 : weekday - 2
            
        guard let roughMonday = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else { return nil }
        
        // Установка времени для понедельника на 00:00:00
        guard let monday = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: roughMonday) else { return nil }
        
        // Получение воскресенья и установка времени на 23:59:59
        guard let roughSunday = calendar.date(byAdding: .day, value: 6, to: monday),
              let sunday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: roughSunday) else {
            return nil
        }
            
        return (monday, sunday)
    }
    
    func updateTaskDate(_ task: Task, toWeekday weekday: String) {
        let calendar = Calendar.current
        guard let (startDate, _) = getCurrentWeekDateRange() else {
            print("Error getting current week range.")
            return
        }

        let weekDates = getWeekDates()

        // Находим индекс выбранного дня недели
        guard let index = sections.firstIndex(of: weekday) else {
            print("Error: Invalid section.")
            return
        }
        
        if index < weekDates.count {
            let newDate = weekDates[index]
            
            // Сохраняем часы, минуты и секунды из исходной даты задачи
            let components = calendar.dateComponents([.hour, .minute, .second], from: task.date)
            guard let updatedDate = calendar.date(bySettingHour: components.hour ?? 0,
                                                  minute: components.minute ?? 0,
                                                  second: components.second ?? 0,
                                                  of: newDate) else {
                print("Error computing new date.")
                return
            }

            // Обновление поля date в Realm
            do {
                let realm = try Realm()
                try realm.write {
                    task.date = updatedDate
                }
                print("Updated task date to: \(updatedDate)")
            } catch {
                print("Error updating task date: \(error)")
            }
        } else {
            // Тут обработка для нестандартных секций "Встречи" и "Звонки", если это необходимо
        }
    }
    
    func groupTasksByWeekday() {
        originalTasksGroupedByDay.removeAll()
        tasksGroupedByDay.removeAll()
        if let unwrappedTasks = tasks {
            for task in unwrappedTasks {
                let weekday = getWeekday(from: task.date)
                if originalTasksGroupedByDay[weekday] == nil {
                    originalTasksGroupedByDay[weekday] = []
                }
                originalTasksGroupedByDay[weekday]?.append(task)
            }
        }
        tasksGroupedByDay = originalTasksGroupedByDay
    }
    
    func filterTasks(with query: String) {
        for (section, tasks) in originalTasksGroupedByDay {
            tasksGroupedByDay[section] = tasks.filter {
                $0.name.lowercased().contains(query.lowercased()) || $0.note.lowercased().contains(query.lowercased())
            }
        }
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasksGroupedByDay[sections[section]]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let weekdays = getWeekDates()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd_MM"
        
        // Проверка, чтобы избежать выхода за пределы массива.
        if section < weekdays.count {
            let dateTitle = formatter.string(from: weekdays[section])
            let title = "\(sections[section]) - \(dateTitle)"
            print(title)
            return title
        } else {
            return sections[section] // Для "Встречи" и "Звонки"
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if let tasksForDay = tasksGroupedByDay[sections[indexPath.section]], indexPath.row < tasksForDay.count {
            let task = tasksForDay[indexPath.row]
            var content = cell.defaultContentConfiguration()
            content.text = task.name
            content.secondaryText = task.note
            cell.contentConfiguration = content
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return sectionsletters.firstIndex(of: title) ?? 0
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionsletters
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let sourceTasks = tasksGroupedByDay[sections[sourceIndexPath.section]] else {
            return
        }
        let destinationDay = sections[destinationIndexPath.section]
        
        let movedTask = sourceTasks[sourceIndexPath.row]
        
        tasksGroupedByDay[sections[sourceIndexPath.section]]?.remove(at: sourceIndexPath.row)
        
        if tasksGroupedByDay[destinationDay] == nil {
            tasksGroupedByDay[destinationDay] = []
        }
        tasksGroupedByDay[destinationDay]?.append(movedTask)
        
        updateTaskDate(movedTask, toWeekday: destinationDay)
        
        // После обновления задачи в Realm, загрузите данные и сгруппируйте задачи снова.
        loadData()
        groupTasksByWeekday()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate

extension WeekViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = RedactInfoViewController()
        if let tasksForDay = tasksGroupedByDay[sections[indexPath.section]] {
            detailVC.task = tasksForDay[indexPath.row]
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}

// MARK: - UISearchResultsUpdating

extension WeekViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text else { return }
        if query.isEmpty {
            tasksGroupedByDay = originalTasksGroupedByDay
            tableView.reloadData()
        } else {
            filterTasks(with: query)
        }
    }
}
