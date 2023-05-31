//
//  personalDetailsViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 24.05.23.
//

import UIKit
import RealmSwift
import CloudKit
import FileProvider

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
    
    func checkiCLoudAccess() {
        // Request permission to access iCloud Drive
        let fileManager = FileManager.default
        let iCloudDocumentsURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
        if iCloudDocumentsURL != nil {
            print("iCloud Drive access granted.")
        } else {
            let alert = UIAlertController(title: "iCloud Drive Access Required", message: "Please grant permission for this app to access iCloud Drive in the Settings app.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }))
            present(alert, animated: true, completion: nil)
        }
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
    
    // Utility method to get URL of default.realm
    func getDefaultRealmURL() -> URL? {
        return Realm.Configuration.defaultConfiguration.fileURL
    }
    
    // Function to get the URL for the iCloud Drive Documents folder
    func getICloudDocumentsURL() -> URL? {
        let fileManager = FileManager.default
        if let iCloudContainerURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
            return iCloudContainerURL
        }
        return nil
    }
    
    // Restore the Realm database file from iCloud Drive
    func restoreFromiCloudDrive() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        documentPicker.delegate = self
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    // Save the Realm database file to iCloud Drive
    func saveDatabaseToICloud() {
        guard let defaultRealmURL = getDefaultRealmURL() else {
            print("Could not find default.realm")
            return
        }
        
        let realm = try! Realm()
        guard !realm.isEmpty else {
            print("Realm is empty, not copying to iCloud Drive")
            return
        }
        
        let documentPicker = UIDocumentPickerViewController(url: defaultRealmURL, in: .exportToService)
        documentPicker.delegate = self
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    // MARK: Saving database to iCLoud drive
    
    @IBAction func saveDatabaseButtonPressed(_ sender: Any) {
        saveDatabaseToICloud()
        
    }
    
    // MARK: Restoring from iCLoud drive
    
    @IBAction func restoreDatabaseButtonPressed(_ sender: Any) {
        restoreFromiCloudDrive()
        
    }
}

extension personalDetailsViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            return
        }
        
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let sandboxFileURL = dir.appendingPathComponent("default.realm")

        if FileManager.default.fileExists(atPath: sandboxFileURL.path) {
            do {
                try FileManager.default.removeItem(at: sandboxFileURL)
                try FileManager.default.copyItem(at: selectedFileURL, to: sandboxFileURL)
                // Successfully imported the new realm file from iCloud Drive.
                // You might want to reload your data or refresh your UI here.
            } catch {
                // Handle the error
            }
        } else {
            do {
                try FileManager.default.copyItem(at: selectedFileURL, to: sandboxFileURL)
                // Successfully imported the new realm file from iCloud Drive.
                // You might want to reload your data or refresh your UI here.
            } catch {
                // Handle the error
            }
        }
    }
}
    

 


