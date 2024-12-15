//
//  clientReportViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 07.10.2024.
//

import UIKit
import RealmSwift
import MessageUI

class clientReportViewController: UIViewController, UITextFieldDelegate, MFMailComposeViewControllerDelegate {

   // MARK: Outlets
    
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    
    @IBOutlet weak var clientNameTextfield: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // MARK: Customization
        
        startDatePicker.overrideUserInterfaceStyle = .dark
        
        startDatePicker.setValue(UIColor.white, forKeyPath: "textColor")
        startDatePicker.tintColor = UIColor.systemPurple
        
        endDatePicker.overrideUserInterfaceStyle = .dark
        
        endDatePicker.setValue(UIColor.white, forKeyPath: "textColor")
        endDatePicker.tintColor = UIColor.systemPurple
        
        // Set the delegate for the client name text field
        clientNameTextfield.delegate = self
        
        // Add Tap Gesture to Dismiss Keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // Dismiss Keyboard Method
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func createReportButtonPressed(_ sender: Any) {
        
        // MARK: Haptic Feedback for start
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        sendDetailedReport()
    }
    
    func sendDetailedReport() {
        // Haptic Feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        // Initialize total distance and total time variables
        var totalDistance: Double = 0.0
        var totalTime: TimeInterval = 0.0 // TimeInterval is in seconds
        
        // Realm
        let realm: Realm
        do {
            realm = try Realm()
        } catch {
            print("Failed to initialize Realm: \(error.localizedDescription)")
            return // Handle the error appropriately
        }
        
        let calendar = Calendar.current
        
        // Normalize the start date to the beginning of the day (00:00:00)
        let startOfDay = calendar.startOfDay(for: startDatePicker.date)
        
        // Normalize the end date to the last second of the day (23:59:59)
        var components = DateComponents()
        components.day = 1
        components.second = -1
        let endOfDay = calendar.date(byAdding: components, to: calendar.startOfDay(for: endDatePicker.date)) ?? endDatePicker.date
        
        // Get client name
        guard let clientName = clientNameTextfield.text, !clientName.isEmpty else {
            // Handle empty client name, show an alert
            let alert = UIAlertController(title: "Fehler", message: "Kundenname ist erforderlich", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        // Query current rides
        let currentRides = realm.objects(currentRide.self)
            .filter("dateActual >= %@ AND dateActual <= %@ AND currentClientName CONTAINS[c] %@", startOfDay, endOfDay, clientName)
        
        // Query archived rides similarly
        let archivedRides = realm.objects(archivedRides.self)
            .filter("dateActual >= %@ AND dateActual <= %@ AND currentClientName CONTAINS[c] %@", startOfDay, endOfDay, clientName)

        // Combine current and archived rides
        var allRides: [AnyObject] = []
        allRides.append(contentsOf: currentRides.map { $0 as AnyObject }) // Cast to AnyObject
        allRides.append(contentsOf: archivedRides.map { $0 as AnyObject }) // Cast to AnyObject
        
        // Sort the combined rides by date
        allRides.sort {
            let date1 = ($0 as? currentRide)?.dateActual ?? ($0 as? archivedRides)?.dateActual ?? Date.distantPast
            let date2 = ($1 as? currentRide)?.dateActual ?? ($1 as? archivedRides)?.dateActual ?? Date.distantPast
            return date1 < date2
        }

        // Get personal details (assuming you have this model)
        let personalDetails = realm.objects(personalDetails.self).last
        let yourName = personalDetails?.yourName ?? ""
        let email = "" // Ensure you have a valid email address
        
        var emailText = "Guten Tag,<br><br> Untenstehend erhalten Sie die zusannengefasste Fahrtenliste für den Kunden \(clientName):<br><br>"

        // Temporary variable to accumulate ride details
        var rideDetails = ""

        // Build detailed report
        for ride in allRides {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d. MMMM yyyy"
            let dateString: String

            if let ride = ride as? currentRide { // Check if ride is of type currentRide
                dateString = ride.dateActual != nil ? dateFormatter.string(from: ride.dateActual!) : "No date"
                rideDetails += "<b><span style=\"color: #9CC769;\">\(dateString)</span></b><br><br>"
                rideDetails += "\(ride.currentClientName ?? "")<br><br>"

                dateFormatter.dateFormat = "HH:mm"
                let startTimeString = ride.startTime != nil ? dateFormatter.string(from: ride.startTime!) : "--:--"
                let endTimeString = ride.endTime != nil ? dateFormatter.string(from: ride.endTime!) : "--:--"
                rideDetails += "\(startTimeString) - \(endTimeString)<br><br>"

                // Accumulate total distance and time
                if let distance = ride.distanceDriven {
                    let cleanedDistance = distance.replacingOccurrences(of: " Km", with: "")
                    if let distanceDouble = Double(cleanedDistance.trimmingCharacters(in: .whitespaces)) {
                        totalDistance += distanceDouble
                    }
                }
                rideDetails += "<b>Gefahrene Distanz: &nbsp \(ride.distanceDriven ?? "")</b><br>"

                if let timeString = ride.timeElapsed, let rideTime = timeIntervalFrom(timeString: timeString) {
                    totalTime += rideTime
                }
                rideDetails += "<b>Gefahrene Zeit: &nbsp  &nbsp  &nbsp &nbsp &nbsp  \(ride.timeElapsed ?? "")</b><br>"
                rideDetails += "_________________________________<br><br>"
                
            } else if let ride = ride as? archivedRides { // Check if ride is of type archivedRides
                dateString = ride.dateActual != nil ? dateFormatter.string(from: ride.dateActual!) : "No date"
                rideDetails += "<b><span style=\"color: #9CC769;\">\(dateString)</span></b><br><br>"
                rideDetails += "\(ride.currentClientName ?? "")<br><br>"

                dateFormatter.dateFormat = "HH:mm"
                let startTimeString = ride.startTime != nil ? dateFormatter.string(from: ride.startTime!) : "--:--"
                let endTimeString = ride.endTime != nil ? dateFormatter.string(from: ride.endTime!) : "--:--"
                rideDetails += "\(startTimeString) - \(endTimeString)<br><br>"

                // Accumulate total distance and time
                if let distance = ride.distanceDriven {
                    let cleanedDistance = distance.replacingOccurrences(of: " Km", with: "")
                    if let distanceDouble = Double(cleanedDistance.trimmingCharacters(in: .whitespaces)) {
                        totalDistance += distanceDouble
                    }
                }
                rideDetails += "<b>Gefahrene Distanz: &nbsp \(ride.distanceDriven ?? "")</b><br>"

                if let timeString = ride.timeElapsed, let rideTime = timeIntervalFrom(timeString: timeString) {
                    totalTime += rideTime
                }
                rideDetails += "<b>Gefahrene Zeit: &nbsp  &nbsp &nbsp &nbsp &nbsp \(ride.timeElapsed ?? "")</b><br>"
                rideDetails += "_________________________________<br><br>"
            }
        }

        // Format total distance and total time after accumulating all the data
        let totalTimeFormatted = formatTimeInterval(totalTime)
        let totalRides = allRides.count // Count the number of rides
        emailText += "_________________________________<br><br>"
        emailText += "<b><span style=\"color: #9CC769;\">TOTALE:</span></b><br>"
        emailText += "<br><b>Gesamte Gefahrene Distanz: &nbsp \(String(format: "%.2f", totalDistance)) Km</b><br>"
        emailText += "<b>Gesamte Gefahrene Zeit: &nbsp &nbsp &nbsp &nbsp &nbsp    \(totalTimeFormatted)</b><br><br>"
        emailText += "<b>Anzahl Fahrten: \(totalRides) &nbsp &nbsp </b><br><br>"
        emailText += "_________________________________<br><br>"

        // Append ride details after the totals
        emailText += rideDetails

        emailText += "Mit besten Grüssen,<br><br>\(yourName)<br><br>"
        emailText += "Dieser Bericht wurde durch die Horizonte Fahrtenbuch App V7.0.2 generiert. - © 2023 - 2025 Stephan König (GPL 3.0)"
        
        // Create a date formatter for German locale
        let dateFormatterForSubject = DateFormatter()
        dateFormatterForSubject.locale = Locale(identifier: "de_DE")
        dateFormatterForSubject.dateFormat = "d. MMMM yyyy" // Format to only show day, month, and year

        // Format the start and end dates
        let formattedStartDate = dateFormatterForSubject.string(from: startOfDay)
        let formattedEndDate = dateFormatterForSubject.string(from: endOfDay)

        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients([email])
            
            // Use the formatted dates in the subject
            mailComposer.setSubject("Fahrtenbuch \(clientName) für \(formattedStartDate) bis \(formattedEndDate)")
            mailComposer.setMessageBody(emailText, isHTML: true)
            present(mailComposer, animated: true, completion: nil)
        } else {
            print("Cannot send mails")
        }
    }



    // MARK: - MFMailComposeViewControllerDelegate
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        // Dismiss the mail compose view controller
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Functions for keyboard actions
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
        
        // Helper function to convert time string to TimeInterval
        func timeIntervalFrom(timeString: String) -> TimeInterval? {
            let components = timeString.split(separator: ":").compactMap { Double($0) }
            guard components.count == 3 else { return nil } // Expecting "hh:mm:ss"
            let hours = components[0]
            let minutes = components[1]
            let seconds = components[2]
            return (hours * 3600) + (minutes * 60) + seconds
        }
        
        // Helper function to format TimeInterval to "hh:mm:ss"
        func formatTimeInterval(_ timeInterval: TimeInterval) -> String {
            let hours = Int(timeInterval) / 3600
            let minutes = (Int(timeInterval) % 3600) / 60
            let seconds = Int(timeInterval) % 60
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }


