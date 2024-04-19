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

    @objc dynamic var companyPostalCode: String?
    @objc dynamic var companyStreet: String?
    @objc dynamic var companyCity: String?
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(yourName: String, bossName: String, email: String, companyPostalCode: String, companyStreet: String, companyCity: String) {
        self.init()
        self.yourName = yourName
        self.bossName = bossName
        self.email = email
        self.companyPostalCode = companyPostalCode
        self.companyStreet = companyStreet
        self.companyCity = companyCity
    }
}
