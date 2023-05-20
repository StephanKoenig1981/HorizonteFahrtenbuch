//
//  statsViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 20.05.23.
//

import UIKit
import RealmSwift

class statsViewController: UIViewController{
    
    
    @IBOutlet weak var totalTimeElapsedLabel: UILabel!
    @IBOutlet weak var totalDistanceDrivenLabel: UILabel!
    
    @IBOutlet weak var pastMonthsSummaryTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: Customizing UI
        
        pastMonthsSummaryTableView.layer.cornerRadius = 20
        pastMonthsSummaryTableView.backgroundColor = UIColor.clear
        
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
}
