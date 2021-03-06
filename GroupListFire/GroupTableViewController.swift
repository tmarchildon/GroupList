//
//  GroupTableViewController.swift
//  GroupListFire
//
//  Created by Teddy Marchildon on 7/7/16.
//  Copyright © 2016 Teddy Marchildon. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import FBSDKCoreKit
import FirebaseAuth

protocol FirebaseDelegation {
    func didFetchData<T: SequenceType>(data: T, toMatch: String?)
}

class GroupTableViewController: UITableViewController, FirebaseDelegation {
    
    var myUserRef: FIRDatabaseReference? = nil
    var myGroupRef: FIRDatabaseReference? = nil
    var userGroups: [Group] = []
    let user = FIRAuth.auth()?.currentUser
    var userReference: String!
    var names: [String] = []
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle)
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        self.clearsSelectionOnViewWillAppear = true
        self.userReference = ErrorAlerts.getUserReferenceType(self.user!)
        myUserRef = FIRDatabase.database().referenceFromURL("https://grouplistfire-39d22.firebaseio.com/").child("users").child("\(userReference)-\(user!.uid)")
        myGroupRef = FIRDatabase.database().referenceFromURL("https://grouplistfire-39d22.firebaseio.com/").child("groups")
        let ref = myUserRef?.child("userGroups")
        ref?.observeEventType(.Value, withBlock: { snapshot in
            var newNames: [String] = []
            for item in snapshot.children {
                if let item = item as? FIRDataSnapshot {
                    let postDict = item.value as! [String: String]
                    newNames.append(postDict["name"]!)
                }
            }
            self.didFetchData(newNames, toMatch: nil)
        })
    }
    
    func didFetchData<T: SequenceType>(data: T, toMatch: String?) {
        if let data = data as? [String] {
            self.userGroups = []
            for item in data {
                self.myGroupRef?.child(item).observeSingleEventOfType(.Value, withBlock: { snapshot in
                    let newGroup = Group(snapshot: snapshot)
                    self.userGroups.append(newGroup)
                    self.tableView.reloadData()
                })
            }
        }
    }
    
    @IBAction func addGroup(sender: AnyObject) {
        let alert = UIAlertController(title: "New Group", message: nil, preferredStyle: .Alert)
        let saveAction = UIAlertAction(title: "Save", style: .Default) { (action: UIAlertAction!) -> Void in
            let nameField = alert.textFields![0]
            let topicField = alert.textFields![1]
            if ErrorAlerts.containsInvalidCharacters(nameField.text!) || ErrorAlerts.containsInvalidCharacters(topicField.text!) {
                let malTextAlert = ErrorAlerts.invalidTextEntered("Name and Topic may not contain the following characters: $ # / [ ] . -")
                self.presentViewController(malTextAlert, animated: true, completion: nil)
                return
            } else {
                let group = Group(withName: nameField.text!, andTopic: topicField.text!, andList: List(), createdBy: self.userReference, andUser: self.user!)
                group.addToRefs(self.user!)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
        alert.addTextFieldWithConfigurationHandler { (textGroup) -> Void in
            textGroup.placeholder = "Group Name"
            textGroup.clearButtonMode = UITextFieldViewMode.WhileEditing
        }
        alert.addTextFieldWithConfigurationHandler { (textTopic) -> Void in
            textTopic.placeholder = "Group Topic"
            textTopic.clearButtonMode = UITextFieldViewMode.WhileEditing
        }
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userGroups.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("groupCell", forIndexPath: indexPath) as! GroupTableViewCell
        cell.titleLabel.text = userGroups[indexPath.row].name
        cell.titleLabel.adjustsFontSizeToFitWidth = true
        cell.topicLabel.text = userGroups[indexPath.row].topic
        cell.topicLabel.adjustsFontSizeToFitWidth = true
        cell.usernameLabel.text = userGroups[indexPath.row].createdBy
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let group = userGroups[indexPath.row]
            self.userGroups.removeAtIndex(indexPath.row)
            group.updateRefsForDeletion(self.user!)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "listSegue" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let listController = segue.destinationViewController as! ListTableViewController
                listController.currGroup = userGroups[indexPath.row]
                listController.currGroupObject = userGroups[indexPath.row].toAnyObject()
                listController.title = "\(userGroups[indexPath.row].name) list"
            }
        }
    }
}
