//
//  SendMessageViewController.swift
//  Cargi
//
//  Created by Edwin Park on 3/6/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import UIKit
import MessageUI
import QuartzCore

class SendMessageViewController: UIViewController, MFMessageComposeViewControllerDelegate {

    var phoneNumber: String = "6073791277"
    
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var dashboard: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layer: CALayer = self.dashboard.layer
        layer.shadowOffset = CGSizeMake(1, 1);
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowRadius = 1.5
        layer.shadowOpacity = 0.7
        layer.shadowPath = UIBezierPath(rect: layer.bounds).CGPath
    }
    
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
