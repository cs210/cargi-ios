//
//  SettingsTableViewController.swift
//  Cargi
//
//  Created by Ishita Prasad on 4/18/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    
    // MARK: Properties
    
    var sectionTitles = [String] ()
    
    var options = [[String]] ()
    
    var homeCell: SettingsTextFieldTableViewCell?

    override func viewDidLoad() {
        super.viewDidLoad()
        loadOptions()

        // Single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SettingsTableViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func loadOptions() {
        
        sectionTitles += ["Connected Map", "Connected Music", "Text Options", "Home"]
        
        options += [[String](), [String](), [String]()]
        
        // adding maps
        options[0] += ["Cargi"]
        if (UIApplication.sharedApplication().canOpenURL(NSURL(string: "comgooglemaps://")!)) {
            options[0] += ["Google Maps"]
        }
        if (UIApplication.sharedApplication().canOpenURL(NSURL(string: "http://maps.apple.com/")!)) {
            options[0] += ["Apple Maps"]
        }
        if (UIApplication.sharedApplication().canOpenURL(NSURL(string: "waze://")!)) {
            options[0] += ["Waze"]
        }
        
        // adding music
        if (UIApplication.sharedApplication().canOpenURL(NSURL(string: "spotify://")!)) {
            options[1] += ["Spotify"]
        }
        if (UIApplication.sharedApplication().canOpenURL(NSURL(string: "http://music.apple.com/")!)) {
            options[1] += ["Apple Music"]
        }
        if (UIApplication.sharedApplication().canOpenURL(NSURL(string: "soundcloud://app")!)) {
            options[1] += ["SoundCloud"]
        }
        
        // adding text
        options[2] += ["Hi, I'll be there in [eta] minutes.", "I'm driving, but I'll be there soon."]
    }


    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionTitles.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 3 {
            return 2
        }
        
        return options[section].count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 3 {
            if indexPath.row == 0 {
                print("textfield")
                let cellIdentifier = "TextFieldTableViewCell"
                let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! SettingsTextFieldTableViewCell
                let userDefaults = NSUserDefaults.standardUserDefaults()
                if let homeAddress = userDefaults.stringForKey("home_address") {
                    if !homeAddress.isEmpty {
                        cell.textfield.text = homeAddress
                    }
                }
                cell.selectionStyle = .None
                homeCell = cell
                return cell
            } else {
                print("Done")
                let cellIdentifier = "DoneTableViewCell"
                let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)!
                cell.selectionStyle = .None
                return cell
            }
        }
        
        let cellIdentifier = "SettingsTableViewCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! SettingsTableViewCell
        
        let option = options[indexPath.section][indexPath.row]
        
        cell.nameLabel.text = option
        

        // Configure the cell...

        return cell
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier("SettingsHeaderTableViewCell") as! SettingsHeaderTableViewCell
        headerCell.nameLabel.text = sectionTitles[section].uppercaseString
        return headerCell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? SettingsTableViewCell else {
            return
        }
        cell.radioButtonView.image = UIImage(named: "radiobutton-selected")
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        guard let selectedIndexPaths = tableView.indexPathsForSelectedRows else { return indexPath }
        
        for selectedIndexPath in selectedIndexPaths {
            if (selectedIndexPath.section == indexPath.section) {
                tableView.deselectRowAtIndexPath(selectedIndexPath, animated:false)
                if let cell = tableView.cellForRowAtIndexPath(selectedIndexPath) as? SettingsTableViewCell {
                    cell.radioButtonView.image = UIImage(named: "radiobutton-unselected")
                }
            }
        }
        return indexPath
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        /* 
         * Temporarily commented out, since radio buttons shouldn't able to be deselected.
         *
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! SettingsTableViewCell
        cell.radioButtonView.image = UIImage(named: "radiobutton-unselected")
         */
        
    }
    
    // Calls this function when the (single/multiple) tap is recognized.
    func dismissKeyboard() {
        // The view's embedded textfields are signaled to resign the first responder status.
        view.endEditing(true)
    }
    
    @IBAction func saveButtonClicked(sender: UIButton) {
        print("save button clicked")
        if let newHomeAddress = homeCell?.textfield.text {
            print("new home address is \(newHomeAddress)")
            let userDefaults = NSUserDefaults.standardUserDefaults()
            userDefaults.setValue(newHomeAddress, forKey: "home_address")
        }
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
