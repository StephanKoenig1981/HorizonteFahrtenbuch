//
//  contactsTableViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 23.04.23.
//

import UIKit
import RealmSwift
import CoreLocation

protocol ContactSelectionDelegate: AnyObject {
    func didSelectContact(clientName: String, phoneNumber: String, street: String, city: String, postalCode: String)
}


class contactsTableViewController: UITableViewController, UISearchBarDelegate, CLLocationManagerDelegate {
    
    weak var delegate: ContactSelectionDelegate?
    
    
    // MARK: Outlets
    
    @IBOutlet var clientTableView: UITableView!
    
    @IBOutlet weak var clientSearchBar: UISearchBar!
    
    // MARK: Initializing Realm
    
    let realm = try! Realm()
    let results = try! Realm().objects(clients.self).sorted(byKeyPath: "client")
    var notificationToken: NotificationToken?
    
    var hasData: Bool = false
    let placeholderLabel = UILabel()
    
    // MARK: Array for filtered data and deinitialization of Notifications
    
    var filteredResults: Results<clients>!
    
    deinit {
        notificationToken?.invalidate()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fix color for UISearchBar
        
        if let textfield = clientSearchBar.value(forKey: "searchField") as? UITextField {
            textfield.attributedPlaceholder = NSAttributedString(string: textfield.placeholder ?? "", attributes: [NSAttributedString.Key.foregroundColor : UIColor.lightGray])
            
            if let leftView = textfield.leftView as? UIImageView {
                leftView.image = leftView.image?.withRenderingMode(.alwaysTemplate)
                leftView.tintColor = UIColor.lightGray
            }
        }
        
        clientSearchBar.overrideUserInterfaceStyle = .dark
        
        // MARK: Tap Recoginzer
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard(_:)))
        tableView.addGestureRecognizer(tapGesture)
        
        // Initialize filteredResults with all objects sorted alphabetically
        filteredResults = realm.objects(clients.self).sorted(byKeyPath: "client", ascending: true)
        
        // Register for changes in Realm Notifications
        
        clientSearchBar.delegate = self
        clientTableView.delegate = self
        clientTableView.dataSource = self
        
        setupUI()
        
        clientTableView.rowHeight = 225 // same as storyboard, but better to declare it here too
        
        // MARK: Setting placeholder text for the tableView being empty
        
        placeholderLabel.text = "Es wurden noch keine Kontakte gespeichert."
        placeholderLabel.textAlignment = .center
        placeholderLabel.textColor = .gray
        clientTableView.backgroundView = placeholderLabel
    }
    
    // MARK: Setting Up User Interface
        func setupUI() {
            clientTableView.register(clientsTableViewCell.self, forCellReuseIdentifier: "clientCell")

            self.title = "Kunden"
        }
    
    // MARK: Filter Data Function
    
    func filterResults(searchTerm: String) {
        if searchTerm.isEmpty {
            // Output all elements sorted alphabetically in a case-insensitive manner
            filteredResults = realm.objects(clients.self).sorted(byKeyPath: "client", ascending: true)
        } else {
            // Filter and output selected elements
            let unsortedFilteredResults = realm.objects(clients.self)
                .filter("client CONTAINS[c] %@ OR street CONTAINS[c] %@", searchTerm, searchTerm)
            
            // Sort the filtered results alphabetically by the 'client' property
            filteredResults = unsortedFilteredResults.sorted(byKeyPath: "client", ascending: true)
        }
        
        // Log the sorted results
        print("Sorted filteredResults: \(filteredResults)")
        
        // Reload data after updating filtered results
        tableView.reloadData()
    }

    
    override func viewWillAppear(_ animated: Bool) {
            // Add a background view to the table view
              let backgroundImage = UIImage(named: "purpleGradient.png")
              let imageView = UIImageView(image: backgroundImage)
              self.tableView.backgroundView = imageView
        }


    // MARK: Define the number of rows beeing presented

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return filteredResults?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = clientTableView.dequeueReusableCell(withIdentifier: "customClientCell", for: indexPath) as! clientsTableViewCell
        
        guard indexPath.row < filteredResults.count else {
            // Handle case where indexPath is out of bounds
            return cell
        }
        
        let object = filteredResults[indexPath.row]
        
        cell.clientNameLabel?.text = object.client?.description
        cell.clientsContactPersonLabel?.text = object.clientContactPerson?.description
        cell.clientStreetLabel?.text = object.street?.description
        cell.clientPostalCodeLabel?.text = object.postalCode?.description
        cell.clientCityLabel?.text = object.city?.description
        
        cell.clientPhoneLabel?.text = object.phone?.description
        
        cell.clientNameLabel.textColor = UIColor(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        
        // Action for making a phone call
        cell.buttonPressed = {
            guard let phone = object.phone, let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) else {
                return
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            print("phoneButton at Index", indexPath)
        }
        
        // Action for Map Button
        cell.routeButtonPressed = {
            print("mapButtonPressed at Index", indexPath)
            let detailVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "clientDetailViewController") as! clientDetailViewController
            
            if let street = object.street?.description, let city = object.city?.description {
                var address = "\(street), \(city)"
                let name = object.client?.description ?? ""
                
                self.getLocationFromAddress(address: address) { (location, error) in
                    guard let location = location else {
                        return
                    }
                    detailVC.latitude = location.latitude
                    detailVC.longitude = location.longitude
                    detailVC.clientName = name
                    
                    self.navigationController?.pushViewController(detailVC, animated: true)
                }
            }
        }
        
        // Action for Start Ride Button Pressed
        cell.startRideButtonPressed = {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
            print("startRideButton pressed at Index", indexPath)
            
            if let clientName = object.client, let phoneNumber = object.phone, let street = object.street, let city = object.city, let postalCode = object.postalCode {
                let fullAddress = "\(street), \(postalCode) \(city)"
                print("Client Name: \(clientName), Phone: \(phoneNumber), Address: \(fullAddress)")
                
                let alertMessage = "Möchtest du wirklich diese Fahrt für \(clientName) starten? Adresse: \(fullAddress)"
                let alert = UIAlertController(title: "Fahrt starten?", message: alertMessage, preferredStyle: .actionSheet)
                
                let yesAction = UIAlertAction(title: "Ja", style: .default) { [weak self] _ in
                    self?.dismiss(animated: true) {
                        self?.delegate?.didSelectContact(clientName: clientName, phoneNumber: phoneNumber, street: street, city: city, postalCode: postalCode)
                    }
                }
                alert.addAction(yesAction)
                
                let noAction = UIAlertAction(title: "Abbrechen", style: .destructive, handler: nil)
                alert.addAction(noAction)
                
                self.present(alert, animated: true, completion: nil)
            } else {
                print("Client name, phone number, or address is missing")
            }
        }
        
        // Disabling the phone button if no phone number is in the contact details.
        if object.phone?.description == "" {
            cell.phoneButton.isEnabled = false
            cell.phoneButton.tintColor = .systemGray
            cell.phoneButton.overrideUserInterfaceStyle = .dark
        } else {
            cell.phoneButton.isEnabled = true
            cell.phoneButton.tintColor = .systemOrange
        }
        
        // Generate Address
        let street = object.street?.description
        let city = object.city?.description ?? ""
        let address = "\(street), \(city)"
        
        // Check if the TableView is provided with data, else show placeholder text.
        if !hasData {
            placeholderLabel.isHidden = true
        } else {
            placeholderLabel.isHidden = false
        }
        
        return cell
    }


    // MARK: Delete contacts from tableView
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)

        // Create alert controller to confirm deletion
        let alertController = UIAlertController(title: "Kundeneintrag löschen", message: "Bist du sicher, dass du den Kundeneintrag löschen möchtest?", preferredStyle: .actionSheet)
        
        // Add cancel action to alert controller
        let cancelAction = UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // Add delete action to alert controller
        let deleteAction = UIAlertAction(title: "Löschen", style: .destructive) { (action) in
            // Ensure the index path is valid
            guard indexPath.row < self.filteredResults.count else { return }
            
            // Delete the corresponding object from the data source
            let objectToDelete = self.filteredResults[indexPath.row]
            try! self.realm.write {
                self.realm.delete(objectToDelete)
            }
            
            // Animate the deletion on the table view
            tableView.deleteRows(at: [indexPath], with: .automatic)
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
            filteredResults = realm.objects(clients.self)
                .sorted(byKeyPath: "client", ascending: true)
        } else {
            filterResults(searchTerm: searchText)
        }
        
        // Reload the table view to reflect the changes
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        clientSearchBar.resignFirstResponder()
    }
    
    // MARK: Geocoding Address
    
    func getLocationFromAddress(address: String, completionHandler: @escaping (CLLocationCoordinate2D?, NSError?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            if error == nil {
                if let placemark = placemarks?[0] {
                    let location = placemark.location!
                    completionHandler(location.coordinate, nil)
                }
            } else {
                completionHandler(nil, error as NSError?)
            }
        }
    }
    
    
    
    // MARK: Action for selecting client
    
    @IBAction func phoneButtonPressed(_ sender: Any) {
       
    }
    
    @IBAction func routeButtonPressed(_ sender: Any) {
        
    }
}
