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
        
        restoreDatabaseFromICloud()
        
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
    
    // Function to check if the local Realm file exists
        func localRealmFileExists() -> Bool {
            guard let defaultRealmURL = getDefaultRealmURL() else {
                return false
            }
            return FileManager.default.fileExists(atPath: defaultRealmURL.path)
        }
    
    // Function to restore the Realm database from iCloud Drive
        func restoreDatabaseFromICloud() {
            guard let iCloudDocumentsURL = getICloudDocumentsURL(),
                  let defaultRealmURL = getDefaultRealmURL() else {
                return
            }
            
            let localRealmFileExists = self.localRealmFileExists()
            
            // Check if the local Realm file exists and iCloud Drive contains a newer version
            if localRealmFileExists, let localRealmFileModificationDate = getModificationDateForFile(at: defaultRealmURL),
               let iCloudRealmFileModificationDate = getModificationDateForFile(at: iCloudDocumentsURL.appendingPathComponent("default.realm")),
               iCloudRealmFileModificationDate > localRealmFileModificationDate {
                
                do {
                    try FileManager.default.removeItem(at: defaultRealmURL)
                } catch {
                    print("Error removing local Realm file: \(error)")
                    return
                }
            }
            
            // Copy the Realm file from iCloud Drive if it exists
            let iCloudRealmFileURL = iCloudDocumentsURL.appendingPathComponent("default.realm")
            if FileManager.default.fileExists(atPath: iCloudRealmFileURL.path) {
                do {
                    try FileManager.default.copyItem(at: iCloudRealmFileURL, to: defaultRealmURL)
                    print("Successfully restored Realm database from iCloud Drive")
                } catch {
                    print("Error restoring Realm database from iCloud Drive: \(error)")
                }
            }
        }
        
        // Function to get the modification date of a file at a given URL
        func getModificationDateForFile(at url: URL) -> Date? {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                return attributes[.modificationDate] as? Date
            } catch {
                print("Error getting modification date for file: \(error)")
                return nil
            }
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
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
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
        
        let documentPicker = UIDocumentPickerViewController(forExporting: [defaultRealmURL], asCopy: true)
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
        guard let securityScopedURL = urls.first, securityScopedURL.startAccessingSecurityScopedResource() else {
            return
        }
        
        defer {
            securityScopedURL.stopAccessingSecurityScopedResource()
        }
        
        do {
            let fileManager = FileManager.default
            let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let sandboxFileURL = dir.appendingPathComponent("default.realm")
            
            if fileManager.fileExists(atPath: sandboxFileURL.path) {
                try fileManager.removeItem(at: sandboxFileURL)
            }
            
            try fileManager.copyItem(at: securityScopedURL, to: sandboxFileURL)
            
            // Successfully imported the new realm file from iCloud Drive.
            // You might want to reload your data or refresh your UI here.
        } catch {
            // Handle the error
            print("Error restoring from iCloud Drive: \(error)")
        }
    }
}
    

 


