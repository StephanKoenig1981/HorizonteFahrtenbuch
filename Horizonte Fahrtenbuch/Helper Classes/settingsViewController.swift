//
//  settingsViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 02.05.23.
//

import UIKit
import CloudKit
import RealmSwift

class settingsViewController: UIViewController {
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    private func retrieveLocalRealmURL() -> URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentaryDirectory = urls[0]
        let realmURL = documentaryDirectory.appendingPathComponent("default.realm");
        
        return realmURL
    }

    private func backupRealmToiCloudDrive() {
        let backgroundQueue = DispatchQueue.global(qos: .background)
        
        backgroundQueue.async {
            guard
                let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)
            else {
                return
            }
                
            //let iCloudDriveURL = ubiquityURL.appendingPathComponent("Documents")
            let iCloudRealmURL = ubiquityURL.appendingPathComponent("default.realm")
            
            let fileExists = FileManager.default.fileExists(atPath: iCloudRealmURL.path, isDirectory: nil)
            
            func copy() {
                let localRealmURL = self.retrieveLocalRealmURL()
                
                do {
                    try FileManager.default.copyItem(at: localRealmURL, to: iCloudRealmURL)
                    print ("Die Datei wurde kopiert")
                } catch {
                    print (error.localizedDescription)
                }
            }
            
            if fileExists {
                self.deleteExistedFile(iCloudRealmURL)
                copy()
            } else {
                do {
                    try FileManager.default.createDirectory(at: iCloudRealmURL, withIntermediateDirectories: true, attributes: nil)
                    copy()
                } catch {
                    print (error.localizedDescription)
                }
            }
        }
    }
    

    private func deleteExistedFile(_ url: URL) {
        let fileCoordinator = NSFileCoordinator(filePresenter: nil)
        
        fileCoordinator.coordinate(writingItemAt: url, options: .forDeleting, error: nil) { deleteURL in
            do {
                let fileExists = FileManager.default.fileExists(atPath: deleteURL.path, isDirectory: nil)
                
                if fileExists {
                    try FileManager.default.removeItem(at: deleteURL)
                }
            } catch {
                print (error.localizedDescription)
            }
        }
    }
    
    private func restoreFromiCloudDrive() {
    }
    
    
    @IBAction func uploadPressed(_ sender: Any) {
        backupRealmToiCloudDrive()
        }
    
    
    
    @IBAction func donwloadPressed(_ sender: Any) {
        restoreFromiCloudDrive()
    }
}
