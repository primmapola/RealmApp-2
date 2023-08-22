import UIKit
import RealmSwift

class TasksViewController: UITableViewController {
    
    //MARK: - Properties
    
    var taskList: TaskList!
    
    private var currentTasks: Results<Task>!
    private var completedTasks: Results<Task>!
    
    //MARK: - Lifesycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = taskList.name
        
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonPressed)
        )
        navigationItem.rightBarButtonItems = [addButton, editButtonItem]
        currentTasks = taskList.tasks.filter("isComplete = false")
        print(taskList)
        completedTasks = taskList.tasks.filter("isComplete = true")
    }
    
    //MARK: - Button Actions
    
    @objc private func addButtonPressed() {
        showAlert()
    }
    
    //MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? currentTasks.count : completedTasks.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "CURRENT TASKS" : "COMPLETED TASKS"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TasksCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let task = indexPath.section == 0 ? currentTasks[indexPath.row] : completedTasks[indexPath.row]
        content.text = task.name
        content.secondaryText = task.note
        cell.contentConfiguration = content
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let task = indexPath.section == 0
            ? currentTasks[indexPath.row]
            : completedTasks[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            StorageManager.shared.delete(task)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            NotificationCenter.default.post(name: Notification.Name("taskDeleted"), object: nil)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [unowned self] _, _, isDone in
            showAlert(with: task) {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            isDone(true)
        }
        
        let doneTitle = indexPath.section == 0 ? "Done" : "Undone"
        
        let doneAction = UIContextualAction(style: .normal, title: doneTitle) { [weak self] _, _, isDone in
            StorageManager.shared.done(task)
            let currentTaskIndex = IndexPath(
                row: self?.currentTasks.index(of: task) ?? 0,
                section: 0
            )
            let completedTaskIndex = IndexPath(
                row: self?.completedTasks.index(of: task) ?? 0,
                section: 1
            )
            let destinationIndexRow = indexPath.section == 0 ? completedTaskIndex : currentTaskIndex
            tableView.moveRow(at: indexPath, to: destinationIndexRow)
            
            isDone(true)
        }
        
        editAction.backgroundColor = .orange
        doneAction.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [doneAction, editAction, deleteAction])
    }
}

//MARK: - Alert Handling

extension TasksViewController {
    private func showAlert(with task: Task? = nil, completion: (() -> Void)? = nil) {
        let title = task != nil ? "Edit Task" : "New Task"
        
        let alert = UIAlertController.createAlert(withTitle: title, andMessage: "What do you want to do?")
        
        alert.action(with: task) { newValue, note, targetDate in
            if let task = task, let completion = completion {
                StorageManager.shared.rename(task, to: newValue, withNote: note, withDate: targetDate)
                completion()
                NotificationCenter.default.post(name: Notification.Name("taskSaved"), object: nil)
            } else {
                self.save(task: newValue, withNote: note, withDate: targetDate)
                NotificationCenter.default.post(name: Notification.Name("taskSaved"), object: nil)
            }
        }
        
        present(alert, animated: true)
    }
    
    private func save(task: String, withNote note: String, withDate targetDate: Date) {
        StorageManager.shared.save(task, withNote: note, withDate: targetDate, to: taskList) { task in
            let rowIndex = IndexPath(row: currentTasks.index(of: task) ?? 0, section: 0)
            tableView.insertRows(at: [rowIndex], with: .automatic)
            NotificationCenter.default.post(name: Notification.Name("taskSaved"), object: nil)
        }
    }
}
