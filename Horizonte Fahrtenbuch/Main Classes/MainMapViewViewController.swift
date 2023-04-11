//
//  MainMapViewViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 23.03.23.
//

import UIKit
import MapKit
import CoreLocation
import CoreMotion
import Combine

class MainMapViewViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    
    var coordinates :[CLLocationCoordinate2D] = []
    var index = 0
    
    // Variables for the Timer
    
    var timer = Timer()
    var (hours, minutes, seconds, fractions) = (0, 0, 0, 0)
    
    var timerCounting:Bool = false
    
    var startTime:Date?
    var stopTime:Date?
    let userDefaults = UserDefaults.standard
    
    let START_TIME_KEY = "startTime"
    let STOP_TIME_KEY = "stopTime"
    let COUNTING_KEY = "countingKey"
    
    var attributedText: NSAttributedString?
    
    let locationManager = CLLocationManager()
    
    // Variables for travel distance
    
    let formatter = MKDistanceFormatter()
    
    var startLocation:CLLocation!
    var lastLocation: CLLocation!
    var traveledDistance:Double = 0
    
    // Outlets for Buttons and Views
    
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
        
        baseToolbarView.topNotchViewfadeIn(duration: 1.0)
        startButton.ButtonViewfadeIn(duration: 1.0)
        locationButton.ButtonViewfadeIn(duration:1.0)
        
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        stopwatchPauseButton.isEnabled = false
        stopwatchResetButton.isEnabled = false
        
        startTime = userDefaults.object( forKey: START_TIME_KEY) as? Date
        stopTime = userDefaults.object( forKey: STOP_TIME_KEY) as? Date
        timerCounting = userDefaults.bool( forKey: COUNTING_KEY)
        
        TopNotchView.layer.cornerRadius = 20
        
        mapView.delegate = self
        
        // Basic Map Setup
        
        mapView.showsCompass = true
        mapView.showsScale = false
        mapView.showsTraffic = true
        
        //mapview setup to show user location
        
        mapView.delegate = self
        mapView.mapType = MKMapType(rawValue: 0)!
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        
    }
        
    // MARK: Base setup for drawing the polyline
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            
            coordinates.append (location.coordinate)
            
            let numberOfLocations = coordinates.count
            print (" :-) \(numberOfLocations)")
            
            if numberOfLocations > 5{
            var pointsToConnect = [coordinates[numberOfLocations - 1], coordinates[numberOfLocations - 2]]
                
            let polyline = MKPolyline(coordinates: &pointsToConnect, count: pointsToConnect.count)
                
            mapView.addOverlay(polyline)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline{
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.systemOrange
            renderer.lineWidth = 8
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    // MARK: Travel distance function
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if startLocation == nil {
            startLocation = (locations.first as! CLLocation)
        } else {
            let lastLocation = locations.last as! CLLocation
            let distance = startLocation.distance(from: lastLocation)
            startLocation = lastLocation
            traveledDistance += distance
        }
    }
    
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
        
        TopNotchView.topNotchViewfadeIn(duration: 1.0)
        timeElapsed.fadeIn(duration: 1.0)
        distanceDriven.fadeIn(duration: 1.0)
        
        stopwatchPauseButton.fadeIn(duration: 0.5)
        stopwatchResetButton.fadeIn(duration: 0.5)
        
        // Testing disabling the screen sleep mode while recording a ride
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.distanceFilter = 5
        
        timeElapsed.fadeOut(duration: 1.0)
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(MainMapViewViewController.keepTimer), userInfo: nil, repeats: true)
        timeElapsed.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        timeElapsed.fadeIn(duration: 1.0)
        
        distanceDriven.fadeOut(duration:1.0)
        distanceDriven.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        distanceDriven.fadeIn(duration: 1.0)
        
        stopwatchPauseButton.isEnabled = true
        stopwatchResetButton.isEnabled = true
        
        startButton.ButtonViewfadeOut(duration: 0.5)
        startButton.isEnabled = false
        startButton.setImage(UIImage(named: "RedButtonHighRes.png"), for: .disabled)
        startButton.ButtonViewfadeIn(duration: 0.5)
        
        formatter.units = .metric
        formatter.unitStyle = .default
        
        let distanceString = formatter.string(fromDistance: traveledDistance)
        distanceDriven.text = distanceString
        
        print (traveledDistance)
    }
    
    @IBAction func pauseButtonPressed(_ sender: Any) {
        
        // Testing disabling the screen sleep mode while recording a ride (Reenabling sleep when pause is pressed
        
        UIApplication.shared.isIdleTimerDisabled = false
        
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        
        timeElapsed.fadeOut(duration: 1.0)
        timeElapsed.textColor = UIColor.orange
        timeElapsed.fadeIn(duration: 1.0)
        
        distanceDriven.fadeOut(duration: 1.0)
        distanceDriven.textColor = UIColor.orange
        distanceDriven.fadeIn(duration: 1.0)
        
        stopwatchPauseButton.fadeOut(duration: 0.5)
        stopwatchPauseButton.fadeIn(duration: 0.5)
        stopwatchResetButton.fadeOut(duration: 0.5)
        stopwatchResetButton.fadeIn(duration: 0.5)
        
        timer.invalidate()
        startButton.isEnabled = true
        stopwatchPauseButton.isEnabled = false
        
        startButton.ButtonViewfadeOut(duration: 0.5)
        startButton.setImage(UIImage(named: "GreenButtonHighRes.png"), for: .normal)
        startButton.ButtonViewfadeIn(duration: 0.5)
    }
    
    @IBAction func stopButtonPressed(_ sender: Any) {
        
        TopNotchView.topNotchViewfadeOut(duration: 1.0)
        timeElapsed.fadeOut(duration: 1.0)
        distanceDriven.fadeOut(duration: 1.0)
        
        stopwatchPauseButton.fadeOut(duration: 0.5)
        stopwatchResetButton.fadeOut(duration: 0.5)
        
        startButton.ButtonViewfadeOut(duration: 0.5)
        startButton.setImage(UIImage(named: "GreenButtonHighRes.png"), for: .normal)
        startButton.ButtonViewfadeIn(duration: 0.5)
        
        // Testing disabling the screen sleep mode while recording a ride (Reenabling sleep when stop is pressed)
        
        UIApplication.shared.isIdleTimerDisabled = false
        
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        
        mapView.removeOverlays(mapView.overlays)
        
        timer.invalidate()
        (hours, minutes, seconds, fractions) = (0, 0, 0, 0)
        timeElapsed.fadeOut(duration: 1.0)
        timeElapsed.text = "00:00:00"
        distanceDriven.text = "00.00 Km"
        timeElapsed.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        startButton.isEnabled = true
        
        distanceDriven.fadeOut(duration: 1.0)
        distanceDriven.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        distanceDriven.fadeIn(duration: 1.0)
        
        stopwatchPauseButton.isEnabled = true
        timeElapsed.fadeIn(duration: 1.0)
        stopwatchResetButton.isEnabled = false
        stopwatchPauseButton.isEnabled = false
    }
    
    @IBAction func locationButtonPressed(_ sender: Any) {
        
        // Re-Enable heading mode
                
                mapView.setUserTrackingMode(.followWithHeading, animated:true)
                
                //Zoom to user location
        
        if let userLocation = locationManager.location?.coordinate {
                   let viewRegion = MKCoordinateRegion(center: userLocation, latitudinalMeters: 200, longitudinalMeters: 200)
                       mapView.setRegion(viewRegion, animated: true)
                   }
           }
    }


