//
//  MapViewController.swift
//  TowHero
//
//  Created by Pawel Furtek on 6/24/16.
//  Copyright © 2016 3good LLC. All rights reserved.
//

import UIKit
import XMPPFramework
import GoogleMaps

struct Static {
    static var token : dispatch_once_t = 0
    static var token2 : dispatch_once_t = 1
    static var token3 : dispatch_once_t = 2
}

class MapViewController: UIViewController, XMPPPubSubDelegate, CLLocationManagerDelegate, XMPPStreamDelegate, XMPPReconnectDelegate, XMPPCapabilitiesDelegate, XMPPRosterDelegate, GMSMapViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var pickUpTextField: UITextField!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var viewWithTextFields: UIView!
    @IBOutlet weak var viewAtBottom: UIView!
    @IBOutlet weak var orderButton: UIButton!
    @IBOutlet weak var centerButton: UIButton!
    @IBOutlet weak var mapView: GMSMapView!
    
    //variables set before segue
    var driver = false
    var login : String = ""
    var distance : Float = 50.0
    
    //XMPP variables
    //var pubsub : XMPPPubSub = XMPPPubSub(serviceJID: nil)
    var pubsub : XMPPPubSub = XMPPPubSub(serviceJID: XMPPJID.jidWithString("pubsub.atlas.chat"), dispatchQueue: dispatch_get_main_queue())
    var xmppstream : XMPPStream = XMPPStream()
    var reconnect : XMPPReconnect = XMPPReconnect()
    var capabilities : XMPPCapabilities = XMPPCapabilities(capabilitiesStorage: XMPPCapabilitiesCoreDataStorage.sharedInstance())
    var roster : XMPPRoster = XMPPRoster(rosterStorage: XMPPRosterCoreDataStorage.sharedInstance())
    
    //location manager variables
    var locationManager : CLLocationManager = CLLocationManager()
    
    //drivers markers
    var driver1 : GMSMarker?
    var driver2 : GMSMarker?
    var oldCoords1 : CLLocationCoordinate2D?
    var oldCoords2 : CLLocationCoordinate2D?
    
    //the map
    //var mapView : GMSMapView?
    var pickUpMarker : GMSMarker?
    var destinationMarker : GMSMarker?
    
    //the model
    var model = Model.sharedInstance
    var placeholder : String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMap()
        setupXMPPConnection()
        setupLocationManager()
        setupTextFields()
        setupBottomView()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        if placeholder == "Destination" {
            self.destinationTextField.text = self.model.destinationLocation
            
            CLGeocoder().geocodeAddressString(destinationTextField.text!) { (placemarks, error) in
                if error != nil {
                    print("forward geocode destination error: \(error?.localizedDescription)")
                    return
                }
                if placemarks!.count > 0 {
                    
                    
                    /*dispatch_async(dispatch_get_main_queue(), {
                     self.mapView?.moveCamera(GMSCameraUpdate.setTarget((placemarks!.first?.location?.coordinate)!))
                     })*/
                }
            }
        } else {
            self.pickUpTextField.text = self.model.pickUpLocation
        
            
            CLGeocoder().geocodeAddressString(pickUpTextField.text!) { (placemarks, error) in
                if error != nil {
                    print("forward geocoder pick up error: \(error?.localizedDescription)")
                    return
                }
                if placemarks!.count > 0 {
                    /*for place in placemarks! {
                        print(place.addressDictionary)
                    }*/
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.mapView?.moveCamera(GMSCameraUpdate.setTarget((placemarks!.first?.location?.coordinate)!))
                    })
                }
            }
            
            //let aGMSGeocoder: GMSGeocoder = GMSGeocoder()
            //aGMSGeocoder.
            
            /*reverseGeocodeCoordinate(locations.first!.coordinate, completionHandler: { (response, error) in
                if error != nil {
                    print(error)
                } else {
                    print(response!.firstResult()!.lines)
                    self.pickUpTextField.text = response?.firstResult()?.thoroughfare
                }
            })*/
        }
    }
    
    func setupMap() {
        //let camera = GMSMutableCameraPosition.cameraWithLatitude(51.0545, longitude: 17.023, zoom: 17)
        //mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
        mapView!.myLocationEnabled = true
        self.view.addSubview(mapView!)
        if !driver {
            self.view.sendSubviewToBack(self.mapView!)
        }
        
        mapView.moveCamera(GMSCameraUpdate.zoomTo(16.0))
        
        mapView?.delegate = self
        
        //allow textfields to be used
        //mapView?.settings.consumesGesturesInView = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(MapViewController.mapTapped))
        self.view.addGestureRecognizer(tap)
        
        //moving google icon
        mapView?.padding = UIEdgeInsetsMake(125.0, 0.0, 125.0, 0.0)
        
        mapView?.trafficEnabled = true
        
        mapView?.settings.allowScrollGesturesDuringRotateOrZoom = false
        
        
        /*
         self.view.addSubview(self.viewWithTextFields)
         let leftConstraint = NSLayoutConstraint(item: self.viewWithTextFields, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0)
         let rightConstraint = NSLayoutConstraint(item: self.viewWithTextFields, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0)
         self.view.addConstraints([leftConstraint, rightConstraint])
         */
        
        /*
        
        self.mapView?.removeConstraints((self.mapView?.constraints)!)
        
        let topConstraint = NSLayoutConstraint(item: mapView!, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: mapView!, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
        let leftConstraint = NSLayoutConstraint(item: self.mapView!, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0)
        let rightConstraint = NSLayoutConstraint(item: self.mapView!, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0)
        self.view.addConstraints([topConstraint, bottomConstraint, leftConstraint, rightConstraint])
 
        */
    }
    
    func mapTapped() {
        print("tapped")
        if self.pickUpTextField.isFirstResponder() {
            self.pickUpTextField.resignFirstResponder()
        } else if self.destinationTextField.isFirstResponder() {
            self.destinationTextField.resignFirstResponder()
        }
    }
    
    func setupXMPPConnection() {
        //self.pubsub = XMPPPubSub(serviceJID: XMPPJID.jidWithString("pubsub.atlas.chat"), dispatchQueue: dispatch_get_main_queue())//dispatch_queue_create("XMPP PubSub queue", nil))
        //self.pubsub = XMPPPubSub(serviceJID: nil)
        //xmppstream = XMPPStream()
        xmppstream.enableBackgroundingOnSocket = true
        xmppstream.myJID = XMPPJID.jidWithString("\(login)@atlas.chat")
        xmppstream.addDelegate(self, delegateQueue: dispatch_get_main_queue())//dispatch_queue_create("XMPP PubSub main delegate", nil))
        try! xmppstream.connectWithTimeout(XMPPStreamTimeoutNone)
    }
    
    func setupLocationManager() {
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.distanceFilter = Double(self.distance)
        self.locationManager.requestWhenInUseAuthorization()
        if !driver {
            self.locationManager.startMonitoringSignificantLocationChanges()
            self.locationManager.startUpdatingLocation()
        }
    }
    
    func setupTextFields() {
        self.pickUpTextField!.layer.cornerRadius = 15
        self.pickUpTextField!.layer.borderWidth = 1
        self.pickUpTextField!.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).CGColor
        self.pickUpTextField!.backgroundColor = UIColor.whiteColor()
        //self.pickUpTextField!.enabled = true
        self.pickUpTextField!.userInteractionEnabled = true
        
        self.destinationTextField!.layer.cornerRadius = 15
        self.destinationTextField!.layer.borderWidth = 1
        self.destinationTextField!.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).CGColor
        self.destinationTextField!.backgroundColor = UIColor.whiteColor()
        //self.destinationTextField!.enabled = true
        self.destinationTextField!.userInteractionEnabled = true
        
        /*
        self.view.addSubview(self.viewWithTextFields)
        let leftConstraint = NSLayoutConstraint(item: self.viewWithTextFields, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0)
        let rightConstraint = NSLayoutConstraint(item: self.viewWithTextFields, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0)
        self.view.addConstraints([leftConstraint, rightConstraint])
        */
    }
    
    func setupBottomView() {
        setupTabBar()
        setupButtons()
        
        /*
        self.view.addSubview(self.viewAtBottom)
        let leftConstraint = NSLayoutConstraint(item: self.viewAtBottom, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0)
        let rightConstraint = NSLayoutConstraint(item: self.viewAtBottom, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self.viewAtBottom, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
        self.view.addConstraints([leftConstraint, rightConstraint, bottomConstraint])
        */
    }
    
    func setupTabBar() {
        //self.tabBar.superview!.backgroundColor = UIColor.clearColor()
        //self.tabBar.backgroundImage = UIImage()
        //self.view.addSubview(self.tabBar)
        /*for item in self.tabBar.items! {
            
            let unselectedItem: NSDictionary = [NSForegroundColorAttributeName: UIColor.yellowColor()]
            let selectedItem: NSDictionary = [NSForegroundColorAttributeName: UIColor.yellowColor()]
            item.setTitleTextAttributes(unselectedItem as? [String : AnyObject], forState: .Normal)
            item.setTitleTextAttributes(selectedItem as? [String : AnyObject], forState: .Selected)
        }*/
    }
    
    func setupButtons() {
        self.orderButton!.layer.cornerRadius = 20
        self.orderButton!.layer.borderColor = UIColor.blackColor().CGColor
        self.orderButton!.layer.borderWidth = 1
        self.orderButton!.backgroundColor = UIColor.darkGrayColor()
        self.centerButton!.layer.cornerRadius = 25
        self.centerButton!.layer.borderColor = UIColor.darkGrayColor().CGColor
        self.centerButton!.layer.borderWidth = 2
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Location updating
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("location update")
        if driver {
            let location = locations.first
            //let message : XMPPMessage = XMPPMessage()
            //let presence : XMPPPresence = XMPPPresence()
            let latitude = DDXMLElement.elementWithName("latitude", stringValue: "\((location?.coordinate.latitude)!)") as! DDXMLElement
            let longitude = DDXMLElement.elementWithName("longitude", stringValue: "\((location?.coordinate.longitude)!)") as! DDXMLElement
            let mylogin = DDXMLElement.elementWithName("login", stringValue: login) as! DDXMLElement
            let mylocation = DDXMLElement.elementWithName("geoloc", children: [latitude, longitude, mylogin], attributes: nil) as! DDXMLElement
            //message.addChild(latitude)
            //message.addChild(longitude)
            //message.addChild(mylogin)
            //message.addChild(mylocation)
            //presence.addChild(mylocation)
            //presence.addChild(mylogin)
            //print(message.XMLString())
            //self.xmppstream?.sendElement(presence)
            
            self.pubsub.publishToNode(login, entry: mylocation)
            /*
            if self.pubsub.xmppStream != nil {
                print("stream not nil")
            } else {
                print("stream nil")
            }
            self.pubsub.publishToNode("http://jabber.org/protocol/geoloc", entry: mylocation)
            */
        } else {
            print("geocode")
                        
            
            dispatch_once(&Static.token, {
                dispatch_async(dispatch_get_main_queue(), {
                    if let location = self.mapView?.myLocation {
                        self.mapView?.moveCamera(GMSCameraUpdate.setTarget(location.coordinate))
                    }
                })
            })
 
            
            /*let aGMSGeocoder: GMSGeocoder = GMSGeocoder()
            aGMSGeocoder.reverseGeocodeCoordinate(locations.first!.coordinate, completionHandler: { (response, error) in
                if error != nil {
                    print(error)
                } else {
                    print(response!.firstResult()!.lines)
                    self.pickUpTextField.text = response?.firstResult()?.thoroughfare
                }
            })*/
            /*CLGeocoder().reverseGeocodeLocation(locations.first!, completionHandler: {(placemarks, error) -> Void in
                
                if error != nil {
                    print("reverse geocoder error: \(error?.localizedDescription)")
                    return
                }
                if placemarks!.count > 0 {
                    if let thorough = placemarks!.first?.thoroughfare {
                        if let subThorough = placemarks!.first?.subThoroughfare {
                            self.pickUpTextField.text = "\(subThorough) \(thorough)"
                        } else {
                            self.pickUpTextField.text = "\(thorough)"
                        }
                    }
                }
            })*/
        }
    }
    
    // MARK: - XXMPP
    
    
    func xmppPubSub(sender: XMPPPubSub!, didPublishToNode node: String!, withResult iq: XMPPIQ!) {
        print("published")
    }
    
    func xmppPubSub(sender: XMPPPubSub!, didNotPublishToNode node: String!, withError iq: XMPPIQ!) {
        print("not published: \(iq.XMLString())")
    }
    
    func xmppPubSub(sender: XMPPPubSub!, didNotCreateNode node: String!, withError iq: XMPPIQ!) {
        print("not created")//: \(iq.XMLString())")
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startMonitoringSignificantLocationChanges()
        self.locationManager.startUpdatingLocation()
    }
    
    func xmppPubSub(sender: XMPPPubSub!, didCreateNode node: String!, withResult iq: XMPPIQ!) {
        print("created")
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startMonitoringSignificantLocationChanges()
        self.locationManager.startUpdatingLocation()
    }
    
    func xmppPubSub(sender: XMPPPubSub!, didSubscribeToNode node: String!, withResult iq: XMPPIQ!) {
        print("subscribed")
    }
    
    func xmppPubSub(sender: XMPPPubSub!, didReceiveMessage message: XMPPMessage!) {
        //message.elementForName("event").elementForName("items").elementForName("item").elementForName("message").elementForName("body").stringValue()
        if let event = message.elementForName("event") {
            if let items = event.elementForName("items") {
                if let item = items.elementForName("item") {
                    if let message = item.elementForName("geoloc") {
                        if let latitude = message.elementForName("latitude") {
                            if let longitude = message.elementForName("longitude") {
                                print("latitude: \(latitude.stringValueAsFloat())")
                                print("longitude: \(longitude.stringValueAsFloat())")
                                if let mylogin = message.elementForName("login") {
                                    print(mylogin.stringValue())
                                    if mylogin.stringValue() == "driver" {
                                        if self.driver1 != nil && self.driver1!.position.latitude == latitude.stringValueAsDouble() && self.driver1!.position.longitude == longitude.stringValueAsDouble() {
                                            return
                                        }
                                        dispatch_async(dispatch_get_main_queue(), {
                                            if self.driver1 != nil {
                                                self.oldCoords1 = self.driver1?.position
                                                self.driver1!.position = CLLocationCoordinate2D(latitude: latitude.stringValueAsDouble(), longitude: longitude.stringValueAsDouble())
                                                self.driver1!.groundAnchor = CGPoint(x: 0.5, y: 0.5)
                                                self.driver1!.rotation = self.bearing(self.oldCoords1!, new: self.driver1!.position) + 90.0
                                            } else {
                                                self.driver1 = GMSMarker(position: CLLocationCoordinate2D(latitude: latitude.stringValueAsDouble(), longitude: longitude.stringValueAsDouble()))
                                                self.driver1!.icon = UIImage(named: "carIcon")
                                                self.driver1!.map = self.mapView
                                                self.driver1!.flat = true
                                            }
                                        })
                                    } else {
                                        if self.driver2 != nil && self.driver2!.position.latitude == latitude.stringValueAsDouble() && self.driver2!.position.longitude == longitude.stringValueAsDouble() {
                                            return
                                        }
                                        dispatch_async(dispatch_get_main_queue(), {
                                            if self.driver2 != nil {
                                                self.oldCoords2 = self.driver2?.position
                                                self.driver2!.position = CLLocationCoordinate2D(latitude: latitude.stringValueAsDouble(), longitude: longitude.stringValueAsDouble())
                                                self.driver2!.groundAnchor = CGPoint(x: 0.5, y: 0.5)
                                                self.driver2!.rotation = self.bearing(self.oldCoords2!, new: self.driver2!.position) + 90.0
                                            } else {
                                                self.driver2 = GMSMarker(position: CLLocationCoordinate2D(latitude: latitude.stringValueAsDouble(), longitude: longitude.stringValueAsDouble()))
                                                self.driver2!.icon = UIImage(named: "carIcon")
                                                self.driver2!.map = self.mapView
                                                self.driver2!.flat = true
                                            }
                                        })
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        print("got message: \(message.XMLString())")
    }
    
    func xmppStreamDidConnect(sender: XMPPStream!) {
        print("connected")
        try! xmppstream.authenticateWithPassword("password")
    }
    
    func xmppStreamDidAuthenticate(sender: XMPPStream!) {
        print("authenticated")
        //xmppstream?.sendElement(XMPPPresence(type: "available"))
        self.pubsub.addDelegate(self, delegateQueue: dispatch_queue_create("XMPP PubSub main delegate", nil))
        self.pubsub.activate(xmppstream)
        self.reconnect.addDelegate(self, delegateQueue: dispatch_queue_create("XMPP Reconnect main delegate", nil))
        self.reconnect.activate(xmppstream)
        self.capabilities.addDelegate(self, delegateQueue: dispatch_queue_create("XMPP Capabilities main delegate", nil))
        self.capabilities.activate(xmppstream)
        self.roster.activate(xmppstream)
        self.roster.addDelegate(self, delegateQueue: dispatch_queue_create("XMPP Roster main delegate", nil))
        if driver {
            self.pubsub.createNode(login)
            //self.pubsub.createNode("location")
            self.roster.addUser(XMPPJID.jidWithString("rider@atlas.chat"), withNickname: "Rider")
            
            self.locationManager.startMonitoringSignificantLocationChanges()
            self.locationManager.startUpdatingLocation()
            
        } else {
            self.pubsub.subscribeToNode("driver")
            //self.roster.addUser(XMPPJID.jidWithString("driver@atlas.chat"), withNickname: "Driver1")
            self.pubsub.subscribeToNode("driver2")
            //self.roster.addUser(XMPPJID.jidWithString("driver2@atlas.chat"), withNickname: "Driver2")
        }
        
        //self.xmppstream?.resendMyPresence()
        self.xmppstream.sendElement(XMPPPresence())
    }
    
    func xmppStream(sender: XMPPStream!, didSendIQ iq: XMPPIQ!) {
        print("sent: \(iq.XMLString())")
    }
    
    func xmppStream(sender: XMPPStream!, willSendIQ iq: XMPPIQ!) -> XMPPIQ! {
        print("will send: \(iq.XMLString())")
        return iq
    }
    
    func xmppStream(sender: XMPPStream!, didSendPresence presence: XMPPPresence!) {
        print("sent: \(presence.XMLString())")
    }
    
    func xmppStream(sender: XMPPStream!, didReceivePresence presence: XMPPPresence!) {
        print("received: \(presence.XMLString())")
    }
    
    func xmppCapabilities(sender: XMPPCapabilities!, collectingMyCapabilities query: DDXMLElement!) {
        print("collecting")
    }
    
    func myFeaturesForXMPPCapabilities(sender: XMPPCapabilities!) -> [AnyObject]! {
        print("myFeatures")
        var features : [AnyObject] = []
        if driver {
            features.append("geoloc")
        } else {
            features.append("geoloc+notify")
        }
        return features
    }
    
    // MARK: - map delegate
    func mapView(mapView: GMSMapView, idleAtCameraPosition position: GMSCameraPosition) {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: position.target.latitude, longitude: position.target.longitude), completionHandler: {(placemarks, error) -> Void in
            
            if error != nil {
                print("reverse geocoder error: \(error?.localizedDescription)")
                return
            }
            if placemarks!.count > 0 {
                if let city = placemarks!.first?.locality {
                    if let street = placemarks!.first?.thoroughfare {
                        if let number = placemarks!.first?.subThoroughfare {
                            self.pickUpTextField.text = "\(number) \(street), \(city)"
                            self.model.pickUpLocation = "\(number) \(street), \(city)"
                        } else {
                            self.pickUpTextField.text = "\(street), \(city)"
                            self.model.pickUpLocation = "\(street), \(city)"
                        }
                    } else {
                        if let number = placemarks!.first?.subThoroughfare {
                            self.pickUpTextField.text = "\(number) \(city)"
                            self.model.pickUpLocation = "\(number) \(city)"
                        } else {
                            self.pickUpTextField.text = city
                            self.model.pickUpLocation = city
                        }
                    }
                }
            }
        })
    }
    
    func mapView(mapView: GMSMapView, didTapMarker marker: GMSMarker) -> Bool {
        mapView.selectedMarker = marker
        return true
    }
    
    // MARK: - Text Field Delegate functions
    func textFieldDidBeginEditing(textField: UITextField) {
        placeholder = textField.placeholder
        textField.resignFirstResponder()
    }

    // MARK: - Bearing function
    func bearing(old: CLLocationCoordinate2D, new: CLLocationCoordinate2D) -> Double {
        let deltaLon : Double = old.longitude - new.longitude;
        let y = sin(deltaLon.toRad()) * cos(old.latitude.toRad())
        let x = (cos(new.latitude.toRad()) * sin(old.latitude.toRad())) - (sin(new.latitude.toRad()) * cos(old.latitude.toRad()) * cos(deltaLon.toRad()))
        let bearing = atan2(y, x).toDeg()
        print(bearing)
        return bearing
    }
    
    @IBAction func centerClicked(sender: AnyObject) {
        print("center clicked")
        dispatch_async(dispatch_get_main_queue(), {
            if let location = self.mapView?.myLocation {
                self.mapView?.moveCamera(GMSCameraUpdate.setTarget(location.coordinate))
            }
        })
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.destinationViewController is TextFieldViewController {
            let destination = segue.destinationViewController as! TextFieldViewController
            destination.barTitle = placeholder!
        }
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    

}
