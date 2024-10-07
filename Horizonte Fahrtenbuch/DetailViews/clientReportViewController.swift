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
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func createReportButtonPressed(_ sender: Any) {
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
        let realm = try! Realm()
        let startDate = startDatePicker.date
        let endDate = endDatePicker.date
        
        // Get client name
        guard let clientName = clientNameTextfield.text, !clientName.isEmpty else {
            // Handle empty client name, show an alert
            let alert = UIAlertController(title: "Fehler", message: "Name ist erforderlich", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        // Query current rides
        let currentRides = realm.objects(currentRide.self)
            .filter("dateActual >= %@ AND dateActual <= %@ AND currentClientName CONTAINS[c] %@", startDate, endDate, clientName)
            .sorted(byKeyPath: "dateActual", ascending: true)
        
        // Query archived rides similarly
        let archivedRides = realm.objects(archivedRides.self)
            .filter("dateActual >= %@ AND dateActual <= %@ AND currentClientName CONTAINS[c] %@", startDate, endDate, clientName)
            .sorted(byKeyPath: "dateActual", ascending: true)
        
        // Get personal details (assuming you have this model)
        let personalDetails = realm.objects(personalDetails.self).last
        let yourName = personalDetails?.yourName ?? ""
        let email = ""
        
        var emailText = "Guten Tag,<br><br> Untenstehend erhalten Sie die zusannengefasste Fahrtenliste für den Kunden \(clientName):<br><br>"
        
        // Build detailed report
        for ride in currentRides {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d. MMMM yyyy"
            let dateString = ride.dateActual != nil ? dateFormatter.string(from: ride.dateActual!) : "No date"
            emailText += "<b>\(dateString)</b><br><br>"
            emailText += "\(ride.currentClientName ?? "")<br><br>"
            dateFormatter.dateFormat = "HH:mm"
            let startTimeString = ride.startTime != nil ? dateFormatter.string(from: ride.startTime!) : "--:--"
            let endTimeString = ride.endTime != nil ? dateFormatter.string(from: ride.endTime!) : "--:--"
            emailText += "\(startTimeString) - \(endTimeString)<br><br>"
            
            // Debugging: Print distance driven value before conversion
            print("Distance Driven (String): \(ride.distanceDriven ?? "nil")")
            
            // Convert distanceDriven to Double and accumulate total distance
            if let distance = ride.distanceDriven {
                let cleanedDistance = distance.replacingOccurrences(of: " Km", with: "")
                
                if let distanceDouble = Double(cleanedDistance.trimmingCharacters(in: .whitespaces)) {
                    totalDistance += distanceDouble
                } else {
                    print("Could not convert distanceDriven to Double")
                }
            } else {
                print("Distance Driven is nil")
            }
            
            emailText += "<b>Gefahrene Distanz: \(ride.distanceDriven ?? "")<br>"
            
            // Convert timeElapsed to TimeInterval and accumulate total time
            if let timeString = ride.timeElapsed, let rideTime = timeIntervalFrom(timeString: timeString) {
                totalTime += rideTime
            }
            emailText += "<b>Gefahrene Zeit: \(ride.timeElapsed ?? "")</b><br>"
            emailText += "_________________________________<br><br>"
        }
        
        // Format total distance and total time
        let totalTimeFormatted = formatTimeInterval(totalTime)
        emailText += "<br><b>Gesamte Gefahrene Distanz: \(String(format: "%.2f", totalDistance)) km</b><br>"
        emailText += "<b>Gesamte Gefahrene Zeit: \(totalTimeFormatted)</b><br><br><br>"
        
        emailText += "Mit besten Grüssen,<br><br>\(yourName)<br><br>"
        
        emailText += "Dieser Bericht wurde durch die Horizonte Fahrtenbuch App V5.0.0 generiert. - © 2023 - 2024 Stephan König (GPL 3.0)"
        
        // Create a date formatter for German locale
        let dateFormatterForSubject = DateFormatter()
        dateFormatterForSubject.locale = Locale(identifier: "de_DE")
        dateFormatterForSubject.dateFormat = "d. MMMM yyyy" // Format to only show day, month, and year

        // Format the start and end dates
        let formattedStartDate = dateFormatterForSubject.string(from: startDate)
        let formattedEndDate = dateFormatterForSubject.string(from: endDate)

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


