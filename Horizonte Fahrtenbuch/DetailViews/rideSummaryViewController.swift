//
//  rideSummaryViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 19.04.23.
//

import UIKit
import MapKit

var MainMapViewController: MainMapViewViewController?
var drivenDistanceText = ""
var elapsedTimeText = ""



class rideSummaryViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: Outlets
    
    @IBOutlet weak var rideSummaryMapView: MKMapView!
    
    @IBOutlet weak var rideSummaryTitle: UILabel!
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    @IBOutlet weak var drivenDistanceLabel: UILabel!
    @IBOutlet weak var drivenDistance: UILabel!
    @IBOutlet weak var elapsedTime: UILabel!
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UI Customization
        
        rideSummaryMapView.layer.cornerRadius = 20
        rideSummaryTitle.textColor = UIColor.orange
        
        elapsedTimeLabel.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        elapsedTime.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        drivenDistanceLabel.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        drivenDistance.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        
        // Do any additional setup after loading the view.
        
        
    }
}

