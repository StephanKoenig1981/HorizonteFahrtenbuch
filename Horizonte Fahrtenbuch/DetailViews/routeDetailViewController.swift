//
//  routeDetailViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 16.05.23.
//

import UIKit
import MapKit

struct Polyline: Codable {
    var points: [PointData]

    init(_ polyline: MKPolyline) {
        self.points = (0 ..< polyline.pointCount).map {
            let mapPoint = polyline.points()[$0]
            let coordinate = mapPoint.coordinate
            return PointData(coordinate)
        }
    }
}

class PointData: Codable {
    var latitude: Double
    var longitude: Double

    init(_ coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
}

class routeDetailViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var routeDetailMapView: MKMapView!
    var encodedPolyline: Data?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Decode the encodedPolyline object
        guard let encodedPolyline = encodedPolyline,
              let polyline = try? JSONDecoder().decode(Polyline.self, from: encodedPolyline) else {
            print("Error decoding polyline")
            return
        }
        print(polyline.points) // Debugging

        // Draw the polyline on the mapView
        let points = polyline.points.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        let mapPolyline = MKPolyline(coordinates: points, count: points.count)
        routeDetailMapView.addOverlay(mapPolyline)
        routeDetailMapView.delegate = self
    }

    // MARK: - MKMapViewDelegate

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer(overlay: overlay)
        }

        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = .blue
        renderer.lineWidth = 5.0
        return renderer
    }

}
