//
//  rideSummaryViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 19.04.23.
//

import UIKit
import MapKit

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
        
        rideSummaryMapView.layer.cornerRadius = 20
    

        // Do any additional setup after loading the view.
    }


}
