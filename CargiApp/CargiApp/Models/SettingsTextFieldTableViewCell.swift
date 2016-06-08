//
//  SettingsTextFieldTableViewCell.swift
//  Cargi
//
//  Created by Edwin Park on 5/31/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import UIKit

class SettingsTextFieldTableViewCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet weak var textfield: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField.resignFirstResponder() {
            print("success!")
        } else {
            print("fail")
        }
        self.endEditing(true)
        return true
    }

}
