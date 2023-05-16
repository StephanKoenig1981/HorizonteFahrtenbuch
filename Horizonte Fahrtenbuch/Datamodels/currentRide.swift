//
//  currentRide.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 21.04.23.
//

import Foundation
import RealmSwift
import CoreLocation

// MARK: THIS CLASS MODEL IS TESTING ONLY

class currentRide: Object {
    
    @objc dynamic var date: String?
    @objc dynamic var distanceDriven: String?
    @objc dynamic var timeElapsed: String?
    @objc dynamic var currentClientName: String?
    @objc dynamic var supplementDate: String?
    @objc dynamic var isManuallySaved: Bool = false
    
    @objc dynamic var encodedPolyline: Data?
    
}
