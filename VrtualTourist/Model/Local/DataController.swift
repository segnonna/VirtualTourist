//
//  DataController.swift
//  VrtualTourist
//
//  Created by Segnonna Hounsou on 12/04/2022.
//

import Foundation
import CoreData

class DataController {
    let persitentContainer: NSPersistentContainer
    
    var viewContex: NSManagedObjectContext {
        return persitentContainer.viewContext
    }
    
    var backgroundContext:NSManagedObjectContext!
    
    init(modelName: String){
      persitentContainer = NSPersistentContainer(name: modelName)
    }
    
    func configureContext(){
        backgroundContext = persitentContainer.newBackgroundContext()
        viewContex.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContex.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    func load(completion: (() -> Void)? = nil){
        persitentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.autaSaveViewContext()
            self.configureContext()
            completion?()
        }
    }
}

extension DataController{
    func autaSaveViewContext(interval: TimeInterval = 10) {
        guard interval > 0 else {
            print("Cannot set negative autosave inteval")
            return
        }
        if viewContex.hasChanges {
            try? viewContex.save()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autaSaveViewContext(interval: interval)
        }
    }
}
