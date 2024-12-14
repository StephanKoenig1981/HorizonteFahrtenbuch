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
    
    @IBOutlet weak var addContactButton: UIBarButtonItem!
    @IBOutlet weak var clientSearchBar: UISearchBar!
    
    // MARK: Initializing Realm
    
    let realm = try! Realm()
    private var realmNotificationToken: NotificationToken?
    
    var hasData: Bool = false
    let placeholderLabel = UILabel()
    
    // MARK: Array for filtered data and deinitialization of Notifications
    
    private var filteredResults: [clients] = []
    private var cachedClients: [clients] = []
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var cellConfigurations: [IndexPath: [Any]] = [:]
    
    deinit {
        realmNotificationToken?.invalidate()
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupSearchBar()
        setupTableView()
        
        // Setup Realm notifications
        let clientResults = realm.objects(clients.self)
        realmNotificationToken = clientResults.observe { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .initial:
                self.cachedClients = Array(self.realm.objects(clients.self))
                    .sorted { ($0.client ?? "").localizedCaseInsensitiveCompare($1.client ?? "") == .orderedAscending }
                self.reloadData()
            case .update:
                self.cachedClients = Array(self.realm.objects(clients.self))
                    .sorted { ($0.client ?? "").localizedCaseInsensitiveCompare($1.client ?? "") == .orderedAscending }
                self.reloadData()
            case .error(let error):
                print("Error observing Realm changes: \(error)")
            }
        }
        
        // Initial data load
        reloadData()
    }
    
    private func setupUI() {
        self.title = "Kunden"
        
        // Setup placeholder
        placeholderLabel.text = "Es wurden noch keine Kontakte gespeichert."
        placeholderLabel.textAlignment = .center
        placeholderLabel.textColor = .gray
    }
    
    private func setupSearchBar() {
        clientSearchBar.delegate = self
        clientSearchBar.overrideUserInterfaceStyle = .dark
        
        if let textfield = clientSearchBar.value(forKey: "searchField") as? UITextField {
            textfield.attributedPlaceholder = NSAttributedString(
                string: textfield.placeholder ?? "",
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
            )
            
            if let leftView = textfield.leftView as? UIImageView {
                leftView.image = leftView.image?.withRenderingMode(.alwaysTemplate)
                leftView.tintColor = UIColor.lightGray
            }
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = Constants.rowHeight
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tableView.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set background
        let backgroundImage = UIImage(named: "purpleGradient.png")
        let imageView = UIImageView(image: backgroundImage)
        tableView.backgroundView = imageView
        
        // Always reload data when view appears
        reloadData()
    }
    
    private func reloadData() {
        // Use cached data instead of querying Realm every time
        let allClients = cachedClients
        
        if let searchText = clientSearchBar.text, !searchText.isEmpty {
            // Use more efficient string comparison
            let searchTextLower = searchText.lowercased()
            filteredResults = allClients.filter {
                ($0.client?.lowercased().contains(searchTextLower) ?? false) ||
                ($0.street?.lowercased().contains(searchTextLower) ?? false)
            }
        } else {
            filteredResults = allClients
        }
        
        placeholderLabel.isHidden = !filteredResults.isEmpty
        tableView.reloadData()
    }
    
    // MARK: Define the number of rows beeing presented

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return filteredResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = clientTableView.dequeueReusableCell(withIdentifier: "customClientCell", for: indexPath) as! clientsTableViewCell
        
        guard indexPath.row < filteredResults.count else { return cell }
        
        let object = filteredResults[indexPath.row]
        configureCell(cell, with: object, at: indexPath)
        
        return cell
    }


    // MARK: Delete contacts from tableView
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)

        // Create alert controller to confirm deletion
        let alertController = createDeleteAlert(for: indexPath)
        
        // Present the alert controller
        present(alertController, animated: true, completion: nil)
    }
    
    
    
    @objc func hideKeyboard(_ sender: UITapGestureRecognizer) {
        tableView.endEditing(true)
    }
    
    
    // MARK: SearchBar Function
    
    private var searchWorkItem: DispatchWorkItem?
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.reloadData()
        }
        searchWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        clientSearchBar.resignFirstResponder()
    }
    
    // MARK: Geocoding Address
    
    private enum ContactError: Error {
        case invalidAddress
        case geocodingFailed
        case missingClientData
    }
    
    private func getLocationFromAddress(address: String, completionHandler: @escaping (CLLocationCoordinate2D?, NSError?) -> Void) {
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
    
    private func createDeleteAlert(for indexPath: IndexPath) -> UIAlertController {
        let alertController = UIAlertController(
            title: "Kundeneintrag löschen",
            message: "Bist du sicher, dass du den Kundeneintrag löschen möchtest?",
            preferredStyle: .actionSheet
        )
        
        alertController.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
        alertController.addAction(createDeleteAction(for: indexPath))
        
        return alertController
    }
    
    private func createDeleteAction(for indexPath: IndexPath) -> UIAlertAction {
        return UIAlertAction(title: "Löschen", style: .destructive) { [weak self] _ in
            self?.deleteClient(at: indexPath)
        }
    }
    
    private func deleteClient(at indexPath: IndexPath) {
        guard indexPath.row < filteredResults.count else { return }
        
        let objectToDelete = filteredResults[indexPath.row]
        filteredResults.remove(at: indexPath.row)
        
        try! realm.write {
            realm.delete(objectToDelete)
        }
        
        tableView.deleteRows(at: [indexPath], with: .automatic)
        placeholderLabel.isHidden = !filteredResults.isEmpty
    }
    
    private func filterClients(_ clients: [clients], with searchText: String) -> [clients] {
        return clients.filter {
            ($0.client?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.street?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    private func provideFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    private func configureCell(_ cell: clientsTableViewCell, with client: clients, at indexPath: IndexPath) {
        cell.configure(with: client)
        
        cell.buttonPressed = { [weak self] in
            self?.handlePhoneCall(for: client)
        }
        
        cell.routeButtonPressed = { [weak self] in
            self?.handleRouteButton(for: client)
        }
        
        cell.startRideButtonPressed = { [weak self] in
            self?.handleStartRide(for: client)
        }
    }
    
    private func handlePhoneCall(for client: clients) {
        guard let phone = client.phone,
              let url = URL(string: "tel://\(phone)"),
              UIApplication.shared.canOpenURL(url) else { return }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    private func handleRouteButton(for client: clients) {
        print("mapButtonPressed")
        let detailVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "clientDetailViewController") as! clientDetailViewController
        
        if let street = client.street?.description, let city = client.city?.description {
            let address = "\(street), \(city)"
            let name = client.client?.description ?? ""
            
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
    
    private func handleStartRide(for client: clients) {
        provideFeedback(.error)
        
        print("startRideButton pressed")
        
        if let clientName = client.client,
           let phoneNumber = client.phone,
           let street = client.street,
           let city = client.city,
           let postalCode = client.postalCode {
            
            let fullAddress = "\(street), \(postalCode) \(city)"
            print("Client Name: \(clientName), Phone: \(phoneNumber), Address: \(fullAddress)")
            
            let alertMessage = "Möchtest du wirklich diese Fahrt für \(clientName) starten? Adresse: \(fullAddress)"
            let alert = UIAlertController(title: "Fahrt starten?", message: alertMessage, preferredStyle: .actionSheet)
            
            let yesAction = UIAlertAction(title: "Ja", style: .default) { [weak self] _ in
                self?.dismiss(animated: true) {
                    self?.delegate?.didSelectContact(clientName: clientName, 
                                                  phoneNumber: phoneNumber, 
                                                  street: street, 
                                                  city: city, 
                                                  postalCode: postalCode)
                }
            }
            alert.addAction(yesAction)
            
            let noAction = UIAlertAction(title: "Abbrechen", style: .destructive, handler: nil)
            alert.addAction(noAction)
            
            present(alert, animated: true, completion: nil)
        } else {
            print("Client name, phone number, or address is missing")
        }
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Clean up cell configurations when cells are no longer visible
        cellConfigurations.removeValue(forKey: indexPath)
    }
}

private enum Constants {
    static let rowHeight: CGFloat = 225.0
    static let greenColor = UIColor(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
    static let backgroundImageName = "purpleGradient.png"
    static let placeholderText = "Es wurden noch keine Kontakte gespeichert."
}

private extension clientsTableViewCell {
    func configure(with client: clients) {
        clientNameLabel?.text = client.client?.description
        clientsContactPersonLabel?.text = client.clientContactPerson?.description
        clientStreetLabel?.text = client.street?.description
        clientPostalCodeLabel?.text = client.postalCode?.description
        clientCityLabel?.text = client.city?.description
        clientPhoneLabel?.text = client.phone?.description
        
        clientNameLabel.textColor = Constants.greenColor
        
        // Configure phone button
        let hasPhone = !(client.phone?.description.isEmpty ?? true)
        phoneButton.isEnabled = hasPhone
        phoneButton.tintColor = hasPhone ? .systemOrange : .systemGray
        phoneButton.overrideUserInterfaceStyle = hasPhone ? .unspecified : .dark
    }
}
