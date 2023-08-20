import UIKit
import RealmSwift

class WeekViewController: UITableViewController {

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
        navigationItem.searchController = searchController
        definesPresentationContext = true

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
