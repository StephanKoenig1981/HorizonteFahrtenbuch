//
//  addContactViewController.swift
//  Horizonte Fahrtenbuch
//
//  Created by Stephan König on 21.04.23.
//

import UIKit
import RealmSwift

class addContactViewController: UIViewController, UITextFieldDelegate {

    // MARK: Outlets
    
    @IBOutlet weak var clientTextfield: UITextField!
    @IBOutlet weak var clientContactPersonTextfield: UITextField!
    @IBOutlet weak var streetTextfield: UITextField!
    @IBOutlet weak var postalCodeTextfield: UITextField!
    @IBOutlet weak var cityTextfield: UITextField!
    @IBOutlet weak var phoneTextfield: UITextField!
    
    
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
            clientContactPersonTextfield.delegate = self
            streetTextfield.delegate = self
            postalCodeTextfield.delegate = self
            cityTextfield.delegate = self
            phoneTextfield.delegate = self
        
        clientTextfield.attributedPlaceholder = NSAttributedString(string: "Kunde", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        clientContactPersonTextfield.attributedPlaceholder = NSAttributedString(string: "Ansprechperson", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        streetTextfield.attributedPlaceholder = NSAttributedString(string: "Strasse", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        postalCodeTextfield.attributedPlaceholder = NSAttributedString(string: "PLZ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        cityTextfield.attributedPlaceholder = NSAttributedString(string: "Ort", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        phoneTextfield.attributedPlaceholder = NSAttributedString(string: "Telefon", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        // Add Tap Gesture to Dismiss Keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // Dismiss Keyboard Method
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: Hickup workaround code to hide keyboard when return is pressed
    
    override func viewWillDisappear(_ animated: Bool) {
        super .viewWillDisappear(true)
        self.view.endEditing(true)
    }

    // MARK: Functions for keyboard actions
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    
    func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
            self.view.endEditing(true)
        }
    
    // MARK: IBActions for Button Presses
    
    
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
        } else if streetTextfield.text == "" {
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
        } else if postalCodeTextfield.text == "" {
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
        } else if cityTextfield.text == "" {
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
            
            let client = clients()
            
            client.client = clientTextfield.text
            client.clientContactPerson = clientContactPersonTextfield.text
            client.street = streetTextfield.text
            client.postalCode = postalCodeTextfield.text
            client.city = cityTextfield.text
            client.phone = phoneTextfield.text
            client.uniqueKey = UUID().uuidString
            
            saveRealmObject(client: client)
            
            self.dismiss(animated: true)
        }
    }
    
    // MARK: Function for finally saving client to database
    
    func saveRealmObject(client:clients) {
            let realm = try? Realm()
            try? realm?.write {
                realm?.add(client)
            }
            print("Data Was Saved To Realm Database.")
    }
    
    // MARK: Cancel Button pressed
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        let alert = UIAlertController(title: "Bist du sicher?", message: "Bist du sicher, dass du abbrechen möchtest ohne den Kontakt zu speichern?", preferredStyle: .actionSheet)
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
