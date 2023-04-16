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
    
    // MARK: Variables for Location determination
    
    var coordinates :[CLLocationCoordinate2D] = []
    var index = 0
    
    // MARK: Variables for the Timer
    
    var timer = Timer()
    
    var timerCounting:Bool = false
    
    var startTime:Date?
    var stopTime:Date?
    
    let START_TIME_KEY = "startTime"
    let STOP_TIME_KEY = "stopTime"
    let TRAVELED_DISTANCE_KEY = "traveledDistance"
    let COUNTING_KEY = "countingKey"
    
    var scheduledTimer: Timer!
    
    // MARK: Variables for NSUserDefaults and attributed text
    
    let userDefaults = UserDefaults.standard
    
    var attributedText: NSAttributedString?
    
    // MARK: Variables for travel distance
    
    let locationManager = CLLocationManager()
    let formatter = MKDistanceFormatter()
    
    var startLocation:CLLocation!
    var lastLocation: CLLocation!
    var traveledDistance:Double = 0
    
    var startDate: Date!
    
    // MARK: Outlets for Buttons and Views
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var timeElapsed: UILabel!
    @IBOutlet weak var distanceDriven: UILabel!
    @IBOutlet weak var baseToolbarView: UIView!
    @IBOutlet weak var TopNotchView: UIView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var locationButton: UIButton!
    
    // MARK: Outletts for Timer
    
    @IBOutlet weak var stopwatchResetButton: UIButton!
    
    
    // MARK: Base functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
                startTime = userDefaults.object(forKey: START_TIME_KEY) as? Date
                stopTime = userDefaults.object(forKey: STOP_TIME_KEY) as? Date
                timerCounting = userDefaults.bool(forKey: COUNTING_KEY)
                traveledDistance = (userDefaults.double(forKey: TRAVELED_DISTANCE_KEY) as Double)
                
                
                if timerCounting
                {
                    TopNotchView.topNotchViewfadeIn(duration: 0.5)
                    timeElapsed.fadeIn(duration: 0.5)
                    distanceDriven.fadeIn(duration: 0.5)
                    updateDistanceLabel()
                    startTimer()
                }
                else
                {
                    stopTimer()
                    if let start = startTime
                    {
                        if let stop = stopTime
                        {
                            let time = calcRestartTime(start: start, stop: stop)
                            let diff = Date().timeIntervalSince(time)
                            setTimeLabel(Int(diff))
                        }
                    }
                }
        
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        
        stopwatchResetButton.isEnabled = false
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector:  #selector(updateDistanceLabel), userInfo: nil, repeats: true)
        distanceDriven.text = "\(traveledDistance)"
    }
    
    // MARK: Travel distance and route polyline drawing function
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
            // Allow Background Updates for proper polyline drawing when not in foreground
        
            locationManager.allowsBackgroundLocationUpdates = true
            
            // Track Distance
        
            if startDate == nil {
                startDate = Date()
            } else {
                print("elapsedTime:", String(format: "%.0fs", Date().timeIntervalSince(startDate)))
            }
            if startLocation == nil {
                startLocation = locations.first
            } else if let location = locations.last {
                traveledDistance += lastLocation.distance(from: location)
                print("Traveled Distance:",  traveledDistance)
                print("Straight Distance:", startLocation.distance(from: locations.last!))
            }
            lastLocation = locations.last
        
            //Track Route
        
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
    
    // MARK: Base setup for drawing the polyline
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline{
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.systemOrange
            renderer.lineWidth = 8
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    // MARK: Stopwatch Functions and Update Traveled Distance
    
    func startTimer()
        {
            scheduledTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(refreshValue), userInfo: nil, repeats: true)
            setTimerCounting(true)
            startButton.setImage(UIImage(named: "RedButtonHighRes.png"), for: .normal)
        }
    
    func calcRestartTime(start: Date, stop: Date) -> Date
        {
            let diff = start.timeIntervalSince(stop)
            return Date().addingTimeInterval(diff)
        }
    
    @objc func refreshValue()
    {
        if let start = startTime
        {
            let diff = Date().timeIntervalSince(start)
            setTimeLabel(Int(diff))
        }
        else
        {
            stopTimer()
            setTimeLabel(0)
        }
    }
    
    func setTimeLabel(_ val: Int)
    {
        let time = secondsToHoursMinutesSeconds(val)
        let timeString = makeTimeString(hour: time.0, min: time.1, sec: time.2)
        timeElapsed.text = timeString
        timeElapsed.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        distanceDriven.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
    }
    
    func secondsToHoursMinutesSeconds(_ ms: Int) -> (Int, Int, Int)
    {
        let hour = ms / 3600
        let min = (ms % 3600) / 60
        let sec = (ms % 3600) % 60
        return (hour, min, sec)
    }
    
    func makeTimeString(hour: Int, min: Int, sec: Int) -> String
    {
        var timeString = ""
        timeString += String(format: "%02d", hour)
        timeString += ":"
        timeString += String(format: "%02d", min)
        timeString += ":"
        timeString += String(format: "%02d", sec)
        return timeString
    }
    
    func stopTimer()
    {
        if scheduledTimer != nil
        {
            scheduledTimer.invalidate()
        }
        setTimerCounting(false)
        startButton.setImage(UIImage(named: "GreenButtonHighRes.png"), for: .normal)
    }
    
    func setStartTime(date: Date?)
        {
            startTime = date
            userDefaults.set(startTime, forKey: START_TIME_KEY)
        }
        
        func setStopTime(date: Date?)
        {
            stopTime = date
            userDefaults.set(stopTime, forKey: STOP_TIME_KEY)
            userDefaults.set(traveledDistance, forKey: TRAVELED_DISTANCE_KEY)
        }
        
        func setTimerCounting(_ val: Bool)
        {
            timerCounting = val
            userDefaults.set(timerCounting, forKey: COUNTING_KEY)
        }
    
    
    @objc func updateDistanceLabel() {

        formatter.units = .metric
        formatter.unitStyle = .default
        
        let distanceString = formatter.string(fromDistance: traveledDistance)
        distanceDriven.text = distanceString
        
        self.distanceDriven.text = "\(distanceString)"
        
    }

    
    // MARK: Start Button Action

    @IBAction func start(_sender: UIButton) {
        
        if timerCounting
                {
                    setStopTime(date: Date())
                    stopTimer()
                }
                else
                {
                    if let stop = stopTime
                    {
                        let restartTime = calcRestartTime(start: startTime!, stop: stop)
                        setStopTime(date: nil)
                        setStartTime(date: restartTime)
                        
                    }
                    else
                    {
                        setStartTime(date: Date())
                    }
                    startTimer()
                }
        
        TopNotchView.topNotchViewfadeIn(duration: 1.0)
        timeElapsed.fadeIn(duration: 1.0)
        distanceDriven.fadeIn(duration: 1.0)
        
        
        stopwatchResetButton.fadeIn(duration: 0.5)
        
        // Testing disabling the screen sleep mode while recording a ride
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.distanceFilter = 5
        
        timeElapsed.fadeOut(duration: 1.0)
        timeElapsed.textColor = UIColor.orange
        timeElapsed.fadeIn(duration: 1.0)
        
        distanceDriven.fadeOut(duration:1.0)
        distanceDriven.textColor = UIColor.orange
        distanceDriven.fadeIn(duration: 1.0)
        
        stopwatchResetButton.isEnabled = true
        
        startButton.ButtonViewfadeOut(duration: 0.5)
        startButton.isEnabled = true
        startButton.ButtonViewfadeIn(duration: 0.5)
        
        formatter.units = .metric
        formatter.unitStyle = .default
        
        let distanceString = formatter.string(fromDistance: traveledDistance)
        distanceDriven.text = distanceString
    
        
        print (traveledDistance)
    }
    
    // MARK: Stop Button Action
    
    @IBAction func stopButtonPressed(_ sender: Any) {
        
        TopNotchView.topNotchViewfadeOut(duration: 1.0)
        timeElapsed.fadeOut(duration: 1.0)
        distanceDriven.fadeOut(duration: 1.0)
        
        stopwatchResetButton.fadeOut(duration: 0.5)
        
        startButton.ButtonViewfadeOut(duration: 0.5)
        startButton.setImage(UIImage(named: "GreenButtonHighRes.png"), for: .normal)
        startButton.ButtonViewfadeIn(duration: 0.5)
        
        // Testing disabling the screen sleep mode while recording a ride (Reenabling sleep when stop is pressed)
        
        UIApplication.shared.isIdleTimerDisabled = false
        
        // Stopping Location Updates to save battery
        
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        
        // Animations of the views and labels.
        
        timeElapsed.fadeOut(duration: 0.5)
        timeElapsed.text = "00:00:00"
        distanceDriven.text = "00.00 Km"
        timeElapsed.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        
        distanceDriven.fadeOut(duration: 0.5)
        distanceDriven.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        
        stopwatchResetButton.isEnabled = false
        
        // Reset traveled distance to 0 and apply on Label
        
        self.mapView.removeOverlays(self.mapView.overlays)
        
        coordinates.removeAll()
        
        startLocation = nil
        traveledDistance -= traveledDistance
        distanceDriven.text = "0 m"
        
        // Reset Timer to Zero
        
        setStopTime(date: nil)
        setStartTime(date: nil)
        timeElapsed.text = makeTimeString(hour: 0, min: 0, sec: 0)
        stopTimer()
    }
    
    // MARK: Function for Location and Heading Tracking
    
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


