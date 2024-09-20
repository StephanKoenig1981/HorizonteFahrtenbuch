//
//  routeDetailViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 16.05.23.
//

import CoreLocation
import MapKit

class routeDetailViewController: UIViewController {
    
    var encodedPolyline: Data?
    var clientName: String?
    var timeElapsed: String?
    var distanceDriven: String?
    
    
    @IBOutlet weak var routeDetailMapView: MKMapView!
    
    @IBOutlet weak var clientNameLabel: UILabel!
    @IBOutlet weak var drivenDistanceLabel: UILabel!
    @IBOutlet weak var timeElapsedLabel: UILabel!
    
    @IBOutlet weak var mapTypeSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        routeDetailMapView.delegate = self
        routeDetailMapView.layer.cornerRadius = 20
        routeDetailMapView.showsScale = true
        routeDetailMapView.showsUserLocation = false
        
        // Customizing the Maptype Selector
    
        mapTypeSegmentedControl.selectedSegmentTintColor = UIColor.systemIndigo //init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        mapTypeSegmentedControl.setTitleTextAttributes(titleTextAttributes, for:.selected)
    
        
        // Check if the encodedPolyline is not nil
        guard let encodedPolyline = encodedPolyline else {
            print("There is no encodedPolyline data to decode")
            return
        }
        
        // Decode the encodedPolyline data into an array of CLLocationCoordinate2D points
        guard let coordinatesJSON = try? JSONDecoder().decode([[String: Double]].self, from: encodedPolyline) else {
            print("Failed to decode the encodedPolyline")
            return
        }
        
        // Create an array of CLLocationCoordinate2D points from the coordinates JSON array
        var points: [CLLocationCoordinate2D] = []
        for coordinateJSON in coordinatesJSON {
            let point = CLLocationCoordinate2D(latitude: coordinateJSON["latitude"]!, longitude: coordinateJSON["longitude"]!)
            points.append(point)
        }
        
        // Add the first coordinate as a pin annotation
        if let firstCoordinate = points.first {
            let pin = MKPointAnnotation()
            pin.coordinate = firstCoordinate
            pin.title = "Start"
            routeDetailMapView.addAnnotation(pin)
            
            // Set the pinTintColor to systemPurple
            if let annotationView = routeDetailMapView.view(for: pin) {
                annotationView.tintColor = UIColor.systemPurple
            }
        }
        
        // Add the last coordinate as a pin annotation
        if let firstCoordinate = points.last {
            let pin = MKPointAnnotation()
            pin.coordinate = firstCoordinate
            pin.title = "Ende"
            routeDetailMapView.addAnnotation(pin)
            
            // Set the pinTintColor to systemPurple
            if let annotationView = routeDetailMapView.view(for: pin) {
                annotationView.tintColor = UIColor.systemPurple
            }
        }

        
        print("Decoded coordinates: \(points)") // Add this line to print the decoded coordinates
        
        // Create an MKPolyline from the points array and add it to the map
        let polyLine = MKPolyline(coordinates: points, count: points.count)
        routeDetailMapView.addOverlay(polyLine)
        
        routeDetailMapView.setVisibleMapRect(polyLine.boundingMapRect, edgePadding: UIEdgeInsets(top: 70, left: 70, bottom: 70, right: 70), animated: true)
        
        clientNameLabel.text = clientName?.description
        drivenDistanceLabel.text = distanceDriven?.description
        timeElapsedLabel.text = timeElapsed?.description
        
        if clientName?.description == "" {
            clientNameLabel.text = "Keine Angabe"
            clientNameLabel.textColor = UIColor.systemBlue
        }
        
        self.title = "Gefahrene Route"
    }
    @IBAction func mapTypeSelector(_ sender: Any) {
        
        switch ((sender as AnyObject).selectedSegmentIndex) {
        case 0:
            routeDetailMapView.fadeOut(duration: 0.7)
            routeDetailMapView.mapType = .standard
            routeDetailMapView.fadeIn(duration: 0.7)
        case 1:
            routeDetailMapView.fadeOut(duration: 0.7)
            routeDetailMapView.mapType = .mutedStandard
            routeDetailMapView.fadeIn(duration: 0.7)
        case 2:
            routeDetailMapView.fadeOut(duration: 0.7)
            routeDetailMapView.mapType = .satellite
            routeDetailMapView.fadeIn(duration: 0.7)
        default:
            routeDetailMapView.mapType = .standard
        }
        
    }
}

extension routeDetailViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.systemOrange
            renderer.lineWidth = 4.0
            return renderer
        }
        return MKOverlayRenderer()
    }
}

