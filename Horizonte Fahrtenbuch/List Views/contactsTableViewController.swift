//
//  contactsTableViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 23.04.23.
//

import UIKit
import RealmSwift
import CoreLocation


class contactsTableViewController: UITableViewController, UISearchBarDelegate, CLLocationManagerDelegate {
    
    
    // MARK: Outlets
    
    @IBOutlet var clientTableView: UITableView!
    
    @IBOutlet weak var clientSearchBar: UISearchBar!
    
    // MARK: Initializing Realm
    
    let realm = try! Realm()
    let results = try! Realm().objects(clients.self).sorted(byKeyPath: "client")
    var notificationToken: NotificationToken?
    
    // MARK: Array for filtered data and deinitialization of Notifications
    
    var filteredResults: Results<clients>!
    
    deinit {
        notificationToken?.invalidate()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // MARK: Tap Recoginzer
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard(_:)))
            tableView.addGestureRecognizer(tapGesture)
        
        
        filteredResults = realm.objects(clients.self)   // <-- initialize Filtered Results
        // Register for changes in Realm Notifications
       
            
        
        
        clientSearchBar.delegate = self
        clientTableView.delegate = self
        clientTableView.dataSource = self
        
        setupUI()
        
        let objects = realm.objects(clients.self)
        var filteredData = objects // Initally, the filtered data is the same as the original data.
        
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
    
    // MARK: Filter Data Function
    
    func filterResults(searchTerm: String) {
                if searchTerm.isEmpty {
                    // Ausgabe aller Elemente wird alphabetisch sortiert.
                    filteredResults = realm.objects(clients.self).sorted(byKeyPath: "client", ascending: true)
                } else {
                    // Nur ausgewählte Elemente werden alphabetisch sortiert
                    filteredResults = realm.objects(clients.self)
                    filteredResults = filteredResults.filter("client CONTAINS[c] %@ OR street CONTAINS[c] %@", searchTerm, searchTerm)
                    filteredResults = filteredResults.sorted(byKeyPath: "client", ascending: true)
                }
                tableView.reloadData()
        }


    // MARK: Define the number of rows beeing presented

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return filteredResults?.count ?? 0
    }
    
    // MARK: Sort Entries alphabetically

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell  =  clientTableView.dequeueReusableCell(withIdentifier: "customClientCell", for: indexPath) as! clientsTableViewCell
           
           let object = filteredResults.sorted(byKeyPath: "client", ascending: true)[indexPath.row]
           
           cell.clientNameLabel?.text = object.client?.description
           cell.clientsContactPersonLabel?.text = object.clientContactPerson?.description
           cell.clientStreetLabel?.text = object.street?.description
           cell.clientPostalCodeLabel?.text = object.postalCode?.description
           cell.clientCityLabel?.text = object.city?.description
           
           cell.clientPhoneLabel?.text = object.phone?.description
           
           cell.clientNameLabel.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        
        
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
            let detailVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "clientDetailViewController") as! clientDetailViewController
            
            let realm = try! Realm()
            let objects: Results<clients> = realm.objects(clients.self).sorted(byKeyPath: "client", ascending: true)
            
            // Get the client for the selected row
            guard indexPath.row < objects.count else {
                return
            }
            let selectedClient = self.filteredResults.sorted(byKeyPath: "client", ascending: true)[indexPath.row]
            
            // Get the address and name for the selected client
            if let street = selectedClient.street?.description, let city = selectedClient.city?.description {
                // Construct the address as correctly as possible
                var address = ""
                if let zipCode = selectedClient.postalCode?.description {
                    address = "\(street), \(zipCode) \(city)"
                } else {
                    address = "\(street), \(city)"
                }
                let name = selectedClient.client?.description ?? ""
                
                // Use the selected address to get the location and assign it to the appropriate client detail view controller
                self.getLocationFromAddress(address: address) { (location, error) in
                    guard let location = location else {
                        return
                    }
                    detailVC.latitude = location.latitude
                    detailVC.longitude = location.longitude
                    detailVC.clientName = name // set the name of the client in the detailVC
                    
                    // Find the index of the selected client and display their address in the console
                    if let index = objects.index(matching: NSPredicate(format: "uniqueKey = %@", selectedClient.uniqueKey)) {
                        print("Selected client address: \(address), Index: \(index)")
                        print(objects)
                    }
                    
                    self.navigationController?.pushViewController(detailVC, animated: true)
                }
            }
        }


    
        // Disabling the phone button if no phone number is in the contact details.
        
        if object.phone?.description == "" {
            cell.phoneButton.isEnabled = false
            cell.phoneButton.tintColor = .systemGray
        } else {
            cell.phoneButton.isEnabled = true
            cell.phoneButton.tintColor = .systemOrange
        }
        
        // Generate Adress
        
        let street = object.street?.description
        let city = object.city?.description ?? "" // Hier wird eine leere Zeichenfolge verwendet, wenn das Objekt keinen City-Wert hat.
        let address = "\(street), \(city)"
        
        // Sorting Data
        
        let data = filteredResults[indexPath.row]
        cell.configure(data: data)

        return cell
    }

    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        clientTableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    }
    
    @objc func hideKeyboard(_ sender: UITapGestureRecognizer) {
        tableView.endEditing(true)
    }
    
    
    // MARK: SearchBar Function
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredResults = realm.objects(clients.self)
            tableView.reloadData()
        } else {
            filterResults(searchTerm: searchText)
        }
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
