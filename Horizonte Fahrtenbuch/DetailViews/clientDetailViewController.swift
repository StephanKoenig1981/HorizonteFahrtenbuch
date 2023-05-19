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
    
    
    @IBOutlet weak var clientDetailMapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clientDetailMapView.delegate = self
        
        clientDetailMapView.layer.cornerRadius = 20
        
        let initialLocation = CLLocation(latitude: latitude, longitude: longitude)
        let regionRadius: CLLocationDistance = 500
        let region = MKCoordinateRegion(center: initialLocation.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        clientDetailMapView.setRegion(region, animated: true)
        
        let annotation = CustomAnnotation(coordinate: CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude), title: self.clientName, subtitle: "\(self.clientStreet ?? ""), \(self.clientCity ?? "")")
        clientDetailMapView.addAnnotation(annotation)
        
        self.title = "Kundenstandort"
        
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
}
    

