//
//  personalDetailsViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 24.05.23.
//

import UIKit
import RealmSwift

class personalDetailsViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var yourNameTextfield: UITextField!
    @IBOutlet weak var bossNameTextfield: UITextField!
    @IBOutlet weak var logoView: UIImageView!
    @IBOutlet weak var saveSuccessTextfield: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the Realm database and retrieve the last saved data
                let realm = try! Realm()
                let lastSavedModel = realm.objects(personalDetails.self).last
                
                // Populate the text fields with the last saved data
                yourNameTextfield.text = lastSavedModel?.yourName
                bossNameTextfield.text = lastSavedModel?.bossName
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        // Get the text from the text fields
        guard let yourName = yourNameTextfield.text,
              let bossName = bossNameTextfield.text
        else {
            return // Exit if there's no text in either of the fields
        }
        
        // Set up the Realm database
        let realm = try! Realm()
        let personalDetails = personalDetails()
        
        personalDetails.yourName = yourName
        personalDetails.bossName = bossName
        
        // Save the data to the Realm database
        try! realm.write {
            realm.add(personalDetails)
        }
        
        saveSuccessTextfield.fadeIn(duration: 0.7)
        logoView.fadeIn(duration: 0.7)
        
        
    }
}

