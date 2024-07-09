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
        upperCellBackgroundView.layer.cornerRadius = 20
        
        // MARK: Setting placeholder text for the tableView beeing empty
        
        //placeholderLabel.text = "Keine abgeschlossenen Monate."
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
    
    // MARK: Function for calculating daily totals
    
    func calculateSumOfTimeAndDistanceForEachDate() -> [(date: Date, totalDistance: String, totalTime: Int)] {
        let realm = try! Realm()
        let rides = realm.objects(currentRide.self)

        var dateDistanceTimeDict = [Date: (totalDistance: Double, totalTime: Int)]()

        for ride in rides {
            guard let date = ride.dateActual else {
                continue
            }

            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            guard let dateOnly = calendar.date(from: components) else {
                continue
            }

            var totalDistanceForDate = 0.0
            var totalTimeForDate = 0

            if let distanceString = ride.distanceDriven {
                let distance = Double(distanceString.components(separatedBy: CharacterSet.decimalDigits.union([".", ","]).inverted).joined()) ?? 0.0
                totalDistanceForDate += distance
            }

            if let timeElapsed = ride.timeElapsed {
                let components = timeElapsed.split(separator: ":")
                if components.count == 3,
                    let hours = Int(components[0]),
                    let minutes = Int(components[1]),
                    let seconds = Int(components[2]) {
                    totalTimeForDate += hours * 3600 + minutes * 60 + seconds
                }
            }

            if let existingValue = dateDistanceTimeDict[dateOnly] {
                dateDistanceTimeDict[dateOnly] = (existingValue.totalDistance + totalDistanceForDate, existingValue.totalTime + totalTimeForDate)
            } else {
                dateDistanceTimeDict[dateOnly] = (totalDistanceForDate, totalTimeForDate)
            }
        }

        let sortedDict = dateDistanceTimeDict.sorted { $0.key < $1.key }
        return sortedDict.map { (date: $0.key, totalDistance: String(format: "%.1f Km", $0.value.totalDistance), totalTime: $0.value.totalTime) }
    }
    
    // MARK: Time formatter function
    
    func timeFormatted(_ totalSeconds: Int) -> String {
        let hours: Int = totalSeconds / 3600
        let minutes: Int = (totalSeconds % 3600) / 60
        let seconds: Int = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // MARK: IBActions
    
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
                        archivedRide.dateActual = currentRide.dateActual
                        archivedRide.distanceDriven = currentRide.distanceDriven
                        archivedRide.timeElapsed = currentRide.timeElapsed
                        archivedRide.currentClientName = currentRide.currentClientName
                        archivedRide.supplementDate = currentRide.supplementDate
                        archivedRide.isManuallySaved = currentRide.isManuallySaved
                        archivedRide.encodedPolyline = currentRide.encodedPolyline
                        
                        archivedRide.startTime = currentRide.startTime
                        archivedRide.endTime = currentRide.endTime
                        archivedRide.deliveryTime = currentRide.deliveryTime
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
        
        // Haptic Feedback
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        // Show action sheet for report options
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let simpleReportAction = UIAlertAction(title: "Einfacher Bericht", style: .default) { _ in
            // Send simple report
            self.sendSimpleReport()
        }
        
        let detailedReportAction = UIAlertAction(title: "Detaillierter Bericht", style: .default) { _ in
            // Send detailed report
            self.sendDetailedReport()
        }
        
        let cancelAction = UIAlertAction(title: "Abbrechen", style: .destructive, handler: nil)
        
        actionSheet.addAction(simpleReportAction)
        actionSheet.addAction(detailedReportAction)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    // MARK: Functions for simple and detailled report
    
    func sendSimpleReport() {
        
        // Haptic Feedback
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        // Realm
        
        let realm = try! Realm()
         let currentRides = realm.objects(currentRide.self).sorted(byKeyPath: "dateActual", ascending: true)
         let personalDetails = realm.objects(personalDetails.self).last

         let yourName = personalDetails?.yourName
         let bossName = personalDetails?.bossName
         let email = personalDetails?.email

         let dateFormatter = DateFormatter()
         dateFormatter.dateFormat = "MMMM yyyy"
         let monthName = dateFormatter.string(from: Date())
        
         var emailText =  "  Grüezi \(bossName ?? ""),<br><br> Untenstehend erhalten Sie die aktuelle Fahrtenliste für den Monat \(monthName).<br><br>Mit besten Grüssen,<br><br>\(yourName ?? "")<br><br><span style=\"color: #9CC769; font-weight: bold;\">Monatstotal:</span></b><br>_________________________________<br>"

         if let hours = totalTimeElapsedLabel.text, let distance = totalDistanceDrivenLabel.text {
             emailText += "<br>"
             emailText += "<b>Total Stunden: &nbsp \(hours)</b><br>"
             emailText += "<b>Total Distanz: &nbsp &nbsp \(distance)</b><br>"
             emailText += "_________________________________<br>"
             emailText += "<br><br>"
             
             
         }

        emailText += "<span style=\"color: #9CC769; font-weight: bold;\">Tagestotale:</span><br>"
        emailText += "_________________________________"
        
        let dateDistanceTimeArray = calculateSumOfTimeAndDistanceForEachDate()
        for tuple in dateDistanceTimeArray {
            emailText += "<br>"
            dateFormatter.locale = Locale(identifier: "de_DE")
            dateFormatter.dateFormat = "d. MMMM yyyy"

            let dateString = dateFormatter.string(from: tuple.date)
            emailText += "<br>"
            emailText += "<b>\(dateString)</b><br><br>"
            emailText += "  Total gefahrene Distanz: &nbsp &nbsp\(tuple.totalDistance)<br>"

            let formattedTime = timeFormatted(tuple.totalTime)
            emailText += "<b>  Total gefahrene Zeit: &nbsp &nbsp &nbsp &nbsp \(formattedTime)</b><br>"
            emailText += "_________________________________<br>"
        }
        
         emailText += "<br><br>"
         emailText += "Dieser Bericht wurde durch die Horizonte Fahrtenbuch App V4.2.0 beta 9 generiert. - © 2023 - 2024 Stephan König (GPL 3.0)"
         
         if MFMailComposeViewController.canSendMail() {
             let mailComposer = MFMailComposeViewController()
             mailComposer.mailComposeDelegate = self
             mailComposer.setToRecipients(["\(email ?? "")"])
             mailComposer.setSubject("Fahrtenbuch \(yourName ?? "") für \(monthName)")
             mailComposer.setMessageBody(emailText, isHTML: true)
             present(mailComposer, animated: true, completion: nil)
         } else {
             print("Cannot send mails")
         }
    }
    
    func sendDetailedReport() {
        
            // Haptic Feedback
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
            // Realm
            
            let realm = try! Realm()
             let currentRides = realm.objects(currentRide.self).sorted(byKeyPath: "dateActual", ascending: true)
             let personalDetails = realm.objects(personalDetails.self).last

             let yourName = personalDetails?.yourName
             let bossName = personalDetails?.bossName
             let email = personalDetails?.email

             let dateFormatter = DateFormatter()
             dateFormatter.dateFormat = "MMMM yyyy"
             let monthName = dateFormatter.string(from: Date())
            
             var emailText =  "  Grüezi \(bossName ?? ""),<br><br> Untenstehend erhalten Sie die aktuelle Fahrtenliste für den Monat \(monthName).<br><br>Mit besten Grüssen,<br><br>\(yourName ?? "")<br><br><span style=\"color: #9CC769; font-weight: bold;\">Monatstotal:</span></b><br>_________________________________<br>"

             if let hours = totalTimeElapsedLabel.text, let distance = totalDistanceDrivenLabel.text {
                 emailText += "<br>"
                 emailText += "<b>Total Stunden: &nbsp \(hours)</b><br>"
                 emailText += "<b>Total Distanz: &nbsp &nbsp \(distance)</b><br>"
                 emailText += "_________________________________<br>"
                 emailText += "<br><br>"
                 
                 
             }

            emailText += "<span style=\"color: #9CC769; font-weight: bold;\">Tagestotale:</span><br>"
            emailText += "_________________________________"
            
            let dateDistanceTimeArray = calculateSumOfTimeAndDistanceForEachDate()
            for tuple in dateDistanceTimeArray {
                emailText += "<br>"
                dateFormatter.locale = Locale(identifier: "de_DE")
                dateFormatter.dateFormat = "d. MMMM yyyy"

                let dateString = dateFormatter.string(from: tuple.date)
                emailText += "<br>"
                emailText += "<b>\(dateString)</b><br><br>"
                emailText += "  Total gefahrene Distanz: &nbsp &nbsp\(tuple.totalDistance)<br>"

                let formattedTime = timeFormatted(tuple.totalTime)
                emailText += "<b>  Total gefahrene Zeit: &nbsp &nbsp &nbsp &nbsp\(formattedTime)</b><br>"
                emailText += "_________________________________<br>"
            }
            
            // Text for detailled report
            
            emailText += "<br><br>"
            emailText += "<span style=\"color: #9CC769; font-weight: bold;\">Detaillierte Fahrtenliste:</span><br>"
            emailText += "_________________________________<br>"

             for ride in currentRides {
                 emailText += "<br>"
                 dateFormatter.locale = Locale(identifier: "de_DE")
                 dateFormatter.dateFormat = "d. MMMM yyyy"

                 let dateString = ride.dateActual != nil ? dateFormatter.string(from: ride.dateActual!) : "No date"
                 emailText += "<b>  Datum:  \(dateString)</b><br><br>"
                 emailText += "Kunde:  &nbsp &nbsp &nbsp &nbsp &nbsp &nbsp &nbsp &nbsp &nbsp &nbsp &nbsp &nbsp &nbsp &nbsp\(ride.currentClientName ?? "")<br>"
                 dateFormatter.dateFormat = "HH:mm"
                     let startTimeString = ride.startTime != nil ? dateFormatter.string(from: ride.startTime!) : "--:--"
                     let endTimeString = ride.endTime != nil ? dateFormatter.string(from: ride.endTime!) : "--:--"

                     emailText += "  Start- und Endzeit: &nbsp &nbsp &nbsp \(startTimeString) - \(endTimeString)<br>"
                 emailText += "  Gefahrene Distanz:  &nbsp &nbsp &nbsp \(ride.distanceDriven ?? "")<br>"
                 emailText += "<b>  Gefahrene Zeit: &nbsp &nbsp &nbsp &nbsp &nbsp &nbsp\(ride.timeElapsed ?? "")</b><br>"
                 emailText += "_________________________________<br><br>"
             }
             
             emailText += "<br><br>"
             emailText += "Dieser Bericht wurde durch die Horizonte Fahrtenbuch App V4.2.0 beta 9 generiert. - © 2023 - 2024 Stephan König (GPL 3.0)"
             
             if MFMailComposeViewController.canSendMail() {
                 let mailComposer = MFMailComposeViewController()
                 mailComposer.mailComposeDelegate = self
                 mailComposer.setToRecipients(["\(email ?? "")"])
                 mailComposer.setSubject("Fahrtenbuch \(yourName ?? "") für \(monthName)")
                 mailComposer.setMessageBody(emailText, isHTML: true)
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
        dateFormatter.locale = Locale(identifier: "de_DE")
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "MMMM yyyy"
        
        return objects.count
    }
    
    // MARK: TableViewFunction to populate with data
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = pastMonthsSummaryTableView.dequeueReusableCell(withIdentifier: "pastMonthRidesCell", for: indexPath) as! pastMonthRidesCell

        let realm = try! Realm()
        let originalObjects = realm.objects(pastMonthRides.self)
        let sortedObjects = originalObjects.sorted(byKeyPath: "date", ascending: false)

        guard indexPath.row < sortedObjects.count else {
            return UITableViewCell()
        }

        let currentObject = sortedObjects[indexPath.row]
        
        let originalIndex: Int
        if let index = originalObjects.index(of: currentObject) {
            originalIndex = index
        } else {
            return UITableViewCell() // Handle the case where the object is not found in the original array
        }

        guard originalIndex > 0 else {
            configureCell(cell, with: currentObject, hasData: hasData, isIncrease: nil, rowIndex: indexPath.row)
            return cell
        }

        let previousObject = originalObjects[originalIndex - 1]

        let distanceDifference = calculatePercentageDifference(currentValue: currentObject.totalDistace ?? 0.0,
                                                               previousValue: previousObject.totalDistace ?? 0.0)
        let timeDifference = calculatePercentageDifference(currentValue: currentObject.totalTimeElapsed ?? 0.0,
                                                           previousValue: previousObject.totalTimeElapsed ?? 0.0)

        cell.distancePercentageLabel.text = "\(Int(distanceDifference))%"
        cell.timePercentageLabel.text = "\(Int(timeDifference))%"

        configureCell(cell, with: currentObject, hasData: hasData, isIncrease: distanceDifference > 0, rowIndex: indexPath.row)

        return cell
    }
    
    func calculatePercentageDifference(currentValue: Any, previousValue: Any) -> Double {
        guard let currentDouble = (currentValue as? NSString)?.doubleValue,
              let previousDouble = (previousValue as? NSString)?.doubleValue,
              previousDouble != 0 else {
            // Handle the case where conversion to double fails or previousValue is 0
            return 0
        }

        // Calculate percentage difference
        return ((currentDouble - previousDouble) / abs(previousDouble)) * 100
    }
    
    func configureCell(_ cell: pastMonthRidesCell, with object: pastMonthRides, hasData: Bool, isIncrease: Bool?, rowIndex: Int) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "de_DE")
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "MMMM yyyy"

        cell.monthLabel?.text = dateFormatter.string(from: object.date)
        cell.distanceLabel.text = object.totalDistace?.description
        cell.timeLabel.text = object.totalTimeElapsed?.description

        // Set the visibility of placeholderLabel based on hasData
        //cell.placeholderLabel.isHidden = hasData

        // Update distancePercentageArrow and timePercentageArrow based on increase or decrease
        if let isIncrease = isIncrease {
            if isIncrease {
                // Set arrow.up.forward.circle in systemGreen color
                cell.distancePercentageArrow.setImage(UIImage(systemName: "arrow.up.forward.circle"), for: .normal)
                cell.timePercentageArrow.setImage(UIImage(systemName: "arrow.up.forward.circle"), for: .normal)
                cell.distancePercentageArrow.tintColor = .systemGreen
                cell.timePercentageArrow.tintColor = .systemGreen
            } else {
                // Set arrow.down.forward.circle in systemRed color
                cell.distancePercentageArrow.setImage(UIImage(systemName: "arrow.down.forward.circle"), for: .normal)
                cell.timePercentageArrow.setImage(UIImage(systemName: "arrow.down.forward.circle"), for: .normal)
                cell.distancePercentageArrow.tintColor = .systemRed
                cell.timePercentageArrow.tintColor = .systemRed
            }
        } else {
            // Set arrow.right.circle in systemBlue color for the first entry
            cell.distancePercentageArrow.setImage(UIImage(systemName: "arrow.right.circle"), for: .normal)
            cell.timePercentageArrow.setImage(UIImage(systemName: "arrow.right.circle"), for: .normal)
            cell.distancePercentageArrow.tintColor = .systemBlue
            cell.timePercentageArrow.tintColor = .systemBlue
        }
    }




    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Add spacing between cells
        let spacing: CGFloat = 10
        cell.contentView.frame = cell.contentView.frame.inset(by: UIEdgeInsets(top: spacing, left: 0, bottom: spacing, right: 0))
    }
    
    
    // MARK: Set the gap between rows:
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90.0 // Set the height of the cell to be 10 points more than what you have specified in the Storyboard or programmatically
    }
}
