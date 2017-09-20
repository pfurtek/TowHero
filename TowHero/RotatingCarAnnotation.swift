//
//  RotatingCarAnnotation.swift
//  TowHero
//
//  Created by Pawel Furtek on 6/20/16.
//  Copyright © 2016 3good LLC. All rights reserved.
//

import UIKit
import MapKit

extension Double {
    func toRad() -> Double {
        return self/180 * M_PI
    }
    
    func toDeg() -> Double {
        return self * 180 / M_PI
    }
}

class RotatingCarAnnotation: MKPointAnnotation {
    
    var destination : CLLocationCoordinate2D?

    var bearing : Double {
        get {
            if let dest = self.destination {
                let deltaLon : Double = dest.longitude - self.coordinate.longitude;
                let y = sin(deltaLon.toRad()) * cos(dest.latitude.toRad())
                let x = (cos(self.coordinate.latitude.toRad()) * sin(dest.latitude.toRad())) - (sin(self.coordinate.latitude.toRad()) * cos(dest.latitude.toRad()) * cos(deltaLon.toRad()))
                return atan2(y, x).toDeg()
            } else {
                return 0
            }
        }
    }
    
    /*override var coordinate: CLLocationCoordinate2D {
        willSet {
            self.destination = self.coordinate
            self.coordinate = newValue
        }
    }*/
    func setCoord(coord: CLLocationCoordinate2D) {
        self.destination = self.coordinate
        self.coordinate = coord
    }
    
    init(title: String, coordinate: CLLocationCoordinate2D) {
        super.init()
        self.title = title
        self.coordinate = coordinate
    }
}

class RotatingCarAnnotationView: MKAnnotationView {
    
    var imageView : UIImageView?
    var oldBearing : Double = 0
    var lock = NSLock()
    
    convenience init(rotatingAnnotation: RotatingCarAnnotation?, reuseIdentifier: String?) {
        self.init(annotation: rotatingAnnotation, reuseIdentifier: reuseIdentifier)
        self.image = UIImage(named: "empty")
        let myImage = UIImage(named: "carIcon")
        imageView = UIImageView(image: myImage)
        self.addSubview(imageView!)
        self.frame = CGRect(x: -25, y: -13, width: 50, height: 25)
        //self.clipsToBounds = true
    }
    
    func rotate(bearing: Double) {
        lock.lock()
        //print(bearing.toDeg())
        imageView!.transform = CGAffineTransformMakeRotation(CGFloat(bearing))
        //imageView!.center = self.center
        //self.oldBearing = bearing
        lock.unlock()
    }
}
