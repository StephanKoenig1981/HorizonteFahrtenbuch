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
        
        datePicker.overrideUserInterfaceStyle = .dark
        
        datePicker.setValue(UIColor.white, forKeyPath: "textColor")
        datePicker.tintColor = UIColor.systemPurple
        
        clientTextfield.attributedPlaceholder = NSAttributedString(string: "Kunde", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        durationTextfield.attributedPlaceholder = NSAttributedString(string: "00:00:00", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        distanceTextfield.attributedPlaceholder = NSAttributedString(string: "24.0 Km", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
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
        
        // Tap recognizer
        
        // Add Tap Gesture to Dismiss Keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
    }
    
    // Dismiss Keyboard Method
    @objc func dismissKeyboard() {
        view.endEditing(true)
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
            let alert = UIAlertController(title: "Pflichtfeld", message: "Bitte fülle alle Felder aus.", preferredStyle: .alert)
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
            
            currentRides.dateActual = datePicker.date
            
            currentRides.timeElapsed = durationTextfield.text
            currentRides.currentClientName = clientTextfield.text
            currentRides.distanceDriven = distanceTextfield.text
            currentRides.supplementDate = dateFormatter.string(from: supplementDate)
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


