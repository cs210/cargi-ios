//
//  SettingsTableViewCell.swift
//  Cargi
//
//  Created by Ishita Prasad on 4/17/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {
    
    // MARK: Properties
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var radioButtonView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        if selected {
            self.radioButtonView.image = UIImage(named: "radiobutton-selected")
        } else {
            self.radioButtonView.image = UIImage(named: "radiobutton-unselected")
        }
    }

}
