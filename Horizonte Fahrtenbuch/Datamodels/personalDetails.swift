//
//  personalDetails.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 24.05.23.
//

import Foundation
import RealmSwift

class personalDetails: Object {
    
    @objc dynamic var id = UUID().uuidString
    
    @objc dynamic var yourName: String?
    @objc dynamic var bossName: String?
    @objc dynamic var email: String?
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(firstName: String, lastName: String, email: String, phone: String) {
            self.init()
            self.id = UUID().uuidString
            self.yourName = yourName
            self.bossName = bossName
            self.email = email
        }
}
