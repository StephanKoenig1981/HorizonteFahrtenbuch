//
//  archivedRides.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 25.05.23.
//

import Foundation
import RealmSwift


class archivedRides: Object {
    
    @objc dynamic var dateActual: Date?
    
    @objc dynamic var distanceDriven: String?
    @objc dynamic var timeElapsed: String?
    @objc dynamic var currentClientName: String?
    @objc dynamic var supplementDate: String?
    @objc dynamic var isManuallySaved: Bool = false
    
    @objc dynamic var startTime: Date?
    @objc dynamic var endTime: Date?
    @objc dynamic var deliveryTime: Date?
    
    @objc dynamic var encodedPolyline: Data?
    
}
