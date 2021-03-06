//
//  Group.swift
//  GroupListFire
//
//  Created by Teddy Marchildon on 7/7/16.
//  Copyright © 2016 Teddy Marchildon. All rights reserved.
//

import Foundation
import Firebase

class Group {
    
    var name: String
    var topic: String
    var list: List
    var ref: FIRDatabaseReference?
    var groupUsers: [String]
    var createdBy: String
    
    init(withName name: String, andTopic topic: String, andList list: List, createdBy: String, andUser user: FIRUser) {
        self.name = name
        self.topic = topic
        self.list = list
        self.ref = nil
        self.createdBy = createdBy
        let userReference = ErrorAlerts.getUserReferenceType(user)
        self.groupUsers = ["\(userReference)-\(user.uid)"]
    }
    
    init(snapshot: FIRDataSnapshot) {
        let fullName = snapshot.key.componentsSeparatedByString("-")
        let createdBy = fullName[0]
        let groupName = fullName[1]
        let topicName = fullName[2]
        self.createdBy = createdBy
        self.name = groupName
        self.topic = topicName
        self.ref = snapshot.ref
        var groupList: [ListItem] = []
        let postDict = snapshot.value! as? [String: AnyObject]
        if let items = postDict!["items"] as? [String: AnyObject] {
            for elem in items.keys {
                let dict = items[elem] as! [String: AnyObject]
                let completed = dict["completed"] as! Bool
                let name = dict["name"] as! String
                let quantity = dict["quantity"] as! String
                let createdBy = dict["createdBy"] as! String
                let timeFrame = dict["timeFrame"] as? String
                let assignedTo = dict["assignedTo"] as? String
                let group = dict["group"] as! String
                let newListItem = ListItem(withName: name, andQuantity: quantity, completed: completed, groupRef: snapshot.ref, createdBy: createdBy, assignedTo: assignedTo, timeFrame: timeFrame, group: group)
                groupList.append(newListItem)
            }
            self.list = List(list: groupList)
        } else {
            self.list = List()
        }
        if let users = postDict!["users"] as? [String] {
            self.groupUsers = users
        } else {
            self.groupUsers = []
        }
    }
    
    func toAnyObject() -> [String: AnyObject] {
        return ["name": name,
                "topic": topic,
                "list": list.items,
                "users": groupUsers,
                "createdByUser": createdBy]
    }
    
    func addItem(name: String, detail: String, timeFrame: String, byUser: FIRUser) {
        let ref = FIRDatabase.database().referenceFromURL("https://grouplistfire-39d22.firebaseio.com/")
        var newItem: ListItem
        if !name.isEmpty {
            if timeFrame.isEmpty {
                newItem = ListItem(withName: name, andQuantity: detail, createdBy: byUser, timeFrame: nil, group: self)
            } else {
                newItem = ListItem(withName: name, andQuantity: detail, createdBy: byUser, timeFrame: timeFrame, group: self)
            }
            self.list.items.append(newItem)
            ref.child("groups").child("\(self.createdBy)-\(self.name)-\(self.topic)").child("items").child(newItem.name).setValue(newItem.toAnyObject())
        }
    }
    
    func updateRefsForDeletion(fromUser: FIRUser) {
        let userReference = ErrorAlerts.getUserReferenceType(fromUser)
        let ref = FIRDatabase.database().referenceFromURL("https://grouplistfire-39d22.firebaseio.com/")
        var i = 0
        for user in self.groupUsers {
            if user == "\(userReference)-\(fromUser.uid)" {
                self.groupUsers.removeAtIndex(i)
            }
            i += 1
        }
        for item in self.list.items {
            if let assignedTo = item.assignedTo where assignedTo == "\(userReference)-\(fromUser.uid)" {
                    ref.child("users").child("\(userReference)-\(fromUser.uid)").child("assignedTo").child("\(item.group)-\(item.name)").removeValue()
                    item.assignedTo = nil
                    item.updateRefsOfItem()
            }
        }
        ref.child("users").child("\(userReference)-\(fromUser.uid)").child("userGroups").child("\(self.createdBy)-\(self.name)-\(self.topic)").removeValue()
        if self.groupUsers.isEmpty {
            ref.child("groups").child("\(self.createdBy)-\(self.name)-\(self.topic)").removeValue()
        } else {
            ref.child("groups").child("\(self.createdBy)-\(self.name)-\(self.topic)").child("users").setValue(self.groupUsers)
        }
    }
    
    func addToRefs(user: FIRUser) {
        let userReference = ErrorAlerts.getUserReferenceType(user)
        let ref = FIRDatabase.database().referenceFromURL("https://grouplistfire-39d22.firebaseio.com/")
        ref.child("groups").child("\(userReference)-\(self.name)-\(self.topic)").setValue(self.toAnyObject())
        ref.child("users").child("\(userReference)-\(user.uid)").child("userGroups").child("\(self.createdBy)-\(self.name)-\(self.topic)").setValue(["name": "\(userReference)-\(self.name)-\(self.topic)"])
    }
    
    func addUser(username: String, userID: String) {
        let ref = FIRDatabase.database().referenceFromURL("https://grouplistfire-39d22.firebaseio.com/")
        ref.child("users").child("\(username)-\(userID)").child("userGroups").child("\(self.createdBy)-\(self.name)-\(self.topic)").setValue(["name": "\(self.createdBy)-\(self.name)-\(self.topic)"])
        ref.child("groups").child("\(self.createdBy)-\(self.name)-\(self.topic)").child("users").setValue(self.groupUsers)
    }
}