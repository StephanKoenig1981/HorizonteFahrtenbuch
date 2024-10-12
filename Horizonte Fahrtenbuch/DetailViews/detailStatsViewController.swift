//
//  detailStatsViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 12.10.2024.
//

import UIKit
import RealmSwift
import MessageUI

class detailStatsViewController: UIViewController, MFMailComposeViewControllerDelegate  {

    // MARK: Outlets
    
    // Cell Titles
    
    @IBOutlet weak var overallTotalTitleLabel: UILabel!
    @IBOutlet weak var currentYearTitleLabel: UILabel!
    @IBOutlet weak var overallAverageTitleLabel: UILabel!
    @IBOutlet weak var currentYearAverageTitleLabel: UILabel!
    
    // Cell Values
    
    @IBOutlet weak var overallDistanceLabel: UILabel!
    @IBOutlet weak var overallTimeLabel: UILabel!
    @IBOutlet weak var overallAmountOfRidesLabel: UILabel!
    
    @IBOutlet weak var currentYearDistanceLabel: UILabel!
    @IBOutlet weak var currentYearTimeLabel: UILabel!
    @IBOutlet weak var currentYearAmountOfRidesLabel: UILabel!
    
    @IBOutlet weak var overallAverageDistanceLabel: UILabel!
    @IBOutlet weak var overallAverageTimeLabel: UILabel!
    
    @IBOutlet weak var currentYearAverageDistanceLabel: UILabel!
    @IBOutlet weak var currentYearAverageTimeLabel: UILabel!
    
    // MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentYearTitleLabel.text = "Total \(Calendar.current.component(.year, from: Date()))"
        currentYearAverageTitleLabel.text = "Durchschnitt pro Fahrt \(Calendar.current.component(.year, from: Date()))"
        
        loadRideStats()
        
    }
    
    func loadRideStats() {
        let realm = try! Realm()
        
        // Fetch all rides from both currentRide and archivedRides
        let currentRides = realm.objects(currentRide.self)
        let archivedRides = realm.objects(archivedRides.self)
        
        print("Current Rides Count: \(currentRides.count)")
        print("Archived Rides Count: \(archivedRides.count)")
        
        // Combine both ride collections
        let allRides = Array(currentRides) + Array(archivedRides)

        // Update the amount of rides labels
        overallAmountOfRidesLabel.text = "\(allRides.count)"
        
        // Filter rides for the current year
        let currentYearRides = allRides.filter { ride in
            if let ride = ride as? currentRide, let date = ride.dateActual {
                return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
            } else if let ride = ride as? archivedRides, let date = ride.dateActual {
                return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
            }
            return false
        }
        
        // Update current year rides count label
        currentYearAmountOfRidesLabel.text = "\(currentYearRides.count)"

        // Helper function to clean numeric strings for distances
        func cleanNumericString(_ input: String?) -> String {
            guard let input = input else { return "0" }
            let numericString = input.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()
            return numericString.isEmpty ? "0" : numericString
        }

        // Helper function to convert time string (hh:mm:ss) to total seconds
        func timeStringToSeconds(_ timeString: String?) -> Double {
            guard let timeString = timeString else { return 0 }
            
            let components = timeString.split(separator: ":").map { String($0) }
            if components.count == 3,
               let hours = Double(components[0]),
               let minutes = Double(components[1]),
               let seconds = Double(components[2]) {
                return hours * 3600 + minutes * 60 + seconds // Convert to total seconds
            }
            
            return 0 // Return 0 if the format is not correct
        }
        
        // Helper function to format time as 00:00:00 (hours:minutes:seconds)
        func formatTime(_ totalSeconds: Double) -> String {
            let hours = Int(totalSeconds) / 3600
            let minutes = (Int(totalSeconds) % 3600) / 60
            let seconds = Int(totalSeconds) % 60
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }

        // Calculate overall stats (after cleaning)
        let totalDistance = allRides.compactMap { ride in
            if let ride = ride as? currentRide {
                return Double(cleanNumericString(ride.distanceDriven))
            } else if let ride = ride as? archivedRides {
                return Double(cleanNumericString(ride.distanceDriven))
            }
            return nil // Return nil for non-matching cases
        }.reduce(0.0, { $0 + ($1 ?? 0.0) }) // Use 0.0 as the initial value

        let totalTime = allRides.compactMap { ride in
            if let ride = ride as? currentRide {
                return timeStringToSeconds(ride.timeElapsed)
            } else if let ride = ride as? archivedRides {
                return timeStringToSeconds(ride.timeElapsed)
            }
            return nil // Return nil for non-matching cases
        }.reduce(0.0, { $0 + ($1 ?? 0.0) }) // Use 0.0 as the initial value
        
        let averageDistance = totalDistance / max(Double(allRides.count), 1)
        let averageTime = totalTime / max(Double(allRides.count), 1)

        let currentYearDistance = currentYearRides.compactMap { ride in
            if let ride = ride as? currentRide {
                return Double(cleanNumericString(ride.distanceDriven))
            } else if let ride = ride as? archivedRides {
                return Double(cleanNumericString(ride.distanceDriven))
            }
            return nil // Return nil for non-matching cases
        }.reduce(0.0, { $0 + ($1 ?? 0.0) }) // Use 0.0 as the initial value

        let currentYearTime = currentYearRides.compactMap { ride in
            if let ride = ride as? currentRide {
                return timeStringToSeconds(ride.timeElapsed)
            } else if let ride = ride as? archivedRides {
                return timeStringToSeconds(ride.timeElapsed)
            }
            return nil // Return nil for non-matching cases
        }.reduce(0.0, { $0 + ($1 ?? 0.0) }) // Use 0.0 as the initial value

        let currentYearAverageDistance = currentYearDistance / max(Double(currentYearRides.count), 1)
        let currentYearAverageTime = currentYearTime / max(Double(currentYearRides.count), 1)

        // Update UI Labels with formatted values
        overallDistanceLabel.text = String(format: "%.1f km", totalDistance) // 0.0 format
        overallTimeLabel.text = formatTime(totalTime) // 00:00:00 format

        currentYearDistanceLabel.text = String(format: "%.1f km", currentYearDistance) // 0.0 format
        currentYearTimeLabel.text = formatTime(currentYearTime) // 00:00:00 format

        overallAverageDistanceLabel.text = String(format: "%.1f km", averageDistance) // 0.0 format
        overallAverageTimeLabel.text = formatTime(averageTime) // 00:00:00 format

        currentYearAverageDistanceLabel.text = String(format: "%.1f km", currentYearAverageDistance) // 0.0 format
        currentYearAverageTimeLabel.text = formatTime(currentYearAverageTime) // 00:00:00 format
    }

    // Helper function to get the start of the current year
    func startOfYear() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: Date())
        return calendar.date(from: components)!
    }
    
    // MARK: Button Functions
    
    @IBAction func sendStatsButtonPressed(_ sender: Any) {
        sendTotalReport()
    }
    
    // Function to handle sending the total report
    func sendTotalReport() {
        // Create the mail composer
        guard MFMailComposeViewController.canSendMail() else {
            print("Mail services are not available")
            return
        }

        let mailComposeVC = MFMailComposeViewController()
        mailComposeVC.mailComposeDelegate = self

        // Subject and body content for the email
        let subject = "Fahrtenbuch Gesamtzusammenfassung"
        
        // Prepare the email body with fetched data
        let emailBody = prepareEmailBody()

        mailComposeVC.setSubject(subject)
        mailComposeVC.setMessageBody(emailBody, isHTML: true) // Set isHTML to true

        // Present the mail composer
        present(mailComposeVC, animated: true, completion: nil)
    }

    // Function to prepare the email body with all fetched data
    func prepareEmailBody() -> String {
        // Fetch all stats
        let realm = try! Realm()
        let currentRides = realm.objects(currentRide.self)
        let archivedRides = realm.objects(archivedRides.self)
        let personalDetails = realm.objects(personalDetails.self)

        // Get your name
        let yourName = personalDetails.last?.yourName ?? "Ihr Name"

        var emailBody = "<html><body>"
        emailBody += "<p>Guten Tag,</p>"
        emailBody += "<p>Untenstehend finden Sie eine Zusammenfassung über alle aufgezeichneten Fahrten:</p>"
        emailBody += "<br><b><span style=\"color: #9CC769;\">Gesamtanzahl Fahrten:</span></b> &nbsp&nbsp&nbsp&nbsp&nbsp\(currentRides.count + archivedRides.count)<br>"
        emailBody += "<b><span style=\"color: #9CC769;\">Gesamtdistanz:</span></b> &nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp\(overallDistanceLabel.text ?? "0.0 km")<br>"
        emailBody += "<b><span style=\"color: #9CC769;\">Gesamte gefahrene Zeit:</span></b> &nbsp \(overallTimeLabel.text ?? "00:00:00")<br><br>"
        emailBody += "<b><span style=\"color: #9CC769;\">Gesamtdistanz \(Calendar.current.component(.year, from: Date())):</span></b>&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp\(currentYearDistanceLabel.text ?? "0.0 km")<br>"
        emailBody += "<b><span style=\"color: #9CC769;\">Gesamtzeit \(Calendar.current.component(.year, from: Date())):</span></b> &nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp\(currentYearTimeLabel.text ?? "00:00:00")<br><br>"
        emailBody += "<b><span style=\"color: #9CC769;\">Gesamte Durchschnittsdistanz:</span></b> &nbsp&nbsp&nbsp&nbsp&nbsp\(overallAverageDistanceLabel.text ?? "0.0 km")<br>"
        emailBody += "<b><span style=\"color: #9CC769;\">Gesamte Durchschnittszeit:</span></b>&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp \(overallAverageTimeLabel.text ?? "00:00:00")<br><br>"
        emailBody += "<b><span style=\"color: #9CC769;\">Durchschnittsdistanz \(Calendar.current.component(.year, from: Date())):</span></b> &nbsp&nbsp&nbsp\(currentYearAverageDistanceLabel.text ?? "0.0 km")<br>"
        emailBody += "<b><span style=\"color: #9CC769;\">Durchschnittszeit \(Calendar.current.component(.year, from: Date())):</span></b> &nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp\(currentYearAverageTimeLabel.text ?? "00:00:00")<br><br>"
        emailBody += "<p>Mit besten Grüssen,<br><br>\(yourName)</p><br>"
        emailBody += "_________________________________<br><br>"
        emailBody += "Dieser Bericht wurde durch die Horizonte Fahrtenbuch App V6.0.0 generiert. - © 2023 - 2024 Stephan König (GPL 3.0)"
        emailBody += "</body></html>"

        return emailBody
    }

        // Function to prepare the email body with all fetched data
  
    
    func presentMailComposer() {
        guard MFMailComposeViewController.canSendMail() else {
            // Show an alert or handle the case where the user can't send emails
            return
        }

        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self // Make sure your class conforms to MFMailComposeViewControllerDelegate

        let emailBody = prepareEmailBody()
        mailComposer.setSubject("Fahrten Zusammenfassung")
        mailComposer.setToRecipients(["recipient@example.com"]) // Replace with actual recipient
        mailComposer.setMessageBody(emailBody, isHTML: true) // Set the email body as HTML

        present(mailComposer, animated: true, completion: nil)
    }

        // Function to handle the result of the mail composer
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true, completion: nil)
        }
}


