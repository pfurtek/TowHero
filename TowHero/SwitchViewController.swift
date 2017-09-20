//
//  SwitchViewController.swift
//  trackme
//
//  Created by Pawel Furtek on 6/20/16.
//  Copyright © 2016 Pawel Furtek. All rights reserved.
//

import UIKit

class SwitchViewController: UIViewController {
    @IBOutlet weak var metersLabel: UILabel!
    @IBOutlet weak var metersSlider: UISlider!
    @IBOutlet weak var driverSegment: UISegmentedControl!
    
    var child : MapViewController? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    @IBAction func sliderChanged(sender: AnyObject) {
        self.metersLabel.text = "\(Int(self.metersSlider.value))m"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        let destination = segue.destinationViewController as! MapViewController
        destination.driver = (self.driverSegment.titleForSegmentAtIndex(self.driverSegment.selectedSegmentIndex) != "Rider")
        destination.login = self.driverSegment.titleForSegmentAtIndex(self.driverSegment.selectedSegmentIndex)!.lowercaseString
        destination.distance = self.metersSlider.value
        
        child = destination
    }
    

}
