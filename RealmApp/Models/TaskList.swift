import Foundation
import RealmSwift

class TaskList: Object {
    @Persisted var name = ""
    @Persisted var date = Date() 
    @Persisted var tasks = List<Task>()
}

class Task: Object {
    @Persisted var name = ""
    @Persisted var note = ""
    @Persisted var date = Date()
    @Persisted var isComplete = false
    @Persisted var importanceRawValue: String = Importance.low.rawValue
    
    var importance: Importance {
        get {
            return Importance(rawValue: importanceRawValue) ?? .low
        }
        set {
            importanceRawValue = newValue.rawValue
        }
    }
}
