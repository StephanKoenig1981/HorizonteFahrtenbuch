//
//  statsViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 20.05.23.
//

import UIKit
import RealmSwift
import MessageUI

class statsViewController: UIViewController, MFMailComposeViewControllerDelegate, UITableViewDelegate, UITableViewDataSource{
    
    
    @IBOutlet weak var totalTimeElapsedLabel: UILabel!
    @IBOutlet weak var totalDistanceDrivenLabel: UILabel!
    
    @IBOutlet weak var upperCellBackgroundView: UIImageView!
    @IBOutlet weak var closeMonthButton: UIButton!
    @IBOutlet weak var pastMonthsSummaryTableView: UITableView!
    
    @IBOutlet weak var sendReportButton: UIButton!
    
    var hasData: Bool = false
    let placeholderLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: Setting Delegates
        
        pastMonthsSummaryTableView.delegate = self
        pastMonthsSummaryTableView.dataSource = self
        
        // MARK: Customizing UI
        
        pastMonthsSummaryTableView.backgroundColor = UIColor.clear
        pastMonthsSummaryTableView.rowHeight = 80
        upperCellBackgroundView.layer.cornerRadius = 20
        
        // MARK: Setting placeholder text for the tableView beeing empty
        
        placeholderLabel.text = "Keine abgeschlossenen Monate."
        placeholderLabel.textAlignment = .center
        placeholderLabel.textColor = .gray
        pastMonthsSummaryTableView.backgroundView = placeholderLabel
        
        // MARK: Showing total time elapsed
        
        // Query all currentRide objects
        let realm = try! Realm()
        let rides = realm.objects(currentRide.self)
        
        // Calculate the total time elapsed
        var totalSeconds = 0
        
        for ride in rides {
            if let timeElapsed = ride.timeElapsed {
                let components = timeElapsed.split(separator: ":")
                if components.count == 3,
                   let hours = Int(components[0]),
                   let minutes = Int(components[1]),
                   let seconds = Int(components[2]) {
                    totalSeconds += hours * 3600 + minutes * 60 + seconds
                }
            }
        }
        
        // Format the total time elapsed as hours:minutes:seconds
        let totalHours = totalSeconds / 3600
        let totalMinutes = (totalSeconds % 3600) / 60
        let remainingSeconds = totalSeconds % 60
        
        let totalTimeElapsed = String(format: "%02d:%02d:%02d", totalHours, totalMinutes, remainingSeconds)
        
        // Display the result on the totalTimeElapsedLabel
        totalTimeElapsedLabel.text = totalTimeElapsed
        
        // MARK: Showing total distance driven
        
        // Next, use a reduce function to sum all the distanceDriven entries
        let totalDistanceDriven = rides.reduce(0.0) { (result, ride) -> Double in
            if let distanceString = ride.distanceDriven {
                let separatedString = distanceString.components(separatedBy: CharacterSet.decimalDigits.inverted)
                let distance = Double(separatedString.joined(separator: "")) ?? 0.0

                // If the last character in the separated string is '0', assume it represents decimal places
                if let last = separatedString.last, last == "0" {
                    let decimalPlaces = Double(String(format: "0.%@", separatedString.last!)) ?? 0.0
                    return result + (distance * decimalPlaces)
                } else {
                    return result + distance/10
                }
            } else {
                return result
            }
        }
        
        // Finally, update your UI with the total distance driven
        totalDistanceDrivenLabel.text = String(format: "%.2f Km", totalDistanceDriven)
    }
    
    @IBAction func closeMonthAction(_ sender: Any) {
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        // Create an alert controller
        let alertController = UIAlertController(
            title: "ACHTUNG",
            message: "Wenn du den aktuellen Monat abschliesst, werden die Fahrten in den vergangen Monaten als Total gespeichert. \n\n Die Liste der Fahrten des aktuellen Monats wird zurückgesetzt und die Fahrten ins Archiv verschoben.",
            preferredStyle: .actionSheet
        )
        
        // Add an action to confirm deletion
        let confirmAction = UIAlertAction(
            title: "Bestätigen",
            style: .destructive,
            handler: { _ in
                // First, we need to write the time elapsed and distance driven values to the pastMonthRides model object before we delete all objects from the database
                let realm = try! Realm()
                
                let totalDistance = self.totalDistanceDrivenLabel.text
                let totalTimeElapsed = self.totalTimeElapsedLabel.text
                
                try! realm.write {
                    let pastMonthRide = pastMonthRides()
                    pastMonthRide.date = Date()
                    pastMonthRide.totalDistace = totalDistance
                    pastMonthRide.totalTimeElapsed = totalTimeElapsed
                    
                    // Use Realm's create(_:value:update:) method to create new instances of your objects
                    // Here, we use the value argument to pass in the properties of the current ride and assign them to the properties of the new archived ride
                    let currentRides = realm.objects(currentRide.self)
                    for currentRide in currentRides {
                        let archivedRide = realm.create(archivedRides.self)
                        archivedRide.date = currentRide.date
                        archivedRide.distanceDriven = currentRide.distanceDriven
                        archivedRide.timeElapsed = currentRide.timeElapsed
                        archivedRide.currentClientName = currentRide.currentClientName
                        archivedRide.supplementDate = currentRide.supplementDate
                        archivedRide.isManuallySaved = currentRide.isManuallySaved
                        archivedRide.encodedPolyline = currentRide.encodedPolyline
                    }
                    
                    realm.add(pastMonthRide)
                    realm.delete(currentRides)
                }
                
                // Update the UI
                self.totalTimeElapsedLabel.text = "00:00:00"
                self.totalDistanceDrivenLabel.text = "0.0 Km"
                self.pastMonthsSummaryTableView.reloadData()
            }
        )
        
        // Add a cancel action to dismiss the alert
        let cancelAction = UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil)
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        // Present the alert
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func sendReportButtonPressed(_ sender: Any) {
        let realm = try! Realm()
        let currentRides = realm.objects(currentRide.self).sorted(byKeyPath: "date", ascending: true)
        let personalDetails = realm.objects(personalDetails.self).last
        
        let yourName = personalDetails?.yourName
        let bossName = personalDetails?.bossName
        let email = personalDetails?.email
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        let monthName = dateFormatter.string(from: Date())
        
        var emailText =  "  Grüezi \(bossName ?? ""),\n\n Untenstehend erhalten Sie die aktuelle Fahrtenliste für den Monat \(monthName).\n\nMit besten Grüssen,\n\n\(yourName ?? "")\n\n\nFahrtenliste:\n_______________________\n"
        
        if let hours = totalTimeElapsedLabel.text, let distance = totalDistanceDrivenLabel.text {
            emailText += "\n"
            emailText += "Total Stunden: \(hours)\n"
            emailText += "Total Distanz: \(distance)\n"
            emailText += "_______________________\n"
            
        }
        
        for ride in currentRides {
            emailText += "\n"
            emailText += "  Datum:  \(ride.date ?? "")\n"
            emailText += "  Kunde:  \(ride.currentClientName ?? "")\n"
            emailText += "  Gefahrene Distanz:  \(ride.distanceDriven ?? "")\n"
            emailText += "  Gefahrene Zeit:     \(ride.timeElapsed ?? "")\n"
            //emailText += "\n"
            emailText += "_______________________\n\n"
        }
        emailText += "Dieser Bericht wurde durch die Horizonte Fahrtenbuch App V1.9.1 generiert."
        
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients(["\(email ?? "")"])
            mailComposer.setSubject("Fahrtenbuch \(yourName ?? "") für \(monthName)")
            mailComposer.setMessageBody(emailText, isHTML: false)
            present(mailComposer, animated: true, completion: nil)
        } else {
            print("Cannot send mails")
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: TableViewFuncitons
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let realm = try! Realm()
        
        let objects = realm.objects(pastMonthRides.self).sorted(byKeyPath: "date", ascending: true)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "de_DE") // Setzen Sie hier Ihr gewünschtes lokale und Zeitzone
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "MMMM yyyy"
        
        return objects.count
    }
    
    // MARK: TableViewFunction to populate with data
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = pastMonthsSummaryTableView.dequeueReusableCell(withIdentifier: "pastMonthRidesCell", for: indexPath) as! pastMonthRidesCell
        
        let realm = try! Realm()
        let objects = realm.objects(pastMonthRides.self).sorted(byKeyPath: "date", ascending: true)
        
        let object = objects[indexPath.row] // Get the correct object for this row
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "de_DE") // Setzen Sie hier Ihr gewünschtes lokale und Zeitzone
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "MMMM yyyy"
        
        cell.monthLabel?.text = dateFormatter.string(from: object.date) // Use the date formatter to set the label text
        cell.distanceLabel.text = object.totalDistace?.description
        cell.timeLabel.text = object.totalTimeElapsed?.description
        
        if !hasData {
               placeholderLabel.isHidden = true
        } else {
            placeholderLabel.isHidden = false
        }

        
        return cell
    }
    
    // MARK: TableViewFunction to delete rows.
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let realm = try! Realm()
            let objects = realm.objects(pastMonthRides.self).sorted(byKeyPath: "date", ascending: true)
            let object = objects[indexPath.row]
            
            let alert = UIAlertController(title: "Monatseintrag löschen", message: "Möchtest du diesen Eintrag wirklich löschen?", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Löschen", style: .destructive, handler: { _ in
                // If the user confirms, delete the row
                try! realm.write {
                    realm.delete(object)
                }
                
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }))
            
            alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil))
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: Set the gap between rows:
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90.0 // Set the height of the cell to be 10 points more than what you have specified in the Storyboard or programmatically
    }
}
