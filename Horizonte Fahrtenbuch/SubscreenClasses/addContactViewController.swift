//
//  addContactViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 21.04.23.
//

import UIKit
import RealmSwift

class addContactViewController: UIViewController {

    // MARK: Outlets
    
    @IBOutlet weak var clientTextfield: UITextField!
    @IBOutlet weak var clientContactPersonTextfield: UITextField!
    @IBOutlet weak var streetTextfield: UITextField!
    @IBOutlet weak var postalCodeTextfield: UITextField!
    @IBOutlet weak var cityTextfield: UITextField!
    @IBOutlet weak var phoneTextfield: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: Initializing Realm
        
        let realm = try! Realm()

    }
    
    // MARK: IBActions for Button Presses
    
    
    @IBAction func saveButtonPressed(_ sender: Any) {
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        
        self.dismiss(animated: true)
    }
}

// MARK: Datastructure for Realm Adress Database

class client: Object {
    objc dynamic var client: String?
}
