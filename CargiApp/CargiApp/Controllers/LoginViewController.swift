//
//  LoginViewController.swift
//  Cargi
//
//  Created by Edwin Park on 4/30/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var emailTextField: UITextField!
    lazy var db = AzureDatabase.sharedInstance

    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.emailTextField.delegate = self
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == emailTextField {
            textField.resignFirstResponder()
            print("Done typing")
            print("Should log in now")
            // should check whether the email exists or not
            return false
        }
        return true
    }
    
    @IBAction func loginButtonClicked(sender: UIButton) {
        let email = emailTextField.text
        if (email == nil) {
            // TODO: some error message or red error text under the login name
            // "PLEASE LOGIN?"
            showAlertViewController(title: "Error", message: "Email is invalid.")
        } else {
            let emailString = email!
            if (!db.validateEmail(emailString)) {
                // TODO: some error message or red error text under the login name, if we know it's an invalid email
                // can also do nothing, unless we want a better UX (let users know they have a typo for instance)
                showAlertViewController(title: "Invalid Error", message: "Please input a valid email or name.")
            } else {
                activityIndicatorView.startAnimating()
                db.emailExists(emailString) { (status, exists) in
                    if (!exists) { // if email doesn't exist, user needs to sign up
                        // TODO: some error message or red error text under the login name
                        // "Looks like you don't have an account yet" ??
                        self.activityIndicatorView.stopAnimating()
                        self.showAlertViewController(title: "Login Failed", message: "An account does not exist with this email.")
                    } else {
                        // email exists, but not sure if this actually is the right user
                        // can call checkEmailLogin, which returns if the email is correct or not. (currently just matching the userID, which is based on deviceID)
                        self.db.checkEmailLogin(emailString) { (status, correct) in
                            if (correct) {
                                //TODO: continue to the home screen
                                self.db.initializeUserID(UIDevice.currentDevice().identifierForVendor!.UUIDString) { (status, success) in
                                    if (success) {
                                        print("initialized user ID:", self.db.userID!)
                                        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "loggedIn") // set as logged in
                                        self.activityIndicatorView.stopAnimating()
                                        self.performSegueWithIdentifier("login", sender: nil)

                                    } else {
                                        self.activityIndicatorView.stopAnimating()
                                        self.showAlertViewController(title: "Server Error", message: "Could not connect with server. Please try again.")
                                    }
                                }
                                
                            } else {
                                self.activityIndicatorView.stopAnimating()
                                // print error message about incorrect email login
                                self.showAlertViewController(title: "Login Failed", message: "Login information entered is not correct.")
                            }
                        }
                    }
                }
            }
        }
    }

    @IBAction func returnToLoginViewController(segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func logoutToLoginViewController(segue: UIStoryboardSegue) {
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
    }
    */

}
