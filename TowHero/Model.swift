//
//  Model.swift
//  TowHero
//
//  Created by Pawel Furtek on 6/27/16.
//  Copyright © 2016 3good LLC. All rights reserved.
//

import Foundation
import XMPPFramework

class Model {
    static let sharedInstance = Model()
    
    var xmppstream : XMPPStream?
    var pickUpLocation = ""
    var destinationLocation = ""
    
}
