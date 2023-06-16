//
//  clientDetailViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 12.05.23.
//

import UIKit
import RealmSwift
import CoreLocation
import MapKit

class clientDetailViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var locationManager = CLLocationManager()
    var clientName: String?
    var clientStreet: String?
    var clientCity: String?
    var latitude: Double = 0
    var longitude: Double = 0
    
    @IBOutlet weak var distanceDescriptionLabel: UILabel!
    @IBOutlet weak var etaDescriptionLabel: UILabel!
    @IBOutlet weak var etaLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    
    @IBOutlet weak var mapTypeSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var clientDetailMapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clientDetailMapView.delegate = self
        
        clientDetailMapView.layer.cornerRadius = 20
        clientDetailMapView.showsScale = true
        
        let initialLocation = CLLocation(latitude: latitude, longitude: longitude)
        let regionRadius: CLLocationDistance = 500
        let region = MKCoordinateRegion(center: initialLocation.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        clientDetailMapView.setRegion(region, animated: true)
        
        let annotation = CustomAnnotation(coordinate: CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude), title: self.clientName, subtitle: "\(self.clientStreet ?? ""), \(self.clientCity ?? "")")
        clientDetailMapView.addAnnotation(annotation)
        
        self.title = clientName
        
        // Customizing the Maptype Selector
    
        mapTypeSegmentedControl.selectedSegmentTintColor = UIColor.systemIndigo //init(red: 156/255, green: 199/255, blue: 105/255, alpha: 1.0)
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        mapTypeSegmentedControl.setTitleTextAttributes(titleTextAttributes, for:.selected)
        
        // MARK: Setting up the location Manager for directions
        
        locationManager.delegate = self
        
        // Clearing the distance and ETA Labels
        
        etaLabel.text = "--:-- Min."
        distanceLabel.text = "-.- Km"
    
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let customAnnotation = annotation as? CustomAnnotation else { return nil }
        
        let identifier = "customAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: customAnnotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.tintColor = .systemOrange
        } else {
            annotationView?.annotation = customAnnotation
        }
        
        // Show callout bubble and set title
        annotationView?.isSelected = false
        annotationView?.glyphText = customAnnotation.title
        
        return annotationView
    }
    
    // MARK: MKDirections
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.last else { return }
        
        let sourceCoord = userLocation.coordinate
        let destinationCoord = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)

        let sourcePlacemark = MKPlacemark(coordinate: sourceCoord)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoord)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = sourceMapItem
        directionsRequest.destination = destinationMapItem
        
        directionsRequest.transportType = .automobile
        directionsRequest.requestsAlternateRoutes = true
        directionsRequest.destination = destinationMapItem
        
    }
    
    // MARK: Overlay renderer
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer(overlay: overlay)
        }
        
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = UIColor.systemOrange
        renderer.lineWidth = 4.0
        return renderer
    }
    
    // MARK: IBActions
    
    @IBAction func mapTypeSegmentedControl(_ sender: Any) {
        switch ((sender as AnyObject).selectedSegmentIndex) {
        case 0:
            clientDetailMapView.fadeOut(duration: 0.7)
            clientDetailMapView.mapType = .standard
            clientDetailMapView.fadeIn(duration: 0.7)
        case 1:
            clientDetailMapView.fadeOut(duration: 0.7)
            clientDetailMapView.mapType = .mutedStandard
            clientDetailMapView.fadeIn(duration: 0.7)
        case 2:
            clientDetailMapView.fadeOut(duration: 0.7)
            clientDetailMapView.mapType = .satellite
            clientDetailMapView.fadeIn(duration: 0.7)
        default:
            clientDetailMapView.mapType = .standard
        }
    }
    @IBAction func routeButtonPressed(_ sender: Any) {
        let sourceCoord = CLLocationCoordinate2D(latitude: locationManager.location?.coordinate.latitude ?? 0.0,
                                                     longitude: locationManager.location?.coordinate.longitude ?? 0.0)
            let destinationCoord = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)

            let sourcePlacemark = MKPlacemark(coordinate: sourceCoord)
            let destinationPlacemark = MKPlacemark(coordinate: destinationCoord)

            let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
            let destinationMapItem = MKMapItem(placemark: destinationPlacemark)

            let directionsRequest = MKDirections.Request()
            directionsRequest.source = sourceMapItem
            directionsRequest.destination = destinationMapItem
            directionsRequest.transportType = .automobile
            directionsRequest.requestsAlternateRoutes = true
            
            let directions = MKDirections(request: directionsRequest)
            directions.calculate(completionHandler: { response, error in
            guard let unwrappedResponse = response, let route = unwrappedResponse.routes.first else { return }
            self.clientDetailMapView.addOverlay(route.polyline, level: .aboveRoads)
            
                let padding: CGFloat = 40
                        let edgePadding = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
                        let boundingMapRect = route.polyline.boundingMapRect
                        let paddedMapRect = boundingMapRect.insetBy(dx: -padding, dy: -padding)
                        self.clientDetailMapView.setVisibleMapRect(paddedMapRect, edgePadding: edgePadding, animated: true)
                
                // Update the labels with the estimated travel time and distance...
                       let distance = route.distance / 1000
                       let eta = route.expectedTravelTime
                       self.distanceLabel.text = String(format: "%.1f Km", distance)
                       self.etaLabel.text = TimeInterval(eta).formatted()
        })
        clientDetailMapView.showsUserLocation = true
        
    }
}

// MARK: Extension for calculating ETA

extension TimeInterval {
    func formatted() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
               formatter.unitsStyle = .positional
               return formatter.string(from: self) ?? "00:00:00"
    }
}
    

