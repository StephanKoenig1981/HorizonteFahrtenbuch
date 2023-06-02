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
    let results = try! Realm().objects(currentRide.self).sorted(byKeyPath: "dateActual", ascending: true)
    
    var notificationToken: NotificationToken?
    
    // MARK: Array for filtered data and deinitialization of Notifications
    
    var filteredResults: Results<currentRide>!
    var hasData: Bool = false
    let placeholderLabel = UILabel()
    
    deinit {
        notificationToken?.invalidate()
    }
    
    // MARK: Variables
    
    let dateFormatter = DateFormatter() // Needed to extract the Year from Publication Date
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fix color for UISearchbar
        
        if let textfield = pastRidesSearchBar.value(forKey: "searchField") as? UITextField {

            textfield.attributedPlaceholder = NSAttributedString(string: textfield.placeholder ?? "", attributes: [NSAttributedString.Key.foregroundColor : UIColor.lightGray])

            if let leftView = textfield.leftView as? UIImageView {
                leftView.image = leftView.image?.withRenderingMode(.alwaysTemplate)
                leftView.tintColor = UIColor.lightGray
            }
        }
        
        pastRidesSearchBar.overrideUserInterfaceStyle = .dark
        
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
        
        // If date is a string, you can convert it to a Date first
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let sortedObjects = filteredResults.sorted(by: { (obj1, obj2) -> Bool in
            guard let date1 = obj1.date, let date2 = obj2.date else { return false }
            guard let dateObj1 = dateFormatter.date(from: date1), let dateObj2 = dateFormatter.date(from: date2) else { return false }
            return dateObj1 < dateObj2
        })
        
        var filteredData = objects.sorted(byKeyPath: "dateActual", ascending: true) // Initally, the filtered data is the same as the original data.
        
        setupUI()
        
        pastRidesSearchBar.delegate = self
        pastRidesTableView.delegate = self
        pastRidesTableView.dataSource = self
        
        pastRidesTableView.rowHeight = 144
        
        // MARK: Setting placeholder text for the tableView beeing empty
        
        placeholderLabel.text = "Es wurden noch keine Fahrten aufgezeichnet."
        placeholderLabel.textAlignment = .center
        placeholderLabel.textColor = .gray
        pastRidesTableView.backgroundView = placeholderLabel
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Add a background view to the table view
          let backgroundImage = UIImage(named: "purpleGradient.png")
          let imageView = UIImageView(image: backgroundImage)
          self.tableView.backgroundView = imageView
    }
    
    // MARK: Setting Up User Interface
    func setupUI() {
        pastRidesTableView.register(pastRidesTableViewCell.self, forCellReuseIdentifier: "latestRideCell")
        
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
            filteredResults = realm.objects(currentRide.self).sorted(byKeyPath: "dateActual", ascending: true)
        } else {
            // Nur ausgewählte Elemente werden sortiert
            filteredResults = realm.objects(currentRide.self).sorted(byKeyPath: "dateActual", ascending: true)
            filteredResults = filteredResults.filter("currentClientName CONTAINS[c] %@", searchTerm)
            filteredResults = filteredResults.sorted(byKeyPath: "dateActual", ascending: true)
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
        
        let object = filteredResults.sorted(byKeyPath: "dateActual", ascending: true)[indexPath.row]
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "de_DE")
        dateFormatter.dateFormat = "d. MMMM yyyy"
        if let dateActual = object.dateActual {
            cell.date?.text = dateFormatter.string(from: dateActual)
        }
        
        
        
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
            cell.routeDetailButton.overrideUserInterfaceStyle = .dark
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
          let currentRide = self.filteredResults.sorted(byKeyPath: "dateActual", ascending: true)[filteredIndex]
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

        // Haptic Feedback
        
        let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
        
        // Create alert controller to confirm deletion
        let alertController = UIAlertController(title: "Fahrteneintrag löschen", message: "Bist du sicher, dass du den Fahrteneintrag löschen möchtest?", preferredStyle: .actionSheet)
        
        // Add cancel action to alert controller
        let cancelAction = UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // Add delete action to alert controller
        let deleteAction = UIAlertAction(title: "Löschen", style: .destructive) { (action) in
            // Delete the corresponding object from the data source
            let objectToDelete = self.filteredResults.sorted(byKeyPath: "dateActual", ascending: true)[indexPath.row]
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
