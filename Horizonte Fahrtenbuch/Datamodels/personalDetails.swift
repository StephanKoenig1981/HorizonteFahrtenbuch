//
//  personalDetails.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 24.05.23.
//

import Foundation
import RealmSwift

class personalDetails: Object {
    @objc dynamic var yourName: String?
    @objc dynamic var bossName: String?
}
