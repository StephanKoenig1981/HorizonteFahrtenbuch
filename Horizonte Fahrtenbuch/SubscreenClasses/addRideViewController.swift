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

            setupUI()
            setupDelegates()
            addTapGesture()
        }
        
        private func setupUI() {
            datePicker.overrideUserInterfaceStyle = .dark
            datePicker.setValue(UIColor.white, forKeyPath: "textColor")
            datePicker.tintColor = UIColor.systemPurple

            clientTextfield.attributedPlaceholder = NSAttributedString(
                string: "Kunde",
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
            )
            durationTextfield.attributedPlaceholder = NSAttributedString(
                string: "00:00:00",
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
            )
            distanceTextfield.attributedPlaceholder = NSAttributedString(
                string: "24.0",
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
            )
            
            // Disable Swipe Down gesture to dismiss modal
            if #available(iOS 13.0, *) {
                self.isModalInPresentation = true
            }
        }
        
        private func setupDelegates() {
            clientTextfield.delegate = self
            durationTextfield.delegate = self
            distanceTextfield.delegate = self
        }
        
    private func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.delegate = self // Ensure this is correctly set
        view.addGestureRecognizer(tapGesture)
    }

        
        // Prevent triggering alert on tapping outside of textfields
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            if let touchedView = touch.view, touchedView.isDescendant(of: clientTextfield) ||
                touchedView.isDescendant(of: durationTextfield) ||
                touchedView.isDescendant(of: distanceTextfield) {
                return false
            }
            return true
        }

        @objc func dismissKeyboard() {
            view.endEditing(true)
        }
        
        // MARK: - Validation Functions
        func isValidTimeFormat(_ input: String) -> Bool {
            let timeRegex = "^\\d{2}:\\d{2}:\\d{2}$"
            let timeTest = NSPredicate(format: "SELF MATCHES %@", timeRegex)
            return timeTest.evaluate(with: input)
        }

        func isValidDistanceFormat(_ input: String) -> Bool {
            let distanceRegex = "^\\d+\\.\\d$"
            let distanceTest = NSPredicate(format: "SELF MATCHES %@", distanceRegex)
            return distanceTest.evaluate(with: input)
        }

        // MARK: - UITextFieldDelegate Methods
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard let currentText = textField.text as NSString? else { return true }
            let newString = currentText.replacingCharacters(in: range, with: string)
            
            if textField == durationTextfield {
                let partialTimeRegex = "^\\d{0,2}(:\\d{0,2})?(:\\d{0,2})?$"
                return NSPredicate(format: "SELF MATCHES %@", partialTimeRegex).evaluate(with: newString)
            } else if textField == distanceTextfield {
                let partialDistanceRegex = "^\\d+(\\.\\d{0,1})?$"
                return NSPredicate(format: "SELF MATCHES %@", partialDistanceRegex).evaluate(with: newString)
            }
            
            return true
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            if textField == durationTextfield, let text = textField.text, !isValidTimeFormat(text) {
                textField.text = ""
                showAlertIfNeeded(message: "Bitte fülle das Feld im folgenden Format aus:\n\n00:00:00")
            } else if textField == distanceTextfield, let text = textField.text, !isValidDistanceFormat(text) {
                textField.text = ""
                showAlertIfNeeded(message: "Bitte fülle das Feld im folgenden Format aus:\n\n0.0")
            }
        }

        // MARK: - Alert for Feedback
        func showAlertIfNeeded(message: String) {
            guard self.isBeingPresented || self.navigationController?.isBeingPresented == true else {
                return // Don't show alert when conditions are met
            }
            let alert = UIAlertController(title: "Eingabe im falschen Format\n", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }

   
    @IBAction func saveButtonPressed(_ sender: Any) {
        
        // Check if any of the text fields are empty
        if clientTextfield.text?.isEmpty ?? true ||
            durationTextfield.text?.isEmpty ?? true ||
            distanceTextfield.text?.isEmpty ?? true {
            showAlert(message: "Bitte fülle alle Felder aus.")
            return
        }
        
        // Validate duration format
        if let durationText = durationTextfield.text, !isValidTimeFormat(durationText) {
            showAlert(message: "Bitte fülle das Feld im folgenden Format aus:\n\n00:00:00")
            return
        }
        
        // Validate distance format
        if let distanceText = distanceTextfield.text, !isValidDistanceFormat(distanceText) {
            showAlert(message: "Bitte fülle das Feld im folgenden Format aus:\n\n0.0")
            return
        }

        // Append "Km" to distance text if valid
        if let distanceText = distanceTextfield.text {
            distanceTextfield.text = "\(distanceText) Km"
        }

        // Prepare the currentRide object for saving
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

        // Save to Realm database
        saveRealmObject(currentRides: currentRides)
        self.dismiss(animated: true)
    }
    
    // Always display an alert without restrictions
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Eingabe im falschen Format\n", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
        
        let generator = UINotificationFeedbackGenerator()
               generator.notificationOccurred(.error)
               
               let alert = UIAlertController(
                   title: "Bist du sicher?",
                   message: "Bist du sicher, dass du abbrechen möchtest ohne die Fahrt zu speichern?",
                   preferredStyle: .actionSheet
               )
               alert.addAction(UIAlertAction(title: "Fortfahren", style: .cancel))
               alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: { _ in
                   self.dismiss(animated: true)
               }))
               self.present(alert, animated: true, completion: nil)
           }
}

// Extension to explicitly confirm protocol conformance
extension addRideViewController: UIGestureRecognizerDelegate {}

