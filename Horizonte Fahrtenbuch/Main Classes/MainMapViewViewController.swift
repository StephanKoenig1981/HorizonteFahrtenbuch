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

    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var timeElapsed: UILabel!
    @IBOutlet weak var distanceDriven: UILabel!
    @IBOutlet weak var baseToolbarView: UIView!
    @IBOutlet weak var TopNotchView: UIView!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var locationButton: UIButton!
    
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
    
    

    
    // MARK: Base Class for the stopwatch
    
    class Stopwatch: ObservableObject {
    private var startTime: Date?
        private var accumulatedTime:TimeInterval = 0
        private var timer: Cancellable?
      
        @Published var isRunning = false {
            didSet {
                if self.isRunning {
                   self.start()
                } else {
                    self.stop()
                }
            }
        }
        @Published private(set) var elapsedTime: TimeInterval = 0
        private func start() -> Void {
            self.startTime = Date()
             self.timer?.cancel()
             self.timer = Timer.publish(every: 0.5, on: .main, in: .common)
             .autoconnect()
             .sink { _ in
                        self.elapsedTime = self.getElapsedTime()
                    }
        }
        private func stop() -> Void {
            self.timer?.cancel()
            self.timer = nil
            self.accumulatedTime = self.elapsedTime
            self.startTime = nil
        }
        func reset() -> Void {
            self.accumulatedTime = 0
            self.elapsedTime = 0
            self.startTime = nil
            self.isRunning = false
        }
        private func getElapsedTime() -> TimeInterval {
            return -(self.startTime?.timeIntervalSinceNow ??     0)+self.accumulatedTime
        }
    }
    
    @IBAction func startStopButtonPressed(_ sender: Any) {
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
}

