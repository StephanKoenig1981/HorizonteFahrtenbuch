//
//  pastRidesTableViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 24.04.23.
//

import UIKit
import RealmSwift


class pastRidesTableViewController: UITableViewController {
    
    // MARK: Initializing Realm
    
    let realm = try! Realm()
    let results = try! Realm().objects(currentRide.self).sorted(byKeyPath: "date", ascending: true)
    
    var notificationToken: NotificationToken?
    
    // MARK: Variables
    
    // Section Headers; we need 3 arrays
    var sectionHeaderTitles = [String]()  // string array of section headers
    let dateFormatter = DateFormatter() // Needed to extract the Year from Publication Date
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        
        setupUI()
        
        tableView.rowHeight = 86 // same as storyboard, but better to declare it here too
    
        
        // Set results notification block
        self.notificationToken = results.observe { (changes: RealmCollectionChange) in
            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                self.tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the TableView
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                self.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                self.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                self.tableView.endUpdates()
            case .error(let err):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(err)")
            }
        }
    }
    
    // MARK: Setting Up User Interface
        func setupUI() {
            tableView.register(Cell.self, forCellReuseIdentifier: "ridesCell")

            self.title = "Abgeschlossene Fahrten"
            
            tableView.rowHeight = 86.0
        }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = realm.objects(currentRide.self).count
        
        return count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ridesCell", for: indexPath)
        
        let object = results[indexPath.row]
        cell.textLabel?.font.withSize(80)
        cell.textLabel?.text = object.date
        cell.detailTextLabel?.font.withSize(15)
        cell.detailTextLabel?.text = object.timeElapsed?.description
        cell.textLabel?.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        
        // Adding the disclosure Indicator Currently inactive for later purposes
        
        // cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator


        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                realm.beginWrite()
                realm.delete(results[indexPath.row])
                try! realm.commitWrite()
            }
        }
    
    // MARK: Method for the Section Indicators

    /*override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Fahrten"
    }*/

}
