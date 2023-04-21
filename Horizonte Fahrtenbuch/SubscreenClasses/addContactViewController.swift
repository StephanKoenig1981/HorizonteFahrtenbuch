//
//  addContactViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 21.04.23.
//

import UIKit
import RealmSwift

class addContactViewController: UIViewController, UITextFieldDelegate {

    // MARK: Outlets
    
    @IBOutlet weak var clientTextfield: UITextField!
    @IBOutlet weak var clientContactPersonTextfield: UITextField!
    @IBOutlet weak var streetTextfield: UITextField!
    @IBOutlet weak var postalCodeTextfield: UITextField!
    @IBOutlet weak var cityTextfield: UITextField!
    @IBOutlet weak var phoneTextfield: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
            clientTextfield.delegate = self
            clientContactPersonTextfield.delegate = self
            streetTextfield.delegate = self
            postalCodeTextfield.delegate = self
            cityTextfield.delegate = self
            phoneTextfield.delegate = self
    }
    
    // MARK: Hickup workaround code to hide keyboard when return is pressed
    
    override func viewWillDisappear(_ animated: Bool) {
        super .viewWillDisappear(true)
        self.view.endEditing(true)
    }

    // MARK: Functions for keyboard actions
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    
    func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
            self.view.endEditing(true)
        }
    
    // MARK: IBActions for Button Presses
    
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        
        // MARK: Initializing Realm
        
        let realm = try! Realm()
        
        var client = clients()
        
        client.client = clientTextfield.text
        client.clientContactPerson = clientContactPersonTextfield.text
        client.street = streetTextfield.text
        client.postalCode = postalCodeTextfield.text
        client.city = cityTextfield.text
        client.phone = phoneTextfield.text
        
        try! realm.write {
            realm.add(clients())
            
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        
        self.dismiss(animated: true)
    }
}
