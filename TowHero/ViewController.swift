//
//  ViewController.swift
//  TowHero
//
//  Created by Binh Ly on 6/20/16.
//  Copyright © 2016 3good LLC. All rights reserved.
//

/*import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var heroMap: MKMapView?

    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.locationManager.requestAlwaysAuthorization()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("locations = \(locValue.latitude) \(locValue.longitude)")
    }


}
*/

import UIKit
import MapKit
import XMPPFramework

class ViewController: UIViewController, XMPPPubSubDelegate, CLLocationManagerDelegate, MKMapViewDelegate, XMPPStreamDelegate, XMPPReconnectDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var centerButton: UIButton!
    @IBOutlet weak var pickUpTextField: UITextField!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var upperTextView: UIView!
    @IBOutlet weak var upperViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var orderButton: UIButton!
    
    var pubsub : XMPPPubSub?
    var locationManager : CLLocationManager = CLLocationManager()
    var xmppstream : XMPPStream?
    var number = 0
    var point : RotatingCarAnnotation?
    var point2 : RotatingCarAnnotation?
    var oldCoords : CLLocationCoordinate2D? = nil
    var added = false
    var reconnect : XMPPReconnect = XMPPReconnect()
    
    var driver = false
    var login : String = ""
    var distance : Float = 50.0
    
    var retailAnnotation1 : MKPointAnnotation = MKPointAnnotation()
    var retailAnnotation2 : MKPointAnnotation = MKPointAnnotation()
    
    var retailDirections1 : [CLLocationCoordinate2D] = []
    var retailDirections2 : [CLLocationCoordinate2D] = []
    
    var retailCar1 : RotatingCarAnnotation?
    var retailCar2 : RotatingCarAnnotation?
    
    var oldOverlays : [MKOverlay] = []
    
    var timer : NSTimer = NSTimer()
    var index1 : Int = 0
    var index2 : Int = 0
    
    var idleTimer : NSTimer? = nil
    
    var lock = NSLock()
 
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.pubsub = XMPPPubSub(serviceJID: XMPPJID.jidWithString("pubsub.towhero.co"), dispatchQueue: dispatch_queue_create("XMPP PubSub queue", nil))
        xmppstream = XMPPStream()
        xmppstream?.enableBackgroundingOnSocket = true
        xmppstream?.myJID = XMPPJID.jidWithString("\(login)@towhero.co")
        xmppstream?.addDelegate(self, delegateQueue: dispatch_queue_create("XMPP PubSub main delegate", nil))
        try! xmppstream?.connectWithTimeout(XMPPStreamTimeoutNone)
        //print("here")
        
        //self.numberLabel.text = "\(number)"
        //self.connectionLabel.text = "connecting..."
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.distanceFilter = Double(self.distance)
        self.locationManager.requestWhenInUseAuthorization()
        
        
        self.mapView.rotateEnabled = false
        self.mapView.showsUserLocation = true
        if driver {
            self.view.sendSubviewToBack(centerButton)
        } else {
            self.locationManager.startMonitoringSignificantLocationChanges()
            self.locationManager.startUpdatingLocation()
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.mapTapped))
            self.view.addGestureRecognizer(tap)
            
            //self.upperViewTopConstraint.constant = -self.upperTextView.frame.size.height
            //self.view.layoutIfNeeded()
            self.upperTextView.hidden = false
        }
        
        //self.upperTextView.hidden = true
        
        prettyTextFields()
        prettyButtons()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func prettyTextFields() {
        self.pickUpTextField!.layer.cornerRadius = 15
        self.pickUpTextField!.layer.borderWidth = 1
        self.pickUpTextField!.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).CGColor
        self.pickUpTextField!.backgroundColor = UIColor.whiteColor()
        
        self.destinationTextField!.layer.cornerRadius = 15
        self.destinationTextField!.layer.borderWidth = 1
        self.destinationTextField!.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).CGColor
        self.destinationTextField!.backgroundColor = UIColor.whiteColor()
    }
    
    func prettyButtons() {
        self.orderButton!.layer.cornerRadius = 20
        self.orderButton!.layer.borderColor = UIColor.blackColor().CGColor
        self.orderButton!.layer.borderWidth = 1
        self.orderButton!.backgroundColor = UIColor.darkGrayColor()
        self.centerButton!.layer.cornerRadius = 30
        self.centerButton!.layer.borderColor = UIColor.whiteColor().CGColor
        self.centerButton!.layer.borderWidth = 3
        //self.centerButton!.backgroundColor = UIColor.darkGrayColor()
    }
    
    @IBAction func centerClicked(sender: AnyObject) {
        //let center = CLLocationCoordinate2D(latitude: self.point!.coordinate.latitude, longitude: self.point!.coordinate.longitude)
        //let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        //self.mapView.setCenterCoordinate(self.mapView.userLocation.coordinate, animated: true)//setRegion(region, animated: true)
        let region = MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.coordinate, 1000.0, 1000.0)
        self.mapView.setRegion(region, animated: true)
    }
    
    func mapTapped() {
        print("tapped")
        //showDetail()
        //resetIdleTimer()
        resignEverything()
    }
    
    //override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    func resignEverything() {
        if self.pickUpTextField.isFirstResponder() {
            self.pickUpTextField.resignFirstResponder()
        } else if self.destinationTextField.isFirstResponder() {
            self.destinationTextField.resignFirstResponder()
        }
    }
    
    func showDetail() {
        //check if it is hidden already
        //zoom in detail view
        if upperTextView.hidden {
            upperTextView.hidden = false
            UIView.animateWithDuration(0.3, animations: {
                self.upperViewTopConstraint.constant = 0
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func hideDetail() {
        if !self.upperTextView.hidden {
            UIView.animateWithDuration(0.3, animations: {
                self.upperViewTopConstraint.constant = -self.upperTextView.frame.size.height
                self.view.layoutIfNeeded()
                }, completion: { (result) in
                    self.upperTextView.hidden = true
            })
        }
    }
    
    func resetIdleTimer() {
        if idleTimer == nil {
            print("new timer")
            idleTimer = NSTimer.scheduledTimerWithTimeInterval(4.0, target: self, selector: #selector(ViewController.idleExceeded), userInfo: nil, repeats: false)
        } else {
            print("old timer")
            //if fabs((idleTimer?.fireDate.timeIntervalSinceNow)!) < (5.0 - 1.0) {
                idleTimer?.fireDate = NSDate(timeIntervalSinceNow: 4.0)
            //}
        }
    }
    
    func idleExceeded() {
        //check if either textField is first responder - if yes then don't do anything
        
        print("timer")
        if !(self.pickUpTextField.isFirstResponder() || self.destinationTextField.isFirstResponder()) {
            hideDetail()
            idleTimer = nil
        } else {
            idleTimer = nil
            resetIdleTimer()
        }
        //otherwise hide
        //clear idleTimer
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if driver {
            print("location update")
            let location = locations.first
            let message : XMPPMessage = XMPPMessage()
            let latitude = DDXMLElement.elementWithName("latitude", stringValue: "\((location?.coordinate.latitude)!)") as! DDXMLElement
            let longitude = DDXMLElement.elementWithName("longitude", stringValue: "\((location?.coordinate.longitude)!)") as! DDXMLElement
            let mylogin = DDXMLElement.elementWithName("login", stringValue: login) as! DDXMLElement
            message.addChild(latitude)
            message.addChild(longitude)
            message.addChild(mylogin)
            print(message.XMLString())
            self.pubsub?.publishToNode(login, entry: message)
            self.xmppstream?.sendElement(XMPPPresence(type: "available"))
            number+=1
            //self.numberLabel.text = "\(number)"
        } else {
            CLGeocoder().reverseGeocodeLocation(locations.first!, completionHandler: {(placemarks, error) -> Void in
                
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
            })
            let request = MKLocalSearchRequest()
            request.naturalLanguageQuery = "Retail"
            request.region = MKCoordinateRegionMakeWithDistance(locations.first!.coordinate, 1000.0, 1000.0)
            let search = MKLocalSearch(request: request)
            search.startWithCompletionHandler({(response: MKLocalSearchResponse?, error: NSError?) in
                
                if error != nil {
                    print("Error occured in search: \(error!.localizedDescription)")
                } else if response!.mapItems.count == 0 {
                    print("No matches found")
                } else {
                    print("Matches found")
                    self.mapView.removeOverlays(self.oldOverlays)
                    self.oldOverlays.removeAll()
                    self.retailDirections1.removeAll()
                    self.retailDirections2.removeAll()
                    let items : [MKMapItem] = (response?.mapItems)!
                    if items.count > 0 {
                        self.retailAnnotation1.title = items[0].name
                        self.retailAnnotation1.coordinate = items[0].placemark.coordinate
                        self.mapView.addAnnotation(self.retailAnnotation1)
                        
                        //setup a request for directions
                        let request = MKDirectionsRequest()
                        request.source = MKMapItem(placemark: MKPlacemark(coordinate: locations.first!.coordinate, addressDictionary: nil))
                        request.destination = MKMapItem(placemark: items[0].placemark)
                        request.transportType = MKDirectionsTransportType.Automobile;
                        request.requestsAlternateRoutes = false
                        let directions : MKDirections = MKDirections(request: request)
                        directions.calculateDirectionsWithCompletionHandler { [unowned self] response, error in
                            guard let unwrappedResponse = response else { return }
                            if unwrappedResponse.routes.count > 0 {
                                let route : MKPolyline = unwrappedResponse.routes.first!.polyline
                                let coordsPointer = UnsafeMutablePointer<CLLocationCoordinate2D>.alloc(route.pointCount)
                                route.getCoordinates(coordsPointer, range: NSMakeRange(0, route.pointCount))
                                for i in 0..<route.pointCount {
                                    self.retailDirections1.append(coordsPointer[i])
                                }
                                coordsPointer.dealloc(route.pointCount)
                                self.mapView.addOverlay(route)
                                self.oldOverlays.append(route)
                                self.lock.lock()
                                if let car1 = self.retailCar1 {
                                    self.mapView.removeAnnotation(car1)
                                }
                                self.retailCar1 = RotatingCarAnnotation(title: "car to \(items[0].name)", coordinate: locations.first!.coordinate)
                                print("\(items[0].name)")
                                self.mapView.addAnnotation(self.retailCar1!)
                                self.lock.unlock()
                            }
                        }
                    }
                    if items.count > 1 {
                        self.retailAnnotation2.title = items[1].name
                        self.retailAnnotation2.coordinate = items[1].placemark.coordinate
                        self.mapView.addAnnotation(self.retailAnnotation2)
                        
                        let request = MKDirectionsRequest()
                        request.source = MKMapItem(placemark: MKPlacemark(coordinate: locations.first!.coordinate, addressDictionary: nil))
                        request.destination = MKMapItem(placemark: items[1].placemark)
                        request.transportType = MKDirectionsTransportType.Automobile;
                        request.requestsAlternateRoutes = false
                        let directions : MKDirections = MKDirections(request: request)
                        directions.calculateDirectionsWithCompletionHandler { [unowned self] response, error in
                            guard let unwrappedResponse = response else { return }
                            if unwrappedResponse.routes.count > 0 {
                                let route : MKPolyline = unwrappedResponse.routes.first!.polyline
                                let coordsPointer = UnsafeMutablePointer<CLLocationCoordinate2D>.alloc(route.pointCount)
                                route.getCoordinates(coordsPointer, range: NSMakeRange(0, route.pointCount))
                                for i in 0..<route.pointCount {
                                    self.retailDirections2.append(coordsPointer[i])
                                }
                                coordsPointer.dealloc(route.pointCount)
                                self.mapView.addOverlay(route)
                                self.oldOverlays.append(route)
                                self.lock.lock()
                                if let car2 = self.retailCar2 {
                                    self.mapView.removeAnnotation(car2)
                                }
                                self.retailCar2 = RotatingCarAnnotation(title: "car to \(items[1].name)", coordinate: locations.first!.coordinate)
                                print("\(items[1].name)")
                                self.mapView.addAnnotation(self.retailCar2!)
                                self.lock.unlock()
                            }
                        }
                    }
                    /*for item in response!.mapItems {
                        print("Name = \(item.name)")
                        print("Phone = \(item.phoneNumber)")
                    }*/
                    self.index1 = 0
                    self.index2 = 0
                    self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(ViewController.updateCars), userInfo: nil, repeats: true)
                    let region = MKCoordinateRegionMakeWithDistance((locations.first?.coordinate)!, 1000.0, 1000.0)
                    self.mapView.setRegion(region, animated: true)
                }
            })
            //find 2 retail places
            //find paths to them
            //start timer
            //create annotations
        }
    }
    
    func updateCars() {
        self.lock.lock()
        if retailDirections1.count > 0 {
            index1+=1
            index1 = index1 % (retailDirections1.count)
            //print(index1)
            //print(retailDirections1.count)
            self.retailCar1!.setCoord(self.retailDirections1[index1])
            if let aView = self.mapView.viewForAnnotation(self.retailCar1!) {
                (aView as! RotatingCarAnnotationView).rotate(M_PI/2 + self.retailCar1!.bearing.toRad())
            }
        }
        if retailDirections2.count > 0 {
            index2+=1
            index2 = index2 % (retailDirections2.count)
            self.retailCar2!.setCoord(self.retailDirections2[index2])
            if let aView = self.mapView.viewForAnnotation(self.retailCar2!) {
                (aView as! RotatingCarAnnotationView).rotate(M_PI/2 + self.retailCar2!.bearing.toRad())
            }
        }
        self.lock.unlock()
    }
    
    func xmppPubSub(sender: XMPPPubSub!, didPublishToNode node: String!, withResult iq: XMPPIQ!) {
        print("published")
    }
    
    func xmppPubSub(sender: XMPPPubSub!, didNotPublishToNode node: String!, withError iq: XMPPIQ!) {
        print("not published")
    }
    
    func xmppPubSub(sender: XMPPPubSub!, didNotCreateNode node: String!, withError iq: XMPPIQ!) {
        print("not created: \(iq.XMLString())")
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startMonitoringSignificantLocationChanges()
        self.locationManager.startUpdatingLocation()
        self.mapView.showsUserLocation = true
    }
    
    func xmppPubSub(sender: XMPPPubSub!, didCreateNode node: String!, withResult iq: XMPPIQ!) {
        print("created")
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startMonitoringSignificantLocationChanges()
        self.locationManager.startUpdatingLocation()
        self.mapView.showsUserLocation = true
    }
    
    func xmppPubSub(sender: XMPPPubSub!, didSubscribeToNode node: String!, withResult iq: XMPPIQ!) {
        print("subscribed")
    }
    
    func xmppPubSub(sender: XMPPPubSub!, didReceiveMessage message: XMPPMessage!) {
        //message.elementForName("event").elementForName("items").elementForName("item").elementForName("message").elementForName("body").stringValue()
        if let event = message.elementForName("event") {
            if let items = event.elementForName("items") {
                if let item = items.elementForName("item") {
                    if let message = item.elementForName("message") {
                        if let latitude = message.elementForName("latitude") {
                            if let longitude = message.elementForName("longitude") {
                                print("latitude: \(latitude.stringValueAsFloat())")
                                print("longitude: \(longitude.stringValueAsFloat())")
                                if self.point != nil && self.point!.coordinate.latitude == latitude.stringValueAsDouble() && self.point!.coordinate.longitude == longitude.stringValueAsDouble() {
                                    return
                                }
                                dispatch_async(dispatch_get_main_queue(), {
                                    // code here
                                    if let mylogin = message.elementForName("login") {
                                        print(mylogin.stringValue())
                                        if mylogin.stringValue() == "driver" {
                                            if self.point != nil {
                                                //self.oldCoords = self.point!.coordinate
                                                self.point!.setCoord(CLLocationCoordinate2D(latitude: latitude.stringValueAsDouble(), longitude: longitude.stringValueAsDouble()))
                                                if let aView = self.mapView.viewForAnnotation(self.point!) {
                                                    (aView as! RotatingCarAnnotationView).rotate(M_PI/2 + self.point!.bearing.toRad())
                                                }
                                                //print("\(self.point!.bearing) bearing")
                                            } else {
                                                self.point = RotatingCarAnnotation(title: mylogin.stringValue(), coordinate: CLLocationCoordinate2D(latitude: latitude.stringValueAsDouble(), longitude: longitude.stringValueAsDouble()))
                                                //let center = CLLocationCoordinate2D(latitude: self.point!.coordinate.latitude, longitude: self.point!.coordinate.longitude)
                                                //let region = MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.coordinate, 1000.0, 1000.0)
                                                self.mapView.addAnnotation(self.point!)
                                                //self.mapView.setRegion(region, animated: true)
                                                self.centerButton.enabled = true
                                                //(self.mapView.viewForAnnotation(self.point!) as! RotatingCarAnnotationView).rotate((180.0).toRad())
                                            }
                                        } else {
                                            if self.point2 != nil {
                                                //self.oldCoords = self.point2!.coordinate
                                                self.point2!.setCoord(CLLocationCoordinate2D(latitude: latitude.stringValueAsDouble(), longitude: longitude.stringValueAsDouble()))
                                                if let aView = self.mapView.viewForAnnotation(self.point2!) {
                                                    (aView as! RotatingCarAnnotationView).rotate(M_PI/2 + self.point2!.bearing.toRad())
                                                }
                                                //print("\(self.point!.bearing) bearing")
                                            } else {
                                                self.point2 = RotatingCarAnnotation(title: mylogin.stringValue(), coordinate: CLLocationCoordinate2D(latitude: latitude.stringValueAsDouble(), longitude: longitude.stringValueAsDouble()))
                                                //let center = CLLocationCoordinate2D(latitude: self.point!.coordinate.latitude, longitude: self.point!.coordinate.longitude)
                                                //let region = MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.coordinate, 1000.0, 1000.0)
                                                self.mapView.addAnnotation(self.point2!)
                                                //self.mapView.setRegion(region, animated: true)
                                                self.centerButton.enabled = true
                                                //(self.mapView.viewForAnnotation(self.point!) as! RotatingCarAnnotationView).rotate((180.0).toRad())
                                            }
                                        }
                                    }
                                    self.number+=1
                                    //self.numberLabel.text = "\(self.number)"
                                })
                            }
                        }
                        //return
                    }
                }
            }
        }
        //print("got other message: \(message.XMLString())")
    }
    
    func xmppStreamDidConnect(sender: XMPPStream!) {
        print("connected")
        try! xmppstream?.authenticateWithPassword("password")
        //self.connectionLabel.text = "authenticating..."
    }
    
    func xmppStreamDidAuthenticate(sender: XMPPStream!) {
        print("authenticated")
        //xmppstream?.sendElement(XMPPPresence(type: "available"))
        self.pubsub?.addDelegate(self, delegateQueue: dispatch_queue_create("XMPP PubSub main delegate", nil))
        self.pubsub?.activate(xmppstream)
        self.reconnect.addDelegate(self, delegateQueue: dispatch_queue_create("XMPP Reconnect main delegate", nil))
        self.reconnect.activate(xmppstream)
        if driver {
            self.pubsub?.createNode(login)
        } else {
            self.pubsub?.subscribeToNode("driver")
            self.pubsub?.subscribeToNode("driver2")
        }
        //self.connectionLabel.text = "connected"
        
        //print("here")
    }
    
    func xmppStream(sender: XMPPStream!, didSendPresence presence: XMPPPresence!) {
        print("\(presence.type())")
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.blueColor()
        return renderer
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        // Don't create annotation views for the user location annotation -- OR SHOULD I?
        if annotation is RotatingCarAnnotation {
            
            var myAnnotationView : RotatingCarAnnotationView? = mapView.dequeueReusableAnnotationViewWithIdentifier("RotatingCarAnnotation") as! RotatingCarAnnotationView?
            
            if (myAnnotationView == nil) {
                myAnnotationView = RotatingCarAnnotationView(rotatingAnnotation: point, reuseIdentifier: "RotatingCarAnnotation")
                myAnnotationView?.canShowCallout = true
                let callout = UIImageView(image: UIImage(named: "carIcon"))
                myAnnotationView?.detailCalloutAccessoryView = callout
                
            } else {
                myAnnotationView!.annotation = annotation
            }
            
            
            return myAnnotationView
        }
        return nil
        
    }
    
    func xmppReconnect(sender: XMPPReconnect!, didDetectAccidentalDisconnect connectionFlags: SCNetworkConnectionFlags) {
        print("disconnected")
    }
    
    @IBAction func orderClicked(sender: AnyObject) {
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = "Strathfield"
        //request.region = MKCoordinateRegionMakeWithDistance(locations.first!.coordinate, 1000.0, 1000.0)
        let search = MKLocalSearch(request: request)
        search.startWithCompletionHandler({(response: MKLocalSearchResponse?, error: NSError?) in
            if error != nil {
                print("error")
            } else {
                for item in response!.mapItems {
                    print(item.name!)
                }
            }
        })
    }
    
    
}

