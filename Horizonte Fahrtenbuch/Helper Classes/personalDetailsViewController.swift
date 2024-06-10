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
import LocalAuthentication

class personalDetailsViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var yourNameTextfield: UITextField!
    @IBOutlet weak var bossNameTextfield: UITextField!
    @IBOutlet weak var emailTextfield: UITextField!
    
    @IBOutlet weak var companyAddress: UITextField!
    @IBOutlet weak var companyPostalCode: UITextField!
    @IBOutlet weak var companyCity: UITextField!
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var logoView: UIImageView!
    
    @IBOutlet weak var faceIDToggleSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        restoreDatabaseFromICloud()
        
        yourNameTextfield.attributedPlaceholder = NSAttributedString(string: "Dein Name", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        bossNameTextfield.attributedPlaceholder = NSAttributedString(string: "Name des Chefs", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        emailTextfield.attributedPlaceholder = NSAttributedString(string: "beispiel@xyz.ch", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        companyCity.attributedPlaceholder = NSAttributedString(string: "Thalwil", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        companyAddress.attributedPlaceholder = NSAttributedString(string: "Schützenstrasse 7", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        companyPostalCode.attributedPlaceholder = NSAttributedString(string: "8800", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        // Set up the Realm database and retrieve the last saved data
        let realm = try! Realm()
        let lastSavedModel = realm.objects(personalDetails.self).last
        
        // Populate the text fields with the last saved data
        yourNameTextfield.text = lastSavedModel?.yourName
        bossNameTextfield.text = lastSavedModel?.bossName
        emailTextfield.text = lastSavedModel?.email
        companyAddress.text = lastSavedModel?.companyStreet
        companyPostalCode.text = lastSavedModel?.companyPostalCode
        companyCity.text = lastSavedModel?.companyCity
        
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
    
    // MARK: FaceID / TouchID
    
    func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself!"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                completion(success)
            }
        } else {
            completion(false)
        }
    }
    
    // MARK: Check iCloud Access
    
    func checkiCLoudAccess() {
        // Request permission to access iCloud Drive
        let fileManager = FileManager.default
        let iCloudDocumentsURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
        if iCloudDocumentsURL != nil {
            print("iCloud Drive access granted.")
        } else {
            let alert = UIAlertController(title: "iCloud Drive Zugang benötigt", message: "Bitte erlaube der App den Zugriff auf iCloud Drive in der Einstellungen App", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Einstellungen", style: .default, handler: { action in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }))
            present(alert, animated: true, completion: nil)
        }
    }
    
    // Handle cancel operation
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("User cancelled the document picker")
        // Handle the cancellation if needed
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        // Get the text from all text fields
            guard let yourName = yourNameTextfield.text,
                  let bossName = bossNameTextfield.text,
                  let email = emailTextfield.text,
                  let companyCityText = companyCity.text,
                  let companyPostalCodeText = companyPostalCode.text,
                  let companyStreetText = companyAddress.text else {
                print("One or more fields are empty.")
                return // Exit if there's no text in any of the fields
            }
            
            // Set up the Realm database
            let realm = try! Realm()
            let lastSavedModel = realm.objects(personalDetails.self).last ?? personalDetails()

            try! realm.write {
                lastSavedModel.yourName = yourName
                lastSavedModel.bossName = bossName
                lastSavedModel.email = email
                lastSavedModel.companyCity = companyCityText
                lastSavedModel.companyPostalCode = companyPostalCodeText
                lastSavedModel.companyStreet = companyStreetText

                realm.add(lastSavedModel, update: .modified)
            }

            // Assuming logoView is a UIView you want to show as confirmation or feedback
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
        
        checkiCLoudAccess()
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        saveDatabaseToICloud()
        
    }
    
    // MARK: Restoring from iCLoud drive
    
    @IBAction func restoreDatabaseButtonPressed(_ sender: Any) {
        
        checkiCLoudAccess()
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        restoreFromiCloudDrive()
        
    }
    
    // MARK: IBAction for FaceID / TouchID
    
    @IBAction func faceIDToggleSwitchChanged(_ sender: UISwitch) {
        
        // User defaults for FaceID / Touch ID toggle switch
        let userDefaults = UserDefaults.standard
        let authenticationKey = "AuthenticationEnabled"
        
        if sender.isOn {
            authenticateUser { success in
                DispatchQueue.main.async {
                    if success {
                        userDefaults.set(true, forKey: authenticationKey)
                        self.faceIDToggleSwitch.setOn(true, animated: true)
                    } else {
                        self.faceIDToggleSwitch.setOn(false, animated: true)
                    }
                }
            }
        } else {
            userDefaults.set(false, forKey: authenticationKey)
        }
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



 


