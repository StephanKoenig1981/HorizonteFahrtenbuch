//
//  ViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 20.03.23.
//

import UIKit
import MapKit
import CoreLocation
import ActivityKit
import SwiftUI


// MARK: Struct for Live Activities

struct ActivityAttributesSample: ActivityAttributes {
    public typealias Status = ContentState
    public struct ContentState: Codable, Hashable {
        var value: String
    }
}

// MARK: Extension for converting doubles to strings

extension Double {
    func toString() -> String {
        return String(format: "%.1f",self)
    }
}

// MARK: Flashing Label Extension

extension UIView{
     func blink() {
         self.alpha = 0.2
         UIView.animate(withDuration: 1, delay: 0.0, options: [.curveLinear, .repeat, .autoreverse], animations: {self.alpha = 1.0}, completion: nil)
     }
}

// MARK: Fade In and Fade Out Extension

extension UIView {
    
/**
 Fade in a view with a duration
 
 - parameter duration: custom animation duration
 */
 func fadeIn(duration: TimeInterval = 1.0) {
     UIView.animate(withDuration: duration, animations: {
        self.alpha = 1.0
     })
 }
    
    func topNotchViewfadeIn(duration: TimeInterval = 1.0) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0.7
        })
    }
    
    func ButtonViewfadeIn(duration: TimeInterval = 1.0) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1.0
        })
    }
    
    func textFieldViewfadeIn(duration: TimeInterval = 1.0) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0.9
        })
    }
    
    func fadeDelieryViewIn(duration: TimeInterval = 0.5) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0.7
        })
    }

/**
 Fade out a view with a duration
 
 - parameter duration: custom animation duration
 */
    func fadeOut(duration: TimeInterval = 1.0) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0.0
        })
    }
    
    func topNotchViewfadeOut(duration: TimeInterval = 1.0) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0.0
        })
      }
    
    func ButtonViewfadeOut(duration: TimeInterval = 1.0) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0.0
        })
      }
    
    func fadeDeliveryViewOut(duration: TimeInterval = 1.0) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0.0
        })
      }

}


class ViewController: UIViewController, CLLocationManagerDelegate {
    
    // MARK: Variables
    
    var locationManager: CLLocationManager?
    
    
    // MARK: Outlets
    
    @IBOutlet weak var WelcomeText: UITextView!
    @IBOutlet weak var ConfigureText: UITextView!
    @IBOutlet weak var HorizonteLogo: UIImageView!
    
    @IBOutlet weak var GrantGPSAccessButton: UIButton!
    
    @IBOutlet weak var AllSetLogo: UIImageView!
    
    @IBOutlet weak var ProceedButton: UIButton!
    
    // MARK: Base Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        HorizonteLogo.fadeIn(duration: 2.0)
        WelcomeText.fadeIn(duration: 2.2)
        ConfigureText.fadeIn(duration: 2.6)
        
        GrantGPSAccessButton.fadeIn(duration: 2.9)
        
    }
    
    // MARK: Logic for showing configuration screen or hide it if GPS Access is already granted.
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let manager = CLLocationManager()
        
        switch manager.authorizationStatus {
        case .restricted:
            pushLoginView((Any).self)
        case .denied:
            pushLoginView((Any).self)
            let alert = UIAlertController(title: "GPS Zugriff verweigert", message: "Wie es scheint ist der GPS Zugriff verweigert. \n\n Bitte kontrolliere den Zugriff in den Einstellungen -> Datenschutz & Sicherheit -> Ortungsdienste -> Fahrtenbuch", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                
                switch action.style{
                    
                    case .default:
                    print("default")
                    
                    case .cancel:
                    print("cancel")
                    
                    case .destructive:
                    print("destructive")
                    
                @unknown default:
                    print("Unknown Fault")
                }
            }))
            self.present(alert, animated: true, completion: nil)
            
            GrantGPSAccessButton.isEnabled = false
            GrantGPSAccessButton.setTitle("GPS Nutzung verweigert", for: .disabled)
            
            AllSetLogo.image = UIImage(named:"Cross")
            AllSetLogo.fadeIn(duration: 1.0)
            
        case .authorizedAlways:
            performSegue(withIdentifier: "MainMapViewSegue", sender: self)
        case .notDetermined:
            print("Didn't request permission for User Location")
        case .authorizedWhenInUse:
            performSegue(withIdentifier: "MainMapViewSegue", sender: self)
        @unknown default:
            print("Didn't request permission for User Location")
        }
    }
    
    // MARK: Function for pushing to the main map view controller if GPS Access is already granted
    
    func pushLoginView(_ sender: Any) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "EntryView") as? ViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    // Function for HealthKit Access
    
    func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Swift.Void) {
        
    }
    
    
    // MARK: IBActions
    
    @IBAction func GrantGPSAccesButtonPressed(_ sender: Any) {
        
        // Ask for Core Location Access
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        
        // Ask if user wants to change to always grant GPS Access
        
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.requestAlwaysAuthorization()
        
        // Depending on what the user chooses, change the behaviour of the buttons
        
        switch locationManager? .authorizationStatus {
        case .denied:
            let alert = UIAlertController(title: "GPS Zugriff verweigert", message: "Wie es scheint ist der GPS Zugriff verweigert. \n\n Bitte kontrolliere den Zugriff in den Einstellungen -> Datenschutz & Sicherheit -> Ortungsdienste -> Fahrtenbuch", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                
                switch action.style{
                    
                    case .default:
                    print("default")
                    
                    case .cancel:
                    print("cancel")
                    
                    case .destructive:
                    print("destructive")
                    
                @unknown default:
                    print("Unknown Fault")
                }
            }))
            self.present(alert, animated: true, completion: nil)
            
            GrantGPSAccessButton.isEnabled = false
            GrantGPSAccessButton.setTitle("GPS Nutzung verweigert", for: .disabled)
            
            AllSetLogo.image = UIImage(named:"Cross")
            AllSetLogo.fadeIn(duration: 1.0)
        case .authorizedAlways:
            GrantGPSAccessButton.isEnabled = false
            GrantGPSAccessButton.setTitle("GPS Nutzung erlaubt", for: .disabled)
            AllSetLogo.fadeIn(duration: 1.0)
            print("GPS permanently granted")
        case .authorizedWhenInUse:
            GrantGPSAccessButton.isEnabled = false
            GrantGPSAccessButton.setTitle("GPS Nutzung erlaubt", for: .disabled)
            AllSetLogo.fadeIn(duration: 1.0)
            ProceedButton.fadeIn(duration: 1.0)
            print("GPS Granted when in use")
        case .notDetermined:
            print("not determined")
        case .some(.restricted):
            GrantGPSAccessButton.isEnabled = false
            
            GrantGPSAccessButton.setTitle("GPS Nutzung verweigert", for: .disabled)
            
            AllSetLogo.image = UIImage(named:"Cross")
            AllSetLogo.fadeIn(duration: 1.0)
            print("GPS Access was denied")
        case .some(_):
            print("Fallback")
        case .none:
            print("None")
        }
    }

    
    @IBAction func ProceedButtonPressed(_ sender: Any) {
        print("Procedded to the main Map View")
    }
}
