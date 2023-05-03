//
//  MainMapViewViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 23.03.23.
//

import UIKit
import RealmSwift
import MapKit
import CoreLocation
import CoreMotion
import Combine
import ActivityKit


class MainMapViewViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UITextFieldDelegate {
    
    
    // MARK: Variables for Location determination
    
    var coordinates :[CLLocationCoordinate2D] = []
    var index = 0
    
    var isWayBack:Bool = false
    
    
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
    @IBOutlet weak var pauseStateLabel: UILabel!
    @IBOutlet weak var wayBackButton: UIButton!
    @IBOutlet weak var wayBackButtonView: UIView!
    @IBOutlet weak var menuButtonView: UIView!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var addContactButtonView: UIView!
    @IBOutlet weak var addContactButton: UIButton!
    @IBOutlet weak var addressBookButtonView: UIView!
    @IBOutlet weak var addressBookButton: UIButton!
    @IBOutlet weak var settingsButtonView: UIView!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var clientTextFieldView: UIView!
    @IBOutlet weak var clientTextField: UITextField!
    
    // MARK: Outlets for the Segmented control view and segmented control
    
    @IBOutlet weak var segmentedControlView: UIView!
    @IBOutlet weak var mapTypeSelector: UISegmentedControl!
    
    // MARK: Outletts for Timer
    
    @IBOutlet weak var stopwatchResetButton: UIButton!

    
    // MARK: Base functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize Realm and print Realm Database file URL
        
        
        lazy var realm:Realm = {
            return try! Realm()
        }()
        print (Realm.Configuration.defaultConfiguration.fileURL!)
        
        // Delegate for the client textfield
        
        clientTextField.delegate = self
        
        // Customizing customer TextField
        
        clientTextField.attributedPlaceholder = NSAttributedString(
            string: "Kunde eingeben",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemOrange.withAlphaComponent(0.9)]
        )
        
            // Mask Corner Radius for segmented control View
        
                menuButtonView.layer.cornerRadius = 25
                menuButton.tintColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        
                addContactButtonView.layer.cornerRadius = 25
                addContactButton.tintColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        
                addressBookButtonView.layer.cornerRadius = 25
                addressBookButton.tintColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        
                settingsButtonView.layer.cornerRadius = 25
                settingsButton.tintColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        
                segmentedControlView.clipsToBounds = true
                segmentedControlView.layer.cornerRadius = 15
                segmentedControlView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        
            // MASK Corner Radius for Textfield View
        
                clientTextFieldView.layer.cornerRadius = 20
                clientTextFieldView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
            // Customizing the Maptype Selector
        
                mapTypeSelector.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
        
                mapTypeSelector.selectedSegmentTintColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
                let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
                mapTypeSelector.setTitleTextAttributes(titleTextAttributes, for:.selected)
        
                wayBackButton.sendActions(for: .touchUpInside)
        
            // Saving NSUserDefault Keys
        
                startTime = userDefaults.object(forKey: START_TIME_KEY) as? Date
                stopTime = userDefaults.object(forKey: STOP_TIME_KEY) as? Date
                timerCounting = userDefaults.bool(forKey: COUNTING_KEY)
                traveledDistance = (userDefaults.double(forKey: TRAVELED_DISTANCE_KEY) as Double)
                
                pauseStateLabel.fadeIn(duration: 2.0)
                pauseStateLabel.text = "Bereit"
                pauseStateLabel.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        
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
        
        TopNotchView.layer.cornerRadius = 10
        wayBackButtonView.layer.cornerRadius = 10
        
        mapView.delegate = self
        mapView.clipsToBounds = true
        
        // Basic Map Setup
        
        mapView.showsCompass = true
        mapView.showsScale = false
        mapView.showsTraffic = true
        
        //mapview setup to show user location
        
        mapView.delegate = self
        mapView.mapType = MKMapType(rawValue: 0)!
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        
    }
    
    // MARK: Hickup workaround code to hide keyboard when return is pressed
    
    override func viewWillDisappear(_ animated: Bool) {
        super .viewWillDisappear(true)
        self.view.endEditing(true)
    }

    // MARK: Functions for keyboard actions
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    
    func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
            self.view.endEditing(true)
        }
    
    
    override func viewDidAppear(_ animated: Bool) {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector:  #selector(updateDistanceLabel), userInfo: nil, repeats: true)
        distanceDriven.text = "\(traveledDistance)"
    }
    
    
    // MARK: Travel distance and route polyline drawing function
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
            // Allow Background Updates for proper polyline drawing when not in foreground
        
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
            
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
            
            // Change the stroke color depending on if it's on the way back or not. (Color is inverted since button was pressed programatically before.
            
            if isWayBack == false {
                renderer.strokeColor = UIColor.systemCyan
            } else if isWayBack == true {
                renderer.strokeColor = UIColor.systemOrange
            }
            renderer.lineWidth = 6
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
    
    // MARK: Function for finally saving client to database
    
    func saveRealmObject(currentRides:currentRide) {
            let realm = try? Realm()
            try? realm?.write {
                realm?.add(currentRides)
            }
            print("Data Was Saved To Realm Database.")
    }

    
    // MARK: Start Button Action

    @IBAction func start(_sender: UIButton) {
        
        if timerCounting
                {
                    pauseStateLabel.fadeIn(duration: 2.0)
                    pauseStateLabel.text = "Pausiert"
                    pauseStateLabel.textColor = UIColor.orange
                    pauseStateLabel.blink()
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
                        pauseStateLabel.fadeIn(duration: 2.0)
                        
                        pauseStateLabel.text = "Aufzeichnen"
                        pauseStateLabel.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
                        pauseStateLabel.blink()
                        setStartTime(date: Date())
                    }
                    pauseStateLabel.fadeIn(duration: 2.0)
                    
                    pauseStateLabel.text = "Aufzeichnen"
                    pauseStateLabel.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
                    pauseStateLabel.blink()
                    startTimer()
                }
        
        TopNotchView.topNotchViewfadeIn(duration: 1.0)
        timeElapsed.fadeIn(duration: 1.0)
        distanceDriven.fadeIn(duration: 1.0)
        
        wayBackButtonView.topNotchViewfadeIn(duration: 1.0)
        wayBackButton.fadeIn(duration: 1.0)
        
        
        wayBackButton.setTitleColor(UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0), for: .normal)
        
        
        stopwatchResetButton.fadeIn(duration: 0.5)
        
        clientTextFieldView.fadeOut(duration: 0.5)
        
        // Testing disabling the screen sleep mode while recording a ride
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        locationManager.startUpdatingLocation()
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
        
        if clientTextField.text == "" {
            wayBackButton.setTitle("Kein Ziel", for: .normal)
            wayBackButton.setTitleColor(.systemOrange, for: .normal)
        } else {
            wayBackButton.setTitle(clientTextField.text, for: .normal)
        }
        
        print (traveledDistance)
    }
    
    // MARK: Stop Button Action
    
    @IBAction func stopButtonPressed(_ sender: Any) {
        
        let alert = UIAlertController(title: "Bist du sicher?", message: "Bist du sicher, dass du abbrechen möchtest ohne die Fahrt zu speichern?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Fortsetzen", style: .cancel))
        alert.addAction(UIAlertAction(title: "Ohne speichern beenden", style: .destructive, handler: { [self]_ in
            
            
            TopNotchView.topNotchViewfadeOut(duration: 1.0)
            timeElapsed.fadeOut(duration: 1.0)
            distanceDriven.fadeOut(duration: 1.0)
            
            clientTextFieldView.fadeIn(duration: 1.0)
            
            // Resetting client Text field for a new ride
            
            clientTextField.text = ""
            
            stopwatchResetButton.fadeOut(duration: 0.5)
            
            startButton.ButtonViewfadeOut(duration: 0.5)
            startButton.setImage(UIImage(named: "GreenButtonHighRes.png"), for: .normal)
            startButton.ButtonViewfadeIn(duration: 0.5)
            
            // Testing disabling the screen sleep mode while recording a ride (Reenabling sleep when stop is pressed)
            
            UIApplication.shared.isIdleTimerDisabled = false
            
            // Stopping Location Updates to save battery
            
            locationManager.stopUpdatingLocation()
            
            // Animations of the views and labels.
            
            timeElapsed.fadeOut(duration: 0.5)
            timeElapsed.text = "00:00:00"
            distanceDriven.text = "00.00 Km"
            timeElapsed.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
            
            distanceDriven.fadeOut(duration: 0.5)
            distanceDriven.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
            
            wayBackButtonView.topNotchViewfadeOut(duration: 1.0)
            wayBackButton.fadeOut(duration: 1.0)
            
            wayBackButton.setTitle("Kein Ziel", for: .normal)
            wayBackButton.setTitleColor(UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0), for: .normal)
            isWayBack = false
            
            wayBackButton.sendActions(for: .touchUpInside)
            
            stopwatchResetButton.isEnabled = false
            
            // Reset traveled distance to 0 and apply on Label
            
            mapView.removeOverlays(self.mapView.overlays)
            
            coordinates.removeAll()
            
            startLocation = nil
            traveledDistance -= self.traveledDistance
            distanceDriven.text = "0 m"
            
            // Reset Timer to Zero
            
            setStopTime(date: nil)
            setStartTime(date: nil)
            timeElapsed.text = makeTimeString(hour: 0, min: 0, sec: 0)
            stopTimer()
            
            locationManager.allowsBackgroundLocationUpdates = false
            locationManager.pausesLocationUpdatesAutomatically = true
            
            // Reset status label to Ready when stop is pressed and change color to green
            
            pauseStateLabel.fadeOut(duration: 2.0)
            pauseStateLabel.text = "Bereit"
            pauseStateLabel.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
            pauseStateLabel.fadeIn(duration: 2.0)
            
            print ("Data was not saved to Realm")

        }))
        alert.addAction(UIAlertAction(title: "Speichern und beenden", style: .destructive, handler: { [self] action in
            
            switch action.style{
                
                case .default:
                print("default")
                
                case .cancel:
                self.dismiss(animated: true)
                
                case .destructive:
                
                TopNotchView.topNotchViewfadeOut(duration: 1.0)
                timeElapsed.fadeOut(duration: 1.0)
                distanceDriven.fadeOut(duration: 1.0)
                
                stopwatchResetButton.fadeOut(duration: 0.5)
                
                startButton.ButtonViewfadeOut(duration: 0.5)
                startButton.setImage(UIImage(named: "GreenButtonHighRes.png"), for: .normal)
                startButton.ButtonViewfadeIn(duration: 0.5)
                
                clientTextFieldView.fadeIn(duration: 1.0)
                
                // Testing disabling the screen sleep mode while recording a ride (Reenabling sleep when stop is pressed)
                
                UIApplication.shared.isIdleTimerDisabled = false
                
                // MARK: Initializing Realm
                
                lazy var realm:Realm = {
                    return try! Realm()
                }()
                
                let currentRides = currentRide()
                
                let date = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "d. MMM YY"
                dateFormatter.dateStyle = .long
                
                dateFormatter.string(from: date)
                
                currentRides.timeElapsed = timeElapsed.text
                currentRides.distanceDriven = distanceDriven.text
                currentRides.date = dateFormatter.string(from: date)
                currentRides.currentClientName = clientTextField.text
               
                
                saveRealmObject(currentRides: currentRides)
                
                clientTextField.text = ""
                
                // Stopping Location Updates to save battery
                
                locationManager.stopUpdatingLocation()
                
                // Animations of the views and labels.
                
                timeElapsed.fadeOut(duration: 0.5)
                timeElapsed.text = "00:00:00"
                distanceDriven.text = "00.00 Km"
                timeElapsed.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
                
                distanceDriven.fadeOut(duration: 0.5)
                distanceDriven.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
                
                wayBackButtonView.topNotchViewfadeOut(duration: 1.0)
                wayBackButton.fadeOut(duration: 1.0)
                
                wayBackButton.setTitle("", for: .normal)
                wayBackButton.setTitleColor(UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0), for: .normal)
                isWayBack = false
                
                wayBackButton.sendActions(for: .touchUpInside)
                
                stopwatchResetButton.isEnabled = false
                
                // Reset traveled distance to 0 and apply on Label
                
                mapView.removeOverlays(self.mapView.overlays)
                
                coordinates.removeAll()
                
                startLocation = nil
                traveledDistance -= self.traveledDistance
                distanceDriven.text = "0 m"
                
                // Reset Timer to Zero
                
                setStopTime(date: nil)
                setStartTime(date: nil)
                timeElapsed.text = makeTimeString(hour: 0, min: 0, sec: 0)
                stopTimer()
                
                locationManager.allowsBackgroundLocationUpdates = false
                locationManager.pausesLocationUpdatesAutomatically = true
                
                // Reset status label to Ready when stop is pressed and change color to green
                
                pauseStateLabel.fadeOut(duration: 2.0)
                pauseStateLabel.text = "Bereit"
                pauseStateLabel.textColor = UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
                pauseStateLabel.fadeIn(duration: 2.0)
                
                
                
            @unknown default:
                print("Unknown Fault")
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: Function for the Map Type Selector
    
    // Function for the segmented controlled map type selector
        
        @IBAction func segmentedControlAction(sender: UISegmentedControl) {
            switch (sender.selectedSegmentIndex) {
            case 0:
                mapView.fadeOut(duration: 0.7)
                mapView.mapType = .standard
                mapView.fadeIn(duration: 0.7)
            case 1:
                mapView.fadeOut(duration: 0.7)
                mapView.mapType = .mutedStandard
                mapView.fadeIn(duration: 0.7)
            case 2:
                mapView.fadeOut(duration: 0.7)
                mapView.mapType = .satellite
                mapView.fadeIn(duration: 0.7)
            default:
                mapView.mapType = .standard
            }
        }
    
    // MARK: Function for Location and Heading Tracking
    
    @IBAction func locationButtonPressed(_ sender: Any) {
        
        // Re-Enable heading mode
                
                mapView.setUserTrackingMode(.followWithHeading, animated:true)
           }
    @IBAction func wayBackButtonPressed(_ sender: Any) {
        
        
        
        if isWayBack == false {
            isWayBack = true
            wayBackButton.fadeOut(duration: 2.5)
            wayBackButton.setTitle(clientTextField?.text, for: .normal)
            wayBackButton.setTitleColor(UIColor.init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0), for: .normal)
            wayBackButton.fadeIn(duration: 0.7)
        }
        else if isWayBack == true {
            isWayBack = false
            wayBackButton.fadeOut(duration: 2.5)
            wayBackButton.setTitle("Rückfahrt", for: .normal)
            wayBackButton.setTitleColor(UIColor.systemCyan, for: .normal)
            wayBackButton.fadeIn(duration: 0.7)
            }
        }
    @IBAction func menuButtonPressed(_ sender: Any) {
    }
    
    @IBAction func addContactButtonPressed(_ sender: Any) {
    }
    
    @IBAction func addressBookButtonPressed(_ sender: Any) {
    }
    
}



