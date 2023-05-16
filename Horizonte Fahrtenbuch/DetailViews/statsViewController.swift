//
//  rideSummaryViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 19.04.23.
//

import UIKit
import MapKit
import RealmSwift

extension DefaultStringInterpolation {
  mutating func appendInterpolation<T>(_ optional: T?) {
    appendInterpolation(String(describing: optional))
  }
}

class rideSummaryViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: Initializing Realm

    let realm = try! Realm()
    
    let currentRides = currentRide()

}

