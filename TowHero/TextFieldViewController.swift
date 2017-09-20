//
//  TextFieldViewController.swift
//  TowHero
//
//  Created by Pawel Furtek on 6/27/16.
//  Copyright © 2016 3good LLC. All rights reserved.
//

import UIKit
import GoogleMaps

class TextFieldViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var myNavigationItem: UINavigationItem!
    
    var barTitle = ""
    var model = Model.sharedInstance
    
    var data = [GMSAutocompletePrediction]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.navigationBar.topItem?.title = self.title
        self.myNavigationItem.title = self.barTitle
        if barTitle == "Destination" {
            self.textField.text = model.destinationLocation
        } else {
            self.textField.text = model.pickUpLocation
        }
        
        //self.tableView.hidden = true
        
        //self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "locationTableCell")

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        if self.textField.text! != "" {
            GMSPlacesClient().autocompleteQuery(self.textField.text!, bounds: nil, filter: nil) { (results, error) in
                self.data.removeAll()
                if error != nil {
                    print(error)
                } else {
                    self.data = results!
                    self.tableView.reloadData()
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelButtonClicked(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func doneButtonClicked(sender: AnyObject) {
        if self.barTitle == "Destination" {
            self.model.destinationLocation = self.textField.text!
            print(self.textField.text!)
        } else {
            self.model.pickUpLocation = self.textField.text!
            print(self.textField.text!)
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell : UITableViewCell = tableView.dequeueReusableCellWithIdentifier("locationTableCell", forIndexPath: indexPath)
        
        
        let prediction = data[indexPath.row]
        cell.textLabel!.text = "\(prediction.attributedPrimaryText.string)"
        print(prediction.attributedFullText.string)
        cell.detailTextLabel!.text = "\(prediction.attributedSecondaryText! .string)"
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.textField.text = data[indexPath.row].attributedFullText.string
    }
    
    
    
    
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let myText = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        if myText == "" {
            self.data.removeAll()
            self.tableView.reloadData()
            return true
        }
        GMSPlacesClient().autocompleteQuery(myText, bounds: nil, filter: nil) { (results, error) in
            self.data.removeAll()
            if error != nil {
                print(error)
            } else {
                self.data = results!
                self.tableView.reloadData()
            }
        }
        
        return true
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
