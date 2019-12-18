//
//  DataSource.swift
//  Virtual Tour
//
//  Created by Juan Arcos on 12/18/19.
//  Copyright © 2019 Arcos. All rights reserved.
//

import Foundation
import CoreData

struct DataSource {
    
    static func retrieve<T: NSManagedObject>(entityClass: T.Type,
                                             context: NSManagedObjectContext,
                                             sortBy: String? = nil,
                                             isAscending: Bool = true,
                                             predicate: NSPredicate? = nil) -> [T]? {
        let entityName = NSStringFromClass(entityClass)
        let request    = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        
        request.returnsObjectsAsFaults = false
        request.predicate = predicate
        
        if (sortBy != nil) {
            let sorter = NSSortDescriptor(key:sortBy , ascending:isAscending)
            request.sortDescriptors = [sorter]
        }
        
        let commits = try? context.fetch(request) as! [T]
        return commits
        
    }
    
}
