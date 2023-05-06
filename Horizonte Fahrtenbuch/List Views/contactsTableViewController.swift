//
//  contactsTableViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 23.04.23.
//

import UIKit
import RealmSwift


class contactsTableViewController: UITableViewController, UISearchBarDelegate {
    
    // MARK: Outlets
    
    @IBOutlet var clientTableView: UITableView!
    
    @IBOutlet weak var clientSearchBar: UISearchBar!
    
    // MARK: Initializing Realm
    
    let realm = try! Realm()
    let results = try! Realm().objects(clients.self).sorted(byKeyPath: "client")
        var notificationToken: NotificationToken?
    
    // MARK: Array for filtered Data
    
    var clientsFilterArray = [clients()]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        clientTableView.rowHeight = 225 // same as storyboard, but better to declare it here too
        
        // Set results notification block
        self.notificationToken = results.observe { (changes: RealmCollectionChange) in
            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                self.clientTableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the TableView
                self.clientTableView.beginUpdates()
                self.clientTableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                self.clientTableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                self.clientTableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                self.clientTableView.endUpdates()
            case .error(let err):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(err)")
            }
        }
    }
    
    // MARK: Setting Up User Interface
        func setupUI() {
            clientTableView.register(clientsTableViewCell.self, forCellReuseIdentifier: "clientCell")

            self.title = "Kunden"
        }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = realm.objects(clients.self).count
        
        return count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell  =  clientTableView.dequeueReusableCell(withIdentifier: "customClientCell", for: indexPath) as! clientsTableViewCell
        
        let object = results[indexPath.row]
        
        cell.clientNameLabel?.text = object.client?.description
        cell.clientsContactPersonLabel?.text = object.clientContactPerson?.description
        cell.clientStreetLabel?.text = object.street?.description
        cell.clientPostalCodeLabel?.text = object.postalCode?.description
        cell.clientCityLabel?.text = object.city?.description
        
        cell.clientPhoneLabel?.text = object.phone?.description
        
        cell.clientNameLabel.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        
        // Adding the disclosure Indicator
        
        // cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        
        // MARK: Action for making a phone call
        
           cell.buttonPressed = {
               
               guard let url = URL(string: "telprompt://\((object.phone?.description)!)"),
                   UIApplication.shared.canOpenURL(url) else {
                   return
               }
               UIApplication.shared.open(url, options: [:], completionHandler: nil)
                  print ("phoneButton at Index", indexPath)
                   }
        
        // MARK: Action for Map Button
        
        cell.routeButtonPressed = {
            print ("mapButtonPressed at Index", indexPath)
        }
    
        // Disabling the phone button if no phone number is in the contact details.
        
        if object.phone?.description == "" {
            cell.phoneButton.isEnabled = false
            cell.phoneButton.tintColor = .systemGray
        } else {
            cell.phoneButton.isEnabled = true
            cell.phoneButton.tintColor = .systemOrange
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                realm.beginWrite()
                realm.delete(results[indexPath.row])
                try! realm.commitWrite()
            }
        }
    
    // MARK: Action for selecting client
    
    @IBAction func phoneButtonPressed(_ sender: Any) {
       
    }
    
    @IBAction func routeButtonPressed(_ sender: Any) {
    
    }
}
