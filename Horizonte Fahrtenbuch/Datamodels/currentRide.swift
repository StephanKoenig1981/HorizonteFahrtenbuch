//
//  currentRide.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 21.04.23.
//

import Foundation
import RealmSwift

// MARK: THIS CLASS MODEL IS TESTING ONLY

class currentRide: Object {
    
    @objc dynamic var distanceDriven: String?
    @objc dynamic var timeElapsed: String?

}
