//
//  Diary+CoreDataProperties.swift
//  
//
//  Created by unchain, 웡빙 on 2022/08/30.
//
//

import Foundation
import CoreData

extension Diary {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Diary> {
        return NSFetchRequest<Diary>(entityName: "Diary")
    }

    @NSManaged public var body: String?
    @NSManaged public var createdAt: Double
    @NSManaged public var title: String?
    @NSManaged public var weatherIcon: String?

}
