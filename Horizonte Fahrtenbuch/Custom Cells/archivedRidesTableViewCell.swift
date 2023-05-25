//
//  archivedRidesTableViewCell.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 25.05.23.
//

import UIKit

class archivedRidesTableviewCell: UITableViewCell {
    
    //create your closure here
            var routeDetailButtonPressed : (() -> ()) = {}
    
    @IBAction func routeDetailButtonPressed(_ sender: UIButton) {
            routeDetailButtonPressed()
}
    
    func configure(data: archivedRides) {
    }

    @IBOutlet weak var background: UIView!
    
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    @IBOutlet weak var rideClientLabel: UILabel!
    @IBOutlet weak var supplementDateLabel: UILabel!
    @IBOutlet weak var circleSign: UIButton!
    
    @IBOutlet weak var routeDetailButton: UIButton!
    
    @IBOutlet weak var gradientBackgroundView: UIImageView!
    
}
