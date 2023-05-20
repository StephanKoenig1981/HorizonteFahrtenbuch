//
//  pastMonthRides.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 20.05.23.
//

import Foundation
import RealmSwift

class pastMonthRides: Object {
    @objc dynamic var date: String?
    @objc dynamic var totalDistace: String?
    @objc dynamic var totalTimeElapsed: String?
}
