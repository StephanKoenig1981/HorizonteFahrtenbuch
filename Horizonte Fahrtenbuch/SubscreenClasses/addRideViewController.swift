//
//  addRideViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 05.05.23.
//

import UIKit
import RealmSwift

class addRideViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var clientTextfield: UITextField!
    @IBOutlet weak var durationTextfield: UITextField!
    
    @IBOutlet weak var distanceTextfield: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
    
        
        // Disable Swipe Down gesture
        
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        }
        
        let vc = UIViewController()
        vc.presentationController?.presentedView?.gestureRecognizers?[0].isEnabled = false
        
            // Delegates for Textfields
        
            clientTextfield.delegate = self
            durationTextfield.delegate = self
            distanceTextfield.delegate = self
            
    }
    
    // MARK: Functions for keyboard actions
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    
    func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
            self.view.endEditing(true)
        }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
    }
    @IBAction func saveButtonPressed(_ sender: Any) {
        
        if clientTextfield.text == "" {
            let alert = UIAlertController(title: "Pflichtfeld", message: "Bitte fülle alle benötigten Felder aus.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                
                switch action.style{
                    
                    case .default:
                    print("default")
                    
                    case .cancel:
                    print("cancel")
                    
                    case .destructive:
                    print("destructive")
                    
                @unknown default:
                    print("Unknown Fault")
                }
            }))
            self.present(alert, animated: true, completion: nil)
        } else if durationTextfield.text == "" {
            let alert = UIAlertController(title: "Pflichtfeld", message: "Bitte fülle alle benötigten Felder aus.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                
                switch action.style{
                    
                    case .default:
                    print("default")
                    
                    case .cancel:
                    print("cancel")
                    
                    case .destructive:
                    print("destructive")
                    
                @unknown default:
                    print("Unknown Fault")
                }
            }))
            self.present(alert, animated: true, completion: nil)
        } else if distanceTextfield.text == "" {
            let alert = UIAlertController(title: "Pflichtfeld", message: "Bitte fülle alle benötigten Felder aus.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                
                switch action.style{
                    
                    case .default:
                    print("default")
                    
                    case .cancel:
                    print("cancel")
                    
                    case .destructive:
                    print("destructive")
                    
                @unknown default:
                    print("Unknown Fault")
                }
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            
            // MARK: Initializing Realm
            
            
            let currentRides = currentRide()
            
            let date = datePicker.date
            let supplementDate = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d. MMM YY"
            dateFormatter.dateStyle = .long
            
            dateFormatter.string(from: date)
            
            currentRides.timeElapsed = durationTextfield.text
            currentRides.currentClientName = clientTextfield.text
            currentRides.distanceDriven = distanceTextfield.text
            currentRides.supplementDate = dateFormatter.string(from: supplementDate)
            currentRides.date = dateFormatter.string(from: date)
            currentRides.isManuallySaved = true
            
            
            
            currentRides.isManuallySaved = true
            
            saveRealmObject(currentRides: currentRides)
            
            self.dismiss(animated: true)
        }
    }
    
    // MARK: Function for finally saving client to database
    
    func saveRealmObject(currentRides: currentRide) {
            let realm = try? Realm()
            try? realm?.write {
                realm?.add(currentRides)
            }
            print("Data Was Saved To Realm Database.")
    }
    @IBAction func cancellButtonPressed(_ sender: Any) {
        
        let alert = UIAlertController(title: "Bist du sicher?", message: "Bist du sicher, dass du abbrechen möchtest ohne die Fahrt zu speichern?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Fortfahren", style: .cancel))
        alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: { action in
            
            switch action.style{
                
                case .default:
                print("default")
                
                case .cancel:
                self.dismiss(animated: true)
                
                case .destructive:
                self.dismiss(animated: true)
                
            @unknown default:
                print("Unknown Fault")
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
}


