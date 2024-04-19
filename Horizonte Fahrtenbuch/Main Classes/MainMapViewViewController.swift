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
import ActivityKit
import LocalAuthentication

// MARK: Custom

class DestinationPolyline: MKPolyline {
    // You can add additional properties here if needed
}

class TraveledPolyline: MKPolyline {
    // Custom class for traveled routes
}

// MARK: Main

class MainMapViewViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UITextFieldDelegate {
    
    // Update Timer when riding to a customer started from the adressbook
    
    var updateTimer: Timer?
    var currentDestination: CLLocation?
    
    // Variable for destination polyline
    
    var destinationPolyline: MKPolyline?
    
    // Static property for DateFormatter
        static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm" // 24-hour time format
            return formatter
        }()
    
    // MARK: Variables for Location determination
    
    var coordinates :[CLLocationCoordinate2D] = []
    var returnTripPoints: (start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) = (CLLocationCoordinate2D(), CLLocationCoordinate2D())
    var index = 0
    
    var isWayBack:Bool = false

        
    // MARK: Variables for the Timer
    
    var timer = Timer()
    
    var deliveryTime: Date?
    
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
    
    var startAnnotation = MKPointAnnotation()
    let geocoder = CLGeocoder()
    
    // MARK: Variable for the client phone number
    
    var phoneNumber: String?
    
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
    
    @IBOutlet weak var personalDetailButton: UIButton!
    @IBOutlet weak var personalDetailView: UIView!
    
    @IBOutlet weak var settingsView: UIView!
    @IBOutlet weak var deliveryButton: UIButton!
    @IBOutlet weak var deliveryView: UIView!
    
    @IBOutlet weak var phoneButtonView: UIView!
    @IBOutlet weak var phoneButton: UIButton!
    
    @IBOutlet weak var etaView: UIView!
    @IBOutlet weak var etaLabel: UILabel!
    @IBOutlet weak var etaDistanceLabel: UILabel!
    
    // MARK: Outlets for the Segmented control view and segmented control
    
    @IBOutlet weak var segmentedControlView: UIView!
    @IBOutlet weak var mapTypeSelector: UISegmentedControl!
    
    // MARK: Outletts for Timer
    
    @IBOutlet weak var stopwatchResetButton: UIButton!
    
    
    // MARK: Base functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        authenticateWithBiometrics()
        
        // Initialize Realm and print Realm Database file URL
        
        lazy var realm:Realm = {
            return try! Realm()
        }()
        print (Realm.Configuration.defaultConfiguration.fileURL!)
        
        // MARK: Client TextField
        
        // Delegate for the client textfield
        
        clientTextField.delegate = self
        
        // Customizing customer TextField
        
        clientTextField.attributedPlaceholder = NSAttributedString(
            string: "Kunde eingeben",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemOrange.withAlphaComponent(0.9)]
        )
        
        
        
        // Mask Corner Radius for segmented control View
        
        menuButtonView.layer.cornerRadius = 25
        menuButton.tintColor = UIColor.systemPurple //init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        
        addContactButtonView.layer.cornerRadius = 25
        addContactButton.tintColor = UIColor.systemPurple //init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        
        addressBookButtonView.layer.cornerRadius = 25
        addressBookButton.tintColor = UIColor.systemPurple //init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        
        settingsButtonView.layer.cornerRadius = 25
        settingsButton.tintColor = UIColor.systemPurple //init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        
        personalDetailView.layer.cornerRadius = 25
        personalDetailButton.tintColor = UIColor.systemPurple //init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        
        segmentedControlView.clipsToBounds = true
        segmentedControlView.layer.cornerRadius = 15
        segmentedControlView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        
        // MASK Corner Radius for Textfield View
        
        clientTextFieldView.layer.cornerRadius = 20
        clientTextFieldView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
        // Corner Radius for ETA view
        
        etaView.layer.cornerRadius = 10
        
        // Customizing the Maptype Selector
        
        mapTypeSelector.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
        
        mapTypeSelector.selectedSegmentTintColor = UIColor.systemPurple //init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
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
        
        wayBackButton.isUserInteractionEnabled = false
        
        mapView.delegate = self
        mapView.clipsToBounds = true
        
        // Basic Map Setup
        
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsTraffic = true
        
        //mapview setup to show user location
        
        mapView.delegate = self
        mapView.mapType = MKMapType(rawValue: 0)!
        mapView.setUserTrackingMode(.followWithHeading, animated: true)

    }
    
    
    // MARK: Setting the delegate for ContactsTableViewController
    
    func start() {
        let dummyButton = UIButton()
        self.start(_sender: dummyButton)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addressBookSegue" { // Replace with your actual segue identifier
            if let navigationController = segue.destination as? UINavigationController,
               let contactsController = navigationController.viewControllers.first as? contactsTableViewController {
                contactsController.delegate = self
            }
        }
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
    
    // MARK: FaceID
    
    private func authenticateWithBiometrics() {
        let userDefaults = UserDefaults.standard
        let authenticationEnabled = userDefaults.bool(forKey: "AuthenticationEnabled")
        
        guard authenticationEnabled else {
            // Authentication is not enabled, perform necessary actions for non-authenticated state
            return
        }
        
        let context = LAContext()
        let reason = "Authentication required"
        
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { (success, error) in
            if success {
                // Authentication succeeded, continue with your app flow
                DispatchQueue.main.async {
                    // Update your UI or perform any necessary tasks after successful authentication
                    // For example, transition to your main app content
                }
            } else {
                if let error = error as NSError? {
                    if error.code == LAError.authenticationFailed.rawValue {
                        // Authentication with passcode failed, present the lock screen view
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "lockscreenSegue", sender: nil)
                        }
                    } else {
                        // Authentication failed for another reason
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "lockscreenSegue", sender: nil)
                        }
                    }
                }
            }
        }
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
        
        //Track Route (Check if the current location fix is accurate enough (within 10 meters))
        
        guard let currentLocation = locations.last else { return }
        
        if currentLocation.horizontalAccuracy < 10.00 {
            
            for location in locations {
                
                coordinates.append (location.coordinate)
                
                let numberOfLocations = coordinates.count
                print (" :-) \(numberOfLocations)")
                
                if numberOfLocations > 1{
                    var pointsToConnect = [coordinates[numberOfLocations - 1], coordinates[numberOfLocations - 2]]
                    
                    let polyline = MKPolyline(coordinates: &pointsToConnect, count: pointsToConnect.count)
                    
                    mapView.addOverlay(polyline)
                    
                    // MARK: Zoom to fit Polyline into screensize. Important for MKSnapshotter
                    
                    /*guard let currentLocation = locations.last else { return }

                        let center = CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
                        let region = MKCoordinateRegion(center: center, latitudinalMeters: 250, longitudinalMeters: 50)
                        mapView.setRegion(region, animated: true)
                           
                           //mapView.setVisibleMapRect(adjustedRect, edgePadding: mapPadding, animated: true)*/
                    }
                }
            }
        }
    
    
    // MARK: Base setup for drawing the polyline
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? DestinationPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .blue
            renderer.lineWidth = 6
            return renderer
        } else if overlay is TraveledPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .orange
            renderer.lineWidth = 6
            return renderer
        }
        // Fallback for any other polyline
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = .orange
        renderer.lineWidth = 6
        return renderer
    }
    
    func addTraveledRoute(coordinates: [CLLocationCoordinate2D]) {
        print("Adding traveled route with \(coordinates.count) coordinates.")
        let polyline = TraveledPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
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
        timeElapsed.textColor = UIColor.systemPurple //init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        distanceDriven.textColor = UIColor.systemPurple //init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
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
        formatter.unitStyle = .full
        
        let distanceString: String
        
        if traveledDistance < 1000 {
            let kmDistance = traveledDistance / 1000.0
            distanceString = String(format: "%.1f Km", kmDistance)
        } else {
            let kmDistance = traveledDistance / 1000.0
            distanceString = String(format: "%.1f Km", kmDistance)
        }
        
        distanceDriven.text = distanceString
    }
    
    // MARK: Function for finally saving client to database
    
    func saveRealmObject(currentRides:currentRide) {
        let realm = try? Realm()
        try? realm?.write {
            realm?.add(currentRides)
        }
        print("Data Was Saved To Realm Database.")
    }
    
    func addAnnotationAtCurrentLocation() {
        if let userLocation = mapView.userLocation.location {
            // Add a pin annotation to the user's current location
            startAnnotation.coordinate = userLocation.coordinate
            startAnnotation.title = "Start"
            mapView.addAnnotation(startAnnotation)
            mapView.showAnnotations([startAnnotation], animated: true)
        } else {
            // If the user's location is not yet available, try again later.
            // You could also prompt the user to enable location services.
            print("User location not available yet.")
        }
    }
    
    
    // MARK: Start Button Action
    
    @IBAction func start(_sender: UIButton) {
        
        // Add a pin annotation for the start position
        
        geocoder.reverseGeocodeLocation(mapView.userLocation.location!, completionHandler: {(placemarks, error) in
            if error == nil {
                if let firstLocation = placemarks?[0].location {
                    self.startAnnotation.coordinate = firstLocation.coordinate
                    self.startAnnotation.title = "Start"
                    self.mapView.addAnnotation(self.startAnnotation)
                }
            }
            else {
                print("Reverse geocoding error: \(error!.localizedDescription)")
            }
        })
        
        
        // Disabling scrolling, zooming, pitching and rotating when start was pressed.
        
        /*mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false*/
        
        // Fade In delivery Button
        
        deliveryButton.fadeIn(duration: 0.5)
        deliveryView.fadeDelieryViewIn(duration: 0.5)
        
        // MARK: Haptic Feedback for start
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        locationButton.isEnabled = true
        
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
        
        
        wayBackButton.setTitleColor(UIColor.systemPurple /*init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)*/, for: .normal)
        
        
        stopwatchResetButton.fadeIn(duration: 0.5)
        
        clientTextFieldView.fadeOut(duration: 0.5)
        
        // Testing disabling the screen sleep mode while recording a ride
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        locationManager.startUpdatingLocation()
        locationManager.distanceFilter = 20
        
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
        formatter.unitStyle = .full
        
        let distanceString = formatter.string(fromDistance: traveledDistance)
        distanceDriven.text = distanceString
        
        if clientTextField.text == "" {
            wayBackButton.setTitle("Kein Ziel", for: .normal)
            wayBackButton.setTitleColor(.systemOrange, for: .normal)
        } else {
            wayBackButton.setTitle(clientTextField.text, for: .normal)
            wayBackButton.configuration?.titleAlignment = .center
            wayBackButton.configuration?.titleLineBreakMode = .byTruncatingTail
            
            
        }
        
        print (traveledDistance)
    }
    
    // MARK: Stop Button Action
    
    
    @IBAction func stopButtonPressed(_ sender: Any) {
        
        // Reeanbling scrolling, zooming, pitching and rotating when stop was pressed.
        
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true
        
        
        // MARK: Haptic Feedback for start
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        
        
        let alert = UIAlertController(title: "Bist du sicher?", message: "Bist du sicher, dass du abbrechen möchtest ohne die Fahrt zu speichern?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Fortsetzen", style: .cancel))
        alert.addAction(UIAlertAction(title: "Ohne speichern beenden", style: .destructive, handler: { [self]_ in
            
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.deliveryButton.isUserInteractionEnabled = true
            
            // Remove the annotation pin
            
            if let annotation = mapView.annotations.first(where: { $0.title == "Start" }) {
                mapView.removeAnnotation(annotation)
            }
            
            // Invalidate ETA Timer Updates and fade ETA View Out
            
            updateTimer?.invalidate()
            updateTimer = nil
            
            // Check if the timer has been invalidated
            
            // Check if the timer has been invalidated and print the status
                if updateTimer?.isValid ?? false {
                    print("Timer is still active.")
                } else {
                    print("Timer has been successfully invalidated.")
                }
            
            self.etaView.fadeOut()
            
            // Fade Delivery View Out and turn the button color back to systemOrange
            
            deliveryView.fadeDeliveryViewOut(duration: 0.5)
            deliveryButton.fadeDeliveryViewOut(duration: 0.5)
            
            // Fade Phone Button View out
            
            phoneButtonView.fadeDeliveryViewOut(duration: 0.5)
            phoneButton.fadeDeliveryViewOut(duration: 0.5)
            
            deliveryButton.setImage(UIImage(systemName: "car.rear.road.lane")?.withRenderingMode(.alwaysTemplate), for: .normal)
            deliveryButton.tintColor = UIColor.systemOrange
            
            
            TopNotchView.topNotchViewfadeOut(duration: 1.0)
            timeElapsed.fadeOut(duration: 1.0)
            distanceDriven.fadeOut(duration: 1.0)
            
            clientTextFieldView.textFieldViewfadeIn(duration: 1.0)
            clientTextField.textFieldViewfadeIn(duration: 1.0)
            
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
            timeElapsed.textColor = UIColor.systemPurple //init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
            
            distanceDriven.fadeOut(duration: 0.5)
            distanceDriven.textColor = UIColor.systemPurple //init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
            
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
            distanceDriven.text = "0.0 Km"
            
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
            
            locationButton.isEnabled = true
            locationButton.sendActions(for: .touchUpInside)
            
            print ("Data was not saved to Realm")
            
        }))
        alert.addAction(UIAlertAction(title: "Speichern und beenden", style: .destructive, handler: { [self] action in
            
            switch action.style{
                
            case .default:
                print("default")
                
            case .cancel:
                self.dismiss(animated: true)
                
            case .destructive:
                
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.deliveryButton.isUserInteractionEnabled = true
                
                // Remove the annotation pin
                
                if let annotation = mapView.annotations.first(where: { $0.title == "Start" }) {
                    mapView.removeAnnotation(annotation)
                }
                
                // Invalidate ETA Timer Updates and fade ETA View Out
                
                updateTimer?.invalidate()
                updateTimer = nil
                
                // Check if the timer has been invalidated and print the status
                    if updateTimer?.isValid ?? false {
                        print("Timer is still active.")
                    } else {
                        print("Timer has been successfully invalidated.")
                    }
                
                self.etaView.fadeOut()
                
                // Fade Delivery View Out and turn it's color back to systemOrange
                
                deliveryView.fadeDeliveryViewOut(duration: 0.5)
                
                deliveryButton.fadeDeliveryViewOut(duration: 0.5)
                deliveryButton.setImage(UIImage(systemName: "car.rear.road.lane")?.withRenderingMode(.alwaysTemplate), for: .normal)
                deliveryButton.tintColor = UIColor.systemOrange
                
                // Fade Phone Button View out
                
                phoneButtonView.fadeDeliveryViewOut(duration: 0.5)
                phoneButton.fadeDeliveryViewOut(duration: 0.5)
                
                TopNotchView.topNotchViewfadeOut(duration: 1.0)
                timeElapsed.fadeOut(duration: 1.0)
                distanceDriven.fadeOut(duration: 1.0)
                
                stopwatchResetButton.fadeOut(duration: 0.5)
                
                startButton.ButtonViewfadeOut(duration: 0.5)
                startButton.setImage(UIImage(named: "GreenButtonHighRes.png"), for: .normal)
                startButton.ButtonViewfadeIn(duration: 0.5)
                
                clientTextFieldView.fadeIn(duration: 1.0)
                
                locationButton.isEnabled = true
                locationButton.sendActions(for: .touchUpInside)
                
                // Testing disabling the screen sleep mode while recording a ride (Reenabling sleep when stop is pressed)
                
                UIApplication.shared.isIdleTimerDisabled = false
                
                // MARK: Initializing Realm and store properties to the database
                
                lazy var realm:Realm = {
                    return try! Realm()
                }()
                
                let currentRides = currentRide()
                
                let date = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "d. MMM YY"
                dateFormatter.dateStyle = .long
                
                dateFormatter.string(from: date)
                
                let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                
                if let encodedPolyline = try? JSONEncoder().encode(PolylineData(polyline)) {
                    if String(data: encodedPolyline, encoding: .utf8) != nil {
                        currentRides.encodedPolyline = encodedPolyline
                        
                        print("Encoded polyline: \(String(data: encodedPolyline, encoding: .utf8) ?? "Error decoding polyline")")
                    }
                }
                
                currentRides.deliveryTime = deliveryTime
                currentRides.timeElapsed = timeElapsed.text
                currentRides.distanceDriven = distanceDriven.text
                currentRides.dateActual = date
                currentRides.currentClientName = clientTextField.text
                //currentRides.encodedPolyline = encodedPolyline
                
                stopTime = Date()
                
                currentRides.startTime = startTime
                currentRides.endTime = stopTime
                
                currentRides.isManuallySaved = false
                
                saveRealmObject(currentRides: currentRides)
                
                clientTextField.text = ""
                
                // Stopping Location Updates to save battery
                
                locationManager.stopUpdatingLocation()
                
                // Animations of the views and labels.
                
                timeElapsed.fadeOut(duration: 0.5)
                timeElapsed.text = "00:00:00"
                distanceDriven.text = "0.0 Km"
                timeElapsed.textColor = UIColor.systemPurple //init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
                
                distanceDriven.fadeOut(duration: 0.5)
                distanceDriven.textColor = UIColor.systemPurple //init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
                
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
                distanceDriven.text = "0.0 Km"
                
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
    
    // MARK:
    
    // MARK: Function for fading in and out the phone view
    
    func fadePhoneViewIn(duration: TimeInterval = 0.5) {
        UIView.animate(withDuration: duration) {
            self.phoneButtonView.alpha = 0.7
        }
    }
    
    func fadePhoneViewOut(duration: TimeInterval = 0.5) {
        UIView.animate(withDuration: duration) {
            self.phoneButtonView.alpha = 0.0
        }
    }
    
    func fadePhoneButtonIn(duration: TimeInterval = 0.5) {
        UIView.animate(withDuration: duration) {
            self.phoneButton.alpha = 0.7
        }
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
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        // Re-Enable heading mode
        
        mapView.setUserTrackingMode(.followWithHeading, animated:true)
    }
    
    // MARK: Action for the wayback Button
    
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
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    @IBAction func addressBookButtonPressed(_ sender: Any) {
    }
    
    struct PolylineData: Encodable {
        let points: [PointData]
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(points)
        }
        
        struct PointData: Codable {
            var longitude: Double
            var latitude: Double
            
            init(_ coordinate: CLLocationCoordinate2D) {
                self.longitude = coordinate.longitude
                self.latitude = coordinate.latitude
            }
        }
        
        init(_ polyline: MKPolyline) {
            self.points = (0 ..< polyline.pointCount).map {
                let mapPoint = polyline.points()[$0]
                let coordinate = mapPoint.coordinate
                return PointData(coordinate)
            }
        }
    }
    
    @IBAction func currentRidesButtonPressed(_ sender: Any) {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    @IBAction func contactsButtonPressed(_ sender: Any) {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    @IBAction func statsButtonPressed(_ sender: Any) {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    @IBAction func personalDetailsButtonPressed(_ sender: Any) {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    @IBAction func deliveryButtonPressed(_ sender: UIButton) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)

        deliveryButton.tintColor = UIColor.systemGreen
        deliveryButton.setImage(UIImage(systemName: "checkmark.seal.fill")?.withRenderingMode(.alwaysTemplate), for: .normal)
        deliveryTime = Date()
        
        // Plot the route back to the company
        let realm = try! Realm()
        if let details = realm.objects(personalDetails.self).first {
            let street = details.companyStreet ?? ""
            let city = details.companyCity ?? ""
            let postalCode = details.companyPostalCode ?? ""
            
            self.calculateRouteToDestination(street: street, city: city, postalCode: postalCode, clientName: "Arbeitgeber")
        }
        
        // Invalidate and restart the timer
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(updateETA), userInfo: nil, repeats: true)

        // Show ETA View
        self.etaView.topNotchViewfadeIn(duration: 0.7)
        
        // Disable the button for further presses
        
        self.deliveryButton.isUserInteractionEnabled = false
    }
    
    @IBAction func phoneButtonPressed(_ sender: Any) {
        guard let number = phoneNumber, !number.isEmpty, let url = URL(string: "tel://\(number)") else {
                print("Invalid phone number")
                return
            }
            
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                print("Cannot make a call on this device")
            }
    }
}

// MARK: Extensions

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}

extension TimeInterval {
    // Formats the TimeInterval (which is in seconds) into a hours and minutes string
    func formatAsDuration() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        return String(format: "%02i hours %02i minutes", hours, minutes)
    }
}

extension CLLocationDistance {
    // Formats the CLLocationDistance (which is in meters) into a kilometers string
    func formatAsDistance() -> String {
        let kilometers = self / 1000
        return String(format: "%.2f Km", kilometers)
    }
}

extension MainMapViewViewController: ContactSelectionDelegate {
    func didSelectContact(clientName: String, phoneNumber: String, street: String, city: String, postalCode: String) {
            DispatchQueue.main.async {
                self.clientTextField.text = clientName
                self.phoneNumber = phoneNumber

                if !phoneNumber.isEmpty {
                    self.fadePhoneViewIn()
                    self.fadePhoneButtonIn()
                }

                self.startProgrammatically()
                self.calculateRouteToDestination(street: street, city: city, postalCode: postalCode, clientName: clientName)
                self.etaView.topNotchViewfadeIn(duration: 0.7)

                // Start or restart the timer
                self.updateTimer?.invalidate()
                self.updateTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.updateETA), userInfo: nil, repeats: true)
            }
        }
    
    @objc func updateETA() {
            guard let destination = currentDestination else { return }
            self.routeToLocation(destination: destination)
        }
    
    func calculateRouteToDestination(street: String, city: String, postalCode: String, clientName: String) {
        let geocoder = CLGeocoder()
        let addressString = "\(street), \(postalCode) \(city)"
        
        geocoder.geocodeAddressString(addressString) { [weak self] (placemarks, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                print("Geocoding failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    strongSelf.showAlert(title: "Fehler", message: "Es wurde keine Adresse für die Rückfahrt gefunden. Bitte überprüfe Deine Angaben in den Einstellungen.")
                }
                return
            }

            guard let location = placemarks?.first?.location else {
                print("No location found for the provided address.")
                return
            }
            
            // Update the destination annotation with the client name
            DispatchQueue.main.async {
                strongSelf.updateDestinationAnnotation(at: location.coordinate, withName: clientName)
            }
            
            strongSelf.currentDestination = location
            strongSelf.routeToLocation(destination: location)
        }
    }

    
    func updateDestinationAnnotation(at coordinate: CLLocationCoordinate2D, withName name: String) {
        
        // Remove all anntotations
        
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        // Remove existing destination annotation if it exists
        if let existingAnnotation = mapView.annotations.first(where: { ($0 as? MKPointAnnotation)?.title == "Destination" }) {
            mapView.removeAnnotation(existingAnnotation)
        }
        
        // Create a new annotation for the destination
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.coordinate = coordinate
        destinationAnnotation.title = name  // Set the client's name as the title
        mapView.addAnnotation(destinationAnnotation)
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }

    func routeToLocation(destination: CLLocation) {
        guard let sourceCoordinates = locationManager.location?.coordinate else { return }

        let destinationCoordinates = destination.coordinate
        let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinates)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinates)
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: sourcePlacemark)
        directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
        directionRequest.transportType = .automobile

        let directions = MKDirections(request: directionRequest)
        directions.calculate { [weak self] (response, error) in
            guard let strongSelf = self, let response = response, let route = response.routes.first else {
                print("Directions calculation failed: \(error?.localizedDescription ?? "No error provided")")
                return
            }

            // Remove existing destination polyline from the map
            if let polyline = strongSelf.destinationPolyline {
                strongSelf.mapView.removeOverlay(polyline)
            }

            // Extract the coordinates from the route's polyline and create a new destination polyline
            let routeCoordinates = route.polyline.coordinates
            let newPolyline = DestinationPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
            strongSelf.mapView.addOverlay(newPolyline, level: .aboveRoads)
            strongSelf.destinationPolyline = newPolyline  // Keep track of the current polyline

            // Update ETA labels
            let arrivalDate = Date().addingTimeInterval(route.expectedTravelTime)
            strongSelf.etaLabel.text = strongSelf.formatAsTime(date: arrivalDate)
            strongSelf.etaDistanceLabel.text = route.distance.formatAsDistance()
        }
    }

    
    func formatAsTime(date: Date) -> String {
            return MainMapViewViewController.dateFormatter.string(from: date)
        }
    
    

    func startProgrammatically() {
            let dummyButton = UIButton()
            self.start(_sender: dummyButton) // Call the IBAction method
        }
}





