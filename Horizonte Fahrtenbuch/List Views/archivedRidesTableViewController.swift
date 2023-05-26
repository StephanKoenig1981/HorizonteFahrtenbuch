//
//  archivedRidesTableViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 24.04.23.
//

import UIKit
import RealmSwift


class archivedRidesTableViewController: UITableViewController, UISearchBarDelegate {
    
    @IBOutlet weak var archivedRidesSearchBar: UISearchBar!
    @IBOutlet var archivedRidesTableView: UITableView!
    
    // MARK: Initializing Realm
    
    let realm = try! Realm()
    let results = try! Realm().objects(archivedRides.self).sorted(byKeyPath: "date", ascending: false)
    
    var notificationToken: NotificationToken?
    
    // MARK: Array for filtered data and deinitialization of Notifications
    
    var filteredResults: Results<archivedRides>!
    var hasData: Bool = false
    let placeholderLabel = UILabel()
    
    deinit {
        notificationToken?.invalidate()
    }
    
    // MARK: Variables
    
    let dateFormatter = DateFormatter() // Needed to extract the Year from Publication Date
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Archivierte Fahrten"
        filteredResults = realm.objects(archivedRides.self)   // <-- initialize Filtered Results
        // Register for changes in Realm Notifications
        
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        }
        
        
        let vc = UIViewController()
        vc.presentationController?.presentedView?.gestureRecognizers?[0].isEnabled = false
        
        let objects = realm.objects(currentRide.self)
        var filteredData = objects // Initally, the filtered data is the same as the original data.
        
        setupUI()
        
        archivedRidesSearchBar.delegate = self
        archivedRidesTableView.delegate = self
        archivedRidesTableView.dataSource = self
        
        archivedRidesTableView.rowHeight = 144
        
        // MARK: Setting placeholder text for the tableView beeing empty
        
        placeholderLabel.text = "Es wurden noch keine Fahrten aufgezeichnet."
        placeholderLabel.textAlignment = .center
        placeholderLabel.textColor = .gray
        archivedRidesTableView.backgroundView = placeholderLabel
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Add a background view to the table view
          let backgroundImage = UIImage(named: "purpleGradient.png")
          let imageView = UIImageView(image: backgroundImage)
          self.tableView.backgroundView = imageView
    }
    
    // MARK: Setting Up User Interface
    func setupUI() {
        archivedRidesTableView.register(archivedRidesTableviewCell.self, forCellReuseIdentifier: "archiveRidesCell")
        
        // Get the current month name and year
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        let monthName = dateFormatter.string(from: Date())
        
        self.title = monthName
    }
    
    // MARK: Filter Data Function
    
    func filterResults(searchTerm: String) {
        if searchTerm.isEmpty {
            // Ausgabe aller Elemente wird auch sortiert
            filteredResults = realm.objects(archivedRides.self).sorted(byKeyPath: "date", ascending: true)
        } else {
            // Nur ausgewählte Elemente werden sortiert
            filteredResults = realm.objects(archivedRides.self)
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
        let cell = archivedRidesTableView.dequeueReusableCell(withIdentifier: "archivedRidesCell", for: indexPath) as! archivedRidesTableviewCell
        
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
    
    // Disabling the routeDetailButton button if no phone number is in the contact details.
    
    if object.isManuallySaved == true {
        cell.routeDetailButton.isEnabled = false
        cell.routeDetailButton.tintColor = .systemGray
    } else {
        cell.routeDetailButton.isEnabled = true
        cell.routeDetailButton.tintColor = .systemOrange
    }
    
    cell.routeDetailButtonPressed = { [weak self] in
      guard let self = self else { return }
      print ("routeButton pressed at Index", indexPath)

      let detailVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "routeDetailViewController") as! routeDetailViewController
        
      // Determine the index path of the selected cell within the filtered results
      let filteredIndex = indexPath.row
      // Use the filtered index path to obtain the currentRide object from the filtered results
      let currentRide = self.filteredResults[filteredIndex]
      detailVC.encodedPolyline = currentRide.encodedPolyline
      detailVC.clientName = currentRide.currentClientName
      detailVC.timeElapsed = currentRide.timeElapsed
      detailVC.distanceDriven = currentRide.distanceDriven
         
      self.navigationController?.pushViewController(detailVC, animated: true)
    }
    
    if !hasData {
           placeholderLabel.isHidden = true
    } else {
        placeholderLabel.isHidden = false
    }
    
    let data = filteredResults![indexPath.row]
    cell.configure(data: data)

    return cell
}
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }

        // Create alert controller to confirm deletion
        let alertController = UIAlertController(title: "Fahrteneintrag löschen", message: "Bist du sicher, dass du den Fahrteneintrag löschen möchtest?", preferredStyle: .actionSheet)
        
        // Add cancel action to alert controller
        let cancelAction = UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // Add delete action to alert controller
        let deleteAction = UIAlertAction(title: "Löschen", style: .destructive) { (action) in
            // Delete the corresponding object from the data source
            let objectToDelete = self.filteredResults[indexPath.row]
            try! self.realm.write {
                self.realm.delete(objectToDelete)
            }
            
            // Animate the deletion on the table view
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.reloadData()
        }
        alertController.addAction(deleteAction)
        
        // Present the alert controller
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func hideKeyboard(_ sender: UITapGestureRecognizer) {
        tableView.endEditing(true)
    }
    
    // MARK: SearchBar Function
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredResults = realm.objects(archivedRides.self)
            tableView.reloadData()
        } else {
            filterResults(searchTerm: searchText)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        archivedRidesSearchBar.resignFirstResponder()
    }
    @IBAction func doneButtonPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
