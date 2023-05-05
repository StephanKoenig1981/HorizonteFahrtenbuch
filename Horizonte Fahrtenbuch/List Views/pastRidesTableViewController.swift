//
//  pastRidesTableViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 24.04.23.
//

import UIKit
import RealmSwift


class pastRidesTableViewController: UITableViewController {
    
    @IBOutlet var pastRidesTableView: UITableView!
    @IBOutlet var pastRidesSearchBar: UITableView!
    
    // MARK: Initializing Realm
    
    let realm = try! Realm()
    let results = try! Realm().objects(currentRide.self).sorted(byKeyPath: "date", ascending: false)
    
    var notificationToken: NotificationToken?
    
    // MARK: Variables
    
    let dateFormatter = DateFormatter() // Needed to extract the Year from Publication Date
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        }
        
        
        let vc = UIViewController()
        vc.presentationController?.presentedView?.gestureRecognizers?[0].isEnabled = false
        
        
        setupUI()
        
        pastRidesTableView.rowHeight = 144
        
        
        // Set results notification block
        self.notificationToken = results.observe { (changes: RealmCollectionChange) in
            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                self.pastRidesTableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the TableView
                
                self.pastRidesTableView.beginUpdates()
                self.pastRidesTableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                self.pastRidesTableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                self.pastRidesTableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                self.pastRidesTableView.endUpdates()
                
                /*let topIndexPath = IndexPath(row: 0, section: 0)
                 self.pastRidesTableView.insertRows(at: [topIndexPath], with: .automatic)*/
                
            case .error(let err):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(err)")
            }
        }
    }
    
    // MARK: Setting Up User Interface
    func setupUI() {
        pastRidesTableView.register(pastRidesTableViewCell.self, forCellReuseIdentifier: "latestRideCell")
        
        self.title = "Abgeschlossene Fahrten"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = realm.objects(currentRide.self).count
        
        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = pastRidesTableView.dequeueReusableCell(withIdentifier: "latestRidesCell", for: indexPath) as! pastRidesTableViewCell
        
        let object = results[indexPath.row]
       
        
        cell.date?.text = object.date?.description
        
        
        
        cell.durationLabel?.text = object.timeElapsed?.description
        cell.distanceLabel?.text = object.distanceDriven?.description
        cell.supplementDateLabel?.text = object.supplementDate?.description
        
        if object.currentClientName?.description == "" {
            cell.rideClientLabel?.text = "Keine Angabe"
            cell.rideClientLabel?.textColor = UIColor.systemBlue
        } else {
    
            cell.rideClientLabel?.text = object.currentClientName?.description
            cell.rideClientLabel?.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
}
       
        
        // Adding the disclosure Indicator Currently inactive for later purposes
        
        // cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        
        // Disabling the map supplement Button if no phone number is in the contact details.
        
        if object.isManuallySaved == false {
            cell.circleSign.isHidden = true
            cell.supplementDateLabel.isHidden = true
            cell.circleSign.isUserInteractionEnabled = false
            
        
            
        } else if object.isManuallySaved == true{
            cell.circleSign.isHidden = false
            cell.supplementDateLabel.isHidden = false
            cell.circleSign.isUserInteractionEnabled = false
            
            
            
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
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
