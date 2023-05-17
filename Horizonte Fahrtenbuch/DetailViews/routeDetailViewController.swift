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
        
        print("Decoded coordinates: \(points)") // Add this line to print the decoded coordinates
        
        // Create an MKPolyline from the points array and add it to the map
        let polyLine = MKPolyline(coordinates: points, count: points.count)
        routeDetailMapView.addOverlay(polyLine)
        
        routeDetailMapView.setVisibleMapRect(polyLine.boundingMapRect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
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

