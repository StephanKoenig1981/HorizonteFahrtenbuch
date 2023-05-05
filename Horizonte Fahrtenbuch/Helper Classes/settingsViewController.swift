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
    
    struct DocumentsDirectory {
        static let localDocumentsURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: .userDomainMask).last!
        static let iCloudDocumentsURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func isCloudEnabled() -> Bool {
        if DocumentsDirectory.iCloudDocumentsURL != nil { return true }
        else { return false }
    }
    
    
    @IBAction func uploadPressed(_ sender: Any) {
    }
    
    
    @IBAction func donwloadPressed(_ sender: Any) {
    }
}
