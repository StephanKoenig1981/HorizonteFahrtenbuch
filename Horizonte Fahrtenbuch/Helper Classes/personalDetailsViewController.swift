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
    
    // MARK: Saving database to iCLoud drive
    
    @IBAction func saveDatabaseButtonPressed(_ sender: Any) {
        
        checkiCLoudAccess()
        
        let fileManager = FileManager.default
        
        let ubiquityContainerURL = "iCloud.com.horizonte.ch.Horizonte-Fahrtenbuch"

               // Get the URL for the iCloud Drive Documents folder
               if let iCloudDocumentsURL = fileManager.url(forUbiquityContainerIdentifier: ubiquityContainerURL)?.appendingPathComponent("Documents") {
                   let sourceRealmURL = Realm.Configuration.defaultConfiguration.fileURL!

                   // Check if the file already exists in iCloud Drive
                   let targetRealmURL = iCloudDocumentsURL.appendingPathComponent("default.realm")
                   if fileManager.fileExists(atPath: targetRealmURL.path) {
                       do {
                           try fileManager.removeItem(at: targetRealmURL)
                       } catch {
                           // Handle any errors here
                           print(error.localizedDescription)
                       }
                   }

                   // Upload the file to iCloud Drive
                   do {
                       try fileManager.copyItem(at: sourceRealmURL, to: targetRealmURL)

                       // Show an alertView upon successful upload
                       let alert = UIAlertController(title: "Erfolgreich", message: "Die Datenbank wurde erfolgreich nach iCloud Drive exportiert", preferredStyle: .alert)
                       alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                       present(alert, animated: true, completion: nil)
                   } catch {
                       // Handle any errors here
                       print(error.localizedDescription)
                   }
               }
           }
    
    // MARK: Restoring from iCLoud drive
    
    @IBAction func restoreDatabaseButtonPressed(_ sender: Any) {
        
            checkiCLoudAccess()
        
            let fileManager = FileManager.default

            // Get the URL for the iCloud Drive Documents folder
        
            let ubiquityContainerURL = "iCloud.com.horizonte.ch.Horizonte-Fahrtenbuch"
        
            if let iCloudDocumentsURL = fileManager.url(forUbiquityContainerIdentifier: ubiquityContainerURL)?.appendingPathComponent("Documents") {
                let sourceRealmURL = iCloudDocumentsURL.appendingPathComponent("default.realm")

                // Check if the file exists in iCloud Drive
                if fileManager.fileExists(atPath: sourceRealmURL.path) {
                    // Replace the current database with the one from iCloud Drive
                    do {
                        let realm = try Realm()
                        try realm.writeCopy(toFile: Realm.Configuration.defaultConfiguration.fileURL!, encryptionKey: nil)

                        // Show an alertView upon successful restore
                        let alert = UIAlertController(title: "Wiederherstelluung erfolgreich", message: "Die Datenbank wurde erfolgreich aus iCloud Drive wiederhergestellt.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        present(alert, animated: true, completion: nil)
                    } catch {
                        // Handle any errors here
                        print(error.localizedDescription)
                        let alert = UIAlertController(title: "Wiederherstellung fehlgeschlagen", message: "Die Wiederherstellung aus iCloud Drive ist fehlgeschlagen", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        present(alert, animated: true, completion: nil)
                    }
                } else {
                    let alert = UIAlertController(title: "Datenbank nicht gefunden", message: "Die Datenbank konnte nicht auf iCloud Drive gefunden werden.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    present(alert, animated: true, completion: nil)
                }
            }
        }
    }

    

 


