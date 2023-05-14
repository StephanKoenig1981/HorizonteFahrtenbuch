//
//  polylineObject.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 14.05.23.
//

import Foundation
import RealmSwift

class PolylineObject: Object {
    @objc dynamic var name: String? // An optional name for the polyline object
    @objc dynamic var encodedPolyline: String? // The encoded polyline data
    
    override static func primaryKey() -> String? {
        return "name"
    }
}
