//
//  SendMessageViewController.swift
//  Cargi
//
//  Created by Edwin Park on 3/6/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import UIKit
import MessageUI

class SendMessageViewController: UIViewController, MFMessageComposeViewControllerDelegate {

    var count: Int = 0
    var phoneNumber: String = "6073791277"
    
    @IBOutlet var messageLabel: UILabel!

    @IBAction func sendText(sender: UIButton) {
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            controller.body = "Hello, welcome to Cargi!"
            controller.recipients = [phoneNumber]
            controller.messageComposeDelegate = self
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        //... handle sms screen actions
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.navigationBarHidden = false
    }
}
