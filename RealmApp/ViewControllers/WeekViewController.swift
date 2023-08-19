import UIKit
import RealmSwift

class WeekViewController: UIViewController {
    
    var tasks: Results<Task>?
    
    var tasksGroupedByDay: [String: [Task]] = [:]
    
    private let tableView = UITableView()
    
    // Названия секций
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
        tasksGroupedByDay.removeAll()  // очищаем словарь перед группировкой
        for task in tasks! {
            let weekday = getWeekday(from: task.date)
            if tasksGroupedByDay[weekday] == nil {
                tasksGroupedByDay[weekday] = []
            }
            tasksGroupedByDay[weekday]?.append(task)
        }
        for (key, value) in tasksGroupedByDay {
            print("\(key): \(value.count) tasks")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setupTableView()
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
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
}

// MARK: - UITableViewDataSource

extension WeekViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasksGroupedByDay[sections[section]]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return sectionsletters.firstIndex(of: title) ?? 0
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionsletters
    }
}

// MARK: - UITableViewDelegate

extension WeekViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}

