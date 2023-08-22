import UIKit
import RealmSwift

class FoundedTasksViewController: UITableViewController {

    // MARK: - Properties
    var hashtag: String? {
        didSet {
            navigationItem.title = hashtag
        }
    }

    private var tasksWithHashtag: Results<Task>?  // это для использования с Realm
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "Заметок с таким хештегом не найдено."
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        if let hashtagValue = hashtag {
            navigationItem.title = hashtagValue
        }
        loadData()
    }

    private func setupUI() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "taskCell")
        view.addSubview(messageLabel)
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadData() {
        guard let hashtag = hashtag else { return }

        let realm = try? Realm()
        tasksWithHashtag = realm?.objects(Task.self).filter("note CONTAINS %@", hashtag)

        if tasksWithHashtag?.isEmpty ?? true {
            tableView.isHidden = true
            messageLabel.isHidden = false
        } else {
            tableView.isHidden = false
            messageLabel.isHidden = true
        }

        tableView.reloadData()
    }

    // MARK: - UITableView DataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasksWithHashtag?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskCell", for: indexPath)
        if let task = tasksWithHashtag?[indexPath.row] {
            var content = cell.defaultContentConfiguration()
            content.text = task.name
            content.secondaryText = task.note
            cell.contentConfiguration = content
        }
        return cell
    }
}
