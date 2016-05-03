//
//  SignupViewController.swift
//  Cargi
//
//  Created by Edwin Park on 4/30/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import UIKit

class SignupViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    lazy var db = AzureDatabase.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        self.nameTextField.delegate = self
        self.emailTextField.delegate = self
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == emailTextField {
            // email text field clicked "done"
            textField.resignFirstResponder()
            print("Go to the next page")
            return true
        } else if textField == nameTextField {
            // name text field clicked "done"
            textField.resignFirstResponder()
            return true
        }
        return true
    }

    @IBAction func signupButtonClicked(sender: UIButton) {
        let name = nameTextField.text
        let email = emailTextField.text
        
        if (email == nil || name == nil) {
            // TODO: some error message or red error text under the login name
            // "PLEASE ENTER A NAME OR EMAIL" // can also make this more fine-grained, and display specific error messages
            
        } else {
            let emailString = email!
            let nameString = name!
            if (db.validateEmail(emailString) && nameString != "") {
                db.emailExists(emailString) { (status, exists) in
                    if (!exists) { // if email doesn't exist, user can use this email to sign up with
                        print("Email does not exist yet, signing up")
                        self.db.createUser(UIDevice.currentDevice().identifierForVendor!.UUIDString, email: emailString, fullname: nameString) { (status, success) in
                            if (success) {
                                let prefs = NSUserDefaults.standardUserDefaults()
                                prefs.setBool(true, forKey: "loggedIn")
                                prefs.setValue(emailString, forKey: "userEmail")
                                self.showAlertViewControllerWithHandler(title: "Success", message: "A new account has been created.") { (action: UIAlertAction) in
                                    self.performSegueWithIdentifier("signup", sender: nil)
                                }
                            } else {
                                self.showAlertViewController(title: "Server Error", message: "Could not connect with server. Please try again.")
                            }
                        }
                    } else {
                        // email exists
                        print("Account already exists with this email!")
                        // potentially dangerous -> people will just sign in with other people's emails.
                        // they can just check if the email exists or not, and go back to the login page.
                        
                        // TODO: there should be some kind of button that redirects user back to login page, they might have forgotten that they already signed up before (?)
                        self.showAlertViewController(title: "Email in Use", message: "An account already exists with this email!")
                    }
                }
            } else {
                // TODO: some error message or red error text under the login name
                // "PLEASE INPUT A VALID EMAIL OR NAME (?)"
                showAlertViewController(title: "Error", message: "Please input a valid email or name.")
            }
        }
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        segue.destinationViewController
    }

}


