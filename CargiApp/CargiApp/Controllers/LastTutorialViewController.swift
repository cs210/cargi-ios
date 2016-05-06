//
//  LastTutorialViewController.swift
//  Cargi
//
//  Created by Emily J Tang on 5/3/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import UIKit

class LastTutorialViewController: UIViewController {
    
    @IBAction func readyButtonClicked(sender: UIButton) {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "notFirstLaunchV2.0")
        self.performSegueWithIdentifier("goToLogin", sender: nil)
    }
}
