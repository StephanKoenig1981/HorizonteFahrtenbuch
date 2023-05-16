//
//  routeDetailViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 16.05.23.
//

import UIKit
import MapKit

class routeDetailViewController: UIViewController {

    var encodedPolyline: Data?
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var routeDetailMapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        routeDetailMapView.delegate = self
        routeDetailMapView.layer.cornerRadius = 20
        
        // Check if the encodedPolyline is not nil
        guard let encodedPolyline = encodedPolyline else {
            print("There is no encodedPolyline data to decode")
            return
        }
        
        // Decode the encodedPolyline data into a Polyline object
        guard let polyline = try? JSONDecoder().decode(Polyline.self, from: encodedPolyline) else {
            print("Failed to decode the encodedPolyline")
            return
        }
        
        // Create an array of CLLocationCoordinate2D points from the polyline object
        var points: [CLLocationCoordinate2D] = []
        for coordinate in polyline.coordinates {
            let point = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
            points.append(point)
        }
        
        // Create an MKPolyline from the points array and add it to the map
        let polyLine = MKPolyline(coordinates: points, count: points.count)
        routeDetailMapView.addOverlay(polyLine)
        
        // Set the map region to fit the polyline
        if let firstPoint = points.first, let lastPoint = points.last {
            let startRegion = MKCoordinateRegion(center: firstPoint, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            let endRegion = MKCoordinateRegion(center: lastPoint, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            let region = MKCoordinateRegion(center: firstPoint, latitudinalMeters: startRegion.span.latitudeDelta * 2.5 + endRegion.span.latitudeDelta * 2.5, longitudinalMeters: startRegion.span.longitudeDelta * 2.5 + endRegion.span.longitudeDelta * 2.5)
            routeDetailMapView.setRegion(region, animated: true)
        }
    }
}

extension routeDetailViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 3.0
            return renderer
        }
        return MKOverlayRenderer()
    }
}

struct Polyline: Codable {
    var coordinates: [Coordinate]
    
    struct Coordinate: Codable {
        var latitude: Double
        var longitude: Double
    }
}
