//
//  MainMapViewViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 23.03.23.
//

import UIKit
import MapKit
import CoreLocation
import Combine

class MainMapViewViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var locationManager: CLLocationManager?
    
    var timer = Timer()
    var (hours, minutes, seconds, fractions) = (0, 0, 0, 0)
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var timeElapsed: UILabel!
    @IBOutlet weak var distanceDriven: UILabel!
    @IBOutlet weak var baseToolbarView: UIView!
    @IBOutlet weak var TopNotchView: UIView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var locationButton: UIButton!
    
    // Outletts for Timer
    
    @IBOutlet weak var stopwatchPauseButton: UIButton!
    @IBOutlet weak var stopwatchResetButton: UIButton!
    
    // MARK: Base Setup for the main map view
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        TopNotchView.layer.cornerRadius = 20
        
        mapView.delegate = self
        
        // Basic Map Setup
        
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = false
        mapView.showsTraffic = true
        
        //mapview setup to show user location
        
        mapView.delegate = self
        mapView.mapType = MKMapType(rawValue: 0)!
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        
        
        
    }
    
    // MARK: Base setup for the Overlay renderer
    
    
    // MARK: Stopwatch Function
    
    @objc func keepTimer() {
        seconds += 1
        
        if seconds == 60 {
            minutes += 1
            seconds = 0
        }
        
        if minutes == 60 {
            hours += 1
            minutes = 0
        }
        
        let secondsString = seconds > 9 ? "\(seconds)" : "0\(seconds)"
        let minutesString = minutes > 9 ? "\(minutes)" : "0\(minutes)"
        let hoursString = hours > 9 ? "\(hours)" : "0\(hours)"
        
        // Update label outside of main thread
        
        DispatchQueue.main.async {
            self.timeElapsed.text = "\(hoursString):\(minutesString):\(secondsString)"
        }
    }
    
    @objc func pauseTimer() {
        timer.invalidate()
    }
    
    // MARK: Stopwatch Function Buttons

    @IBAction func start(_sender: UIButton) {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(MainMapViewViewController.keepTimer), userInfo: nil, repeats: true)
            startButton.isEnabled = false
    }
    
    @IBAction func pauseButtonPressed(_ sender: Any) {
        timer.invalidate()
        startButton.isEnabled = true
    }
    
    @IBAction func stopButtonPressed(_ sender: Any) {
        timer.invalidate()
        (hours, minutes, seconds, fractions) = (0, 0, 0, 0)
        timeElapsed.text = "00:00:00"
        startButton.isEnabled = true
    }
    
    @IBAction func locationButtonPressed(_ sender: Any) {
        
        // Re-Enable heading mode
        
        mapView.setUserTrackingMode(.followWithHeading, animated:true)
        
        //Zoom to user location
        
        if let userLocation = locationManager?.location?.coordinate {
            let viewRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 200, longitudinalMeters: 200)
                mapView.setRegion(viewRegion, animated: true)
            }

            DispatchQueue.main.async {
                self.locationManager?.startUpdatingLocation()
            }
        
    }
}

