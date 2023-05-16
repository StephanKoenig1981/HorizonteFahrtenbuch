//
//  pastRidesTableViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 24.04.23.
//

import UIKit
import RealmSwift


class pastRidesTableViewController: UITableViewController, UISearchBarDelegate {
    
    @IBOutlet var pastRidesTableView: UITableView!
    @IBOutlet var pastRidesSearchBar: UITableView!
    
    // MARK: Initializing Realm
    
    let realm = try! Realm()
    let results = try! Realm().objects(currentRide.self).sorted(byKeyPath: "date", ascending: false)
    
    var notificationToken: NotificationToken?
    
    // MARK: Array for filtered data and deinitialization of Notifications
    
    var filteredResults: Results<currentRide>!
    
    deinit {
        notificationToken?.invalidate()
    }
    
    // MARK: Variables
    
    let dateFormatter = DateFormatter() // Needed to extract the Year from Publication Date
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: Tap Recoginzer
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard(_:)))
            tableView.addGestureRecognizer(tapGesture)
        
        
        filteredResults = realm.objects(currentRide.self)   // <-- initialize Filtered Results
        // Register for changes in Realm Notifications
        
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        }
        
        
        let vc = UIViewController()
        vc.presentationController?.presentedView?.gestureRecognizers?[0].isEnabled = false
        
        let objects = realm.objects(currentRide.self)
        var filteredData = objects // Initally, the filtered data is the same as the original data.
        
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
            case .error(let err):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(err)")
            }
        }
        
        
        setupUI()
        
        pastRidesSearchBar.delegate = self
        pastRidesTableView.delegate = self
        pastRidesTableView.dataSource = self
        
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
    
    // MARK: Filter Data Function
    
    func filterResults(searchTerm: String) {
            if searchTerm.isEmpty {
                // Ausgabe aller Elemente wird auch sortiert
                filteredResults = realm.objects(currentRide.self).sorted(byKeyPath: "date", ascending: true)
            } else {
                // Nur ausgewählte Elemente werden sortiert
                filteredResults = realm.objects(currentRide.self)
                filteredResults = filteredResults.filter("currentClientName CONTAINS[c] %@", searchTerm)
                filteredResults = filteredResults.sorted(byKeyPath: "date", ascending: true)
            }
            tableView.reloadData()
    }
    
    // MARK: Define the number of rows beeing presented
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return filteredResults?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = pastRidesTableView.dequeueReusableCell(withIdentifier: "latestRidesCell", for: indexPath) as! pastRidesTableViewCell
        
        dateFormatter.locale = Locale(identifier: "de_DE") // Setzen Sie hier Ihr gewünschtes lokale und Zeitzone
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "dd.MM.yyyy"

        let objects = filteredResults.sorted {
            guard let firstDate = dateFormatter.date(from: $0.date!),
                  let secondDate = dateFormatter.date(from: $1.date!) else {
                      return false
                  }
            return firstDate > secondDate
        }

        
        let object = filteredResults[indexPath.row]
        
       
        
        cell.date?.text = object.date?.description
        
        
        
        cell.durationLabel?.text = object.timeElapsed?.description
        cell.distanceLabel?.text = object.distanceDriven?.description
        cell.supplementDateLabel?.text = object.supplementDate?.description
        
        if object.currentClientName?.description == "" {
            cell.rideClientLabel?.text = "Keine Angabe"
            cell.rideClientLabel?.textColor = UIColor.systemBlue
        } else {
    
            cell.rideClientLabel?.text = object.currentClientName?.description
            cell.rideClientLabel?.textColor = .systemOrange
            cell.date?.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
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
        
        cell.routeDetailButtonPressed = {
            
            print ("routeButton pressed at Index", indexPath)
            let detailVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "routeDetailViewController") as! routeDetailViewController
            
            // Pass the encodedPolyline object to the detailVC
            
            let realm = try! Realm()
            let currentRide = realm.objects(currentRide.self)[indexPath.row]

            detailVC.encodedPolyline = currentRide.encodedPolyline

            
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
        
        let data = filteredResults![indexPath.row]
        cell.configure(data: data)

        return cell
    }
    
    @objc func hideKeyboard(_ sender: UITapGestureRecognizer) {
        tableView.endEditing(true)
    }
    
    
    // MARK: SearchBar Function
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredResults = realm.objects(currentRide.self)
            tableView.reloadData()
        } else {
            filterResults(searchTerm: searchText)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        pastRidesSearchBar.resignFirstResponder()
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
