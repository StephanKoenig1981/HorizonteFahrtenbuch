//
//  rideSummaryViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 19.04.23.
//

import UIKit
import MapKit
import RealmSwift

extension DefaultStringInterpolation {
  mutating func appendInterpolation<T>(_ optional: T?) {
    appendInterpolation(String(describing: optional))
  }
}

class rideSummaryViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: Initializing Realm

    let realm = try! Realm()
    
    let currentRides = currentRide()

    
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
        
        // Disable Swipe Down gesture
        
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        }
        
        let vc = UIViewController()
        vc.presentationController?.presentedView?.gestureRecognizers?[0].isEnabled = false
        
        // UI Customization
        
        rideSummaryMapView.layer.cornerRadius = 20
        rideSummaryTitle.textColor = UIColor.orange
        
        elapsedTimeLabel.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        drivenDistanceLabel.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        
        // MARK: Updating Label from Realm Database value (Currently showing NIL)
        
        elapsedTime.text = currentRides.timeElapsed?.description
        drivenDistance.text = currentRides.distanceDriven?.description
    
        
        elapsedTime.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        drivenDistance.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)

        
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    // MARK: Cancel Button
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Bist du sicher?", message: "Bist du sicher, dass du abbrechen möchtest ohne die Fahrt zu speichern?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Fortfahren", style: .cancel))
        alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: { action in
            
            switch action.style{
                
                case .default:
                print("default")
                
                case .cancel:
                self.dismiss(animated: true)
                
                case .destructive:
                self.dismiss(animated: true)
                
            @unknown default:
                print("Unknown Fault")
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: Save Button
    
    @IBAction func saveButtonPressed(_ sender: Any) {
    }
}

