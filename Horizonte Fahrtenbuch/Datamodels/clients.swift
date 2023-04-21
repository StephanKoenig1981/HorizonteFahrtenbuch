//
//  clients.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 21.04.23.
//

import Foundation
import RealmSwift

// MARK: Class Model for saving customers.

class clients: Object {
    @objc dynamic var client: String?
    @objc dynamic var clientContactPerson: String?
    @objc dynamic var street: String?
    @objc dynamic var postalCode: String?
    @objc dynamic var city: String?
    @objc dynamic var phone: String?
}
