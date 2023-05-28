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
    @IBOutlet weak var emailTextfield: UITextField!
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var logoView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        yourNameTextfield.attributedPlaceholder = NSAttributedString(string: "Dein Name", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        bossNameTextfield.attributedPlaceholder = NSAttributedString(string: "Name des Chefs", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        emailTextfield.attributedPlaceholder = NSAttributedString(string: "beispiel@xyz.ch", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        
        // Set up the Realm database and retrieve the last saved data
                let realm = try! Realm()
                let lastSavedModel = realm.objects(personalDetails.self).last
                
                // Populate the text fields with the last saved data
                yourNameTextfield.text = lastSavedModel?.yourName
                bossNameTextfield.text = lastSavedModel?.bossName
                emailTextfield.text = lastSavedModel?.email
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        // Get the text from the text fields
        guard let yourName = yourNameTextfield.text,
              let bossName = bossNameTextfield.text,
              let email = emailTextfield.text
        else {
            return // Exit if there's no text in either of the fields
        }
        
        // Set up the Realm database
        let realm = try! Realm()
        let lastSavedModel = realm.objects(personalDetails.self).last ?? personalDetails()
           
           
           try! realm.write {
               lastSavedModel.yourName = yourName
               lastSavedModel.bossName = bossName
               lastSavedModel.email = email
               realm.add(lastSavedModel, update: .modified)
           }

        
        logoView.fadeIn(duration: 0.7)
        
        
    }
}

