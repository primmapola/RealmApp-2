//
//  DataManager.swift
//  RealmApp
//
//  Created by Don Grigory on 02.07.2022.
//  Copyright © 2022 Don Grigory. All rights reserved.
//

import Foundation

class DataManager {
    static let shared = DataManager()
    
    private init() {}
    
    func createTempData(completion: @escaping () -> Void) {
        if !UserDefaults.standard.bool(forKey: "done") {
            let shoppingList = TaskList()
            shoppingList.name = "Shopping List"
            
            let moviesList = TaskList(
                value: [
                    "Movies List",
                    Date(),
                    [
                        ["Best film ever"],
                        ["The best of the best", "Must have", Date(), true]
                    ]
                ]
            )
            
            let milk = Task()
            milk.name = "Milk"
            milk.note = "2L"
            
            let bread = Task(value: ["Bread", "", Date(), true])
            let apples = Task(value: ["name": "Apples", "note": "2Kg"])
            
            shoppingList.tasks.append(milk)
            shoppingList.tasks.insert(contentsOf: [bread, apples], at: 1)
            
            DispatchQueue.main.async {
                StorageManager.shared.save([shoppingList, moviesList])
                UserDefaults.standard.set(true, forKey: "done")
                completion()
            }
        }
    }
}
