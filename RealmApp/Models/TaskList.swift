//
//  TaskListsViewCTaskListontroller.swift
//  RealmApp
//
//  Created by Don Grigory on 02.07.2022.
//  Copyright © 2022 Don Grigory. All rights reserved.
//

import Foundation
import RealmSwift

class TaskList: Object {
    @Persisted var name = ""
    @Persisted var date = Date() // Дата создания списка задач
    @Persisted var tasks = List<Task>()
}

class Task: Object {
    @Persisted var name = ""
    @Persisted var note = ""
    @Persisted var date = Date() // Дата создания задачи
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
