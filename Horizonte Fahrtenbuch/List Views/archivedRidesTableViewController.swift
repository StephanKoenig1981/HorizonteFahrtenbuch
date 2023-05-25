//
//  archivedRidesTableViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 24.04.23.
//

import UIKit
import RealmSwift


class archivedRidesTableViewController: UITableViewController, UISearchBarDelegate {
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Archivierte Fahrten"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Add a background view to the table view
          let backgroundImage = UIImage(named: "purpleGradient.png")
          let imageView = UIImageView(image: backgroundImage)
          self.tableView.backgroundView = imageView
    }
}
