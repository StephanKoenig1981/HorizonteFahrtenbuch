//
//  clientsTableViewCell.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 29.04.23.
//

import UIKit


class clientsTableViewCell: UITableViewCell {
    
    //create your closure here
             var buttonPressed : (() -> ()) = {}

            @IBAction func phoneButtonAction(_ sender: UIButton) {
        //Call your closure here
                buttonPressed()
            }
    
    
    @IBOutlet weak var background: UIView!

    @IBOutlet weak var clientNameLabel: UILabel!
    @IBOutlet weak var clientPostalCodeLabel: UILabel!
    @IBOutlet weak var clientPhoneLabel: UILabel!
    @IBOutlet weak var clientCityLabel: UILabel!
    @IBOutlet weak var clientStreetLabel: UILabel!
    @IBOutlet weak var clientsContactPersonLabel: UILabel!
    
    @IBOutlet weak var routeButton: UIButton!
    @IBOutlet weak var phoneButton: UIButton!
    
}

