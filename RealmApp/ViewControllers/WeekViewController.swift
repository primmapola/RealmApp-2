import UIKit
import RealmSwift

class WeekViewController: UITableViewController {
    
    var tasks: Results<Task>?
    var tasksGroupedByDay: [String: [Task]] = [:]
    
    private let sections = [
        "Понедельник",
        "Вторник",
        "Среда",
        "Четверг",
        "Пятница",
        "Суббота",
        "Воскресенье",
        "Встречи",
        "Звонки"
    ]
    
    private let sectionsletters = [
        "Пн",
        "Вт",
        "Ср",
        "Чт",
        "Пт",
        "Сб",
        "Вс",
        "Вст",
        "Зв"
    ]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
        groupTasksByWeekday()
        tableView.reloadData()
    }

    func groupTasksByWeekday() {
        tasksGroupedByDay.removeAll()
        if let unwrappedTasks = tasks {
            for task in unwrappedTasks {
                let weekday = getWeekday(from: task.date)
                if tasksGroupedByDay[weekday] == nil {
                    tasksGroupedByDay[weekday] = []
                }
                tasksGroupedByDay[weekday]?.append(task)
            }
        }
        for (key, value) in tasksGroupedByDay {
            print("\(key): \(value.count) tasks")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    private func getWeekday(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: date).capitalized
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
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasksGroupedByDay[sections[section]]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
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
}

// MARK: - UITableViewDelegate

extension WeekViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = RedactInfoViewController()
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
