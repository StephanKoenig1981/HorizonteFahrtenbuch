//
//  clientDetailViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 12.05.23.
//

import UIKit
import RealmSwift
import MapKit

class clientDetailViewController: UIViewController {

    @IBOutlet weak var clientDetailMapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clientDetailMapView.layer.cornerRadius = 20

        // Do any additional setup after loading the view.
    }
}
