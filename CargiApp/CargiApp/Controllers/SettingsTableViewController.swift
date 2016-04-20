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
    

    override func viewDidLoad() {
        super.viewDidLoad()
        loadOptions()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func loadOptions() {
        
        sectionTitles += ["Connected Map", "Connected Music", "Text Options"]
        
        options += [[String] (), [String] (), [String] ()]
        options[0] += ["Google Maps", "Apple Maps", "Waze"]
        options[1] += ["Spotify", "Apple Music", "SoundCloud"]
        options[2] += ["Hi, I'll be there in [eta] minutes.", "I'm driving, but I'll be there soon."]
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
        
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return options.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options[section].count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
        let cell = self.tableView.cellForRowAtIndexPath(indexPath) as! SettingsTableViewCell
        cell.radioButtonView.image = UIImage(named: "radiobutton-selected")
        
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! SettingsTableViewCell
        cell.radioButtonView.image = UIImage(named: "radiobutton-unselected")
        
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
