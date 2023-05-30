//
//  personalDetailsViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 24.05.23.
//

import UIKit
import RealmSwift
import CloudKit

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
    @IBAction func saveDatabaseButtonPressed(_ sender: Any) {
        
        let container = CKContainer(identifier: "iCloud.com.horizonte.ch.Horizonte-Fahrtenbuch")
        
        // Request access to iCloud container
        container.requestApplicationPermission(.userDiscoverability) { (status, error) in
            if let error = error {
                print("Error requesting permission: \(error.localizedDescription)")
            } else {
                switch status {
                case .granted:
                    // User granted access to iCloud
                    print("User granted access to iCloud")
                case .denied:
                    // User denied access to iCloud
                    print("User denied access to iCloud")
                default:
                    // Status is 'couldNotComplete' or 'initialState'
                    print("Unable to determine iCloud access status")
                }
            }
        }
        
        let iCloudPath = FileManager.default.url(forUbiquityContainerIdentifier: "iCloud.com.horizonte.ch.Horizonte-Fahrtenbuch")?.appendingPathComponent("Documents/RealmBackup/")
        
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: iCloudPath!, withIntermediateDirectories: true, attributes: nil)
            let realmPath = Realm.Configuration.defaultConfiguration.fileURL!.path
            let destinationPath = iCloudPath!.appendingPathComponent("default.realm")
            try fileManager.copyItem(atPath: realmPath, toPath: destinationPath.path)
            print("File uploaded to iCloud")
        } catch {
            print("Error uploading file to iCloud: \(error.localizedDescription)")
        }
    }
}
 


