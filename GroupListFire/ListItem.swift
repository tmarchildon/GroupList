//
//  ListItem.swift
//  GroupListFire
//
//  Created by Teddy Marchildon on 7/9/16.
//  Copyright © 2016 Teddy Marchildon. All rights reserved.
//

import Foundation
import Firebase

class ListItem {
    
    var name: String
    var quantity: String
    var completed: Bool = false
    var groupRef: FIRDatabaseReference?
    var createdBy: String
    var assignedTo: String?
    var timeFrame: String?
    var group: String
    
    convenience init(withName name: String, andQuantity quantity: String, createdBy: String, timeFrame: String?, group: Group) {
        self.init(withName: name, andQuantity: quantity, completed: false, groupRef: nil, createdBy: createdBy, assignedTo: nil, timeFrame: timeFrame, group: group)
    }
    init(withName name: String, andQuantity quantity: String, completed: Bool, groupRef: FIRDatabaseReference?, createdBy: String, assignedTo: String?, timeFrame: String?, group: String) {
        self.name = name
        self.quantity = quantity
        self.completed = completed
        self.groupRef = groupRef
        self.createdBy = createdBy
        self.assignedTo = assignedTo
        self.timeFrame = timeFrame
        self.group = group
    }

    init(withName name: String, andQuantity quantity: String, completed: Bool, groupRef: FIRDatabaseReference?, createdBy: String, assignedTo: String?, timeFrame: String?, group: Group) {
        self.name = name
        self.quantity = quantity
        self.completed = completed
        self.groupRef = groupRef
        self.createdBy = createdBy
        self.assignedTo = assignedTo
        self.timeFrame = timeFrame
        self.group = "\(group.createdBy)-\(group.name)-\(group.topic)"
    }
    
    init(snapshot: FIRDataSnapshot) {
        let postDict = snapshot.value as! [String: AnyObject]
        self.name = postDict["name"] as! String
        self.quantity = postDict["quantity"] as! String
        self.completed = postDict["completed"] as! Bool
        self.groupRef = snapshot.ref
        self.createdBy = postDict["createdBy"] as! String
        self.group = postDict["group"] as! String
        if let assignedTo = postDict["assignedTo"] as? String {
            self.assignedTo = assignedTo
        } else { self.assignedTo = nil }
        if let timeFrame = postDict["timeFrame"] as? String {
            self.timeFrame = timeFrame
        } else { self.timeFrame = nil }
    }
    
    func toAnyObject() -> [String: AnyObject]{
        var retDict: [String: AnyObject] = [:]
        retDict["name"] = name
        retDict["quantity"] = quantity
        retDict["completed"] = completed
        retDict["createdBy"] = createdBy
        retDict["group"] = group
        if let assignedTo = assignedTo {
            retDict["assignedTo"] = assignedTo
        }
        if let timeFrame = timeFrame {
            retDict["timeFrame"] = timeFrame
        }
        return retDict
    }
}