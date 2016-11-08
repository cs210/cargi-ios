//
//  LoginViewController.swift
//  Cargi
//
//  Created by Edwin Park on 4/30/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    lazy var db = AzureDatabase.sharedInstance
    @IBOutlet weak var loginButton: UIButton!

    @IBOutlet weak var spinnerView: SpinnerView!
    
    
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
            login()
            // should check whether the email exists or not
            return true
        }
        return true
    }
    
    private func login() {
        loginButton.enabled = false
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
                loginButton.enabled = true
                showAlertViewController(title: "Invalid Error", message: "Please input a valid email.")
            } else {
                spinnerView.animate()
                db.emailExists(emailString) { (status, exists) in
                    // server is down
                    if (!exists && status != "Email does not exist") {
                        self.loginButton.enabled = true
                        self.spinnerView.stopAnimation()
                        let alert = UIAlertController(title: "Server Error", message: "Server is currently down. Would you like to continue as an anonymous user?", preferredStyle: UIAlertControllerStyle.Alert)
                        let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.Default, handler: nil)
                        let yesAction = UIAlertAction(title: "Yes", style: .Default) { (action) in
                            let prefs = NSUserDefaults.standardUserDefaults()
                            prefs.setBool(true, forKey: "loggedIn") // set as logged in
                            self.performSegueWithIdentifier("login", sender: nil)
                        }
                        alert.addAction(noAction)
                        alert.addAction(yesAction)
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                    
                    if (!exists) { // if email doesn't exist, user needs to sign up
                        // TODO: some error message or red error text under the login name
                        // "Looks like you don't have an account yet" ??
                        self.loginButton.enabled = true
                        self.spinnerView.stopAnimation()
                        self.showAlertViewController(title: "Login Failed", message: "An account does not exist with this email.")
                    } else {
                        // email exists, but not sure if this actually is the right user
                        // can call checkEmailLogin, which returns if the email is correct or not. (currently just matching the userID, which is based on deviceID)
                        self.db.checkEmailLogin(emailString) { (status, correct) in
                            if (correct) {
                                //TODO: continue to the home screen
                                self.db.initializeUserIDWithEmail(emailString) { (status, success) in
                                    if (success) {
                                        print("initialized user ID:", self.db.userID!)
                                        let prefs = NSUserDefaults.standardUserDefaults()
                                        prefs.setBool(true, forKey: "loggedIn") // set as logged in
                                        prefs.setValue(emailString, forKey: "userEmail")
                                        prefs.setValue(self.db.userID!, forKey: "userID")
                                        
                                        self.loginButton.enabled = true
                                        self.spinnerView.stopAnimation()
                                        self.performSegueWithIdentifier("login", sender: nil)
                                        
                                    } else {
                                        self.loginButton.enabled = true
                                        self.spinnerView.stopAnimation()
                                        self.showAlertViewController(title: "Server Error", message: "Could not connect with server. Please try again.")
                                        //                                        self.showAlertViewController(title: "Server Error", message: status)
                                    }
                                }
                                
                            } else {
                                self.loginButton.enabled = true
                                self.spinnerView.stopAnimation()
                                // print error message about incorrect email login
                                self.showAlertViewController(title: "Login Failed", message: "Login information entered is not correct.")
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func loginButtonClicked(sender: UIButton) {
        login()
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
