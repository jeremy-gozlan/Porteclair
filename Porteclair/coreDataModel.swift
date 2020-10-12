//
//  coreDataModel.swift
//  Porteclair
//
//  Created by Jeremy on 12/03/2018.
//  Copyright © 2018 Jeremy. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class sensorCore : NSManagedObject {
    
    @NSManaged var battery : Int
    @NSManaged var id : Int
    @NSManaged var lat : Double
    @NSManaged var long : Double
    
    
}

class SensorCore : NSObject, NSCoding {
    
    struct Keys {
        static let Id = "id"
        static let Battery = "battery"
        static let Lat = "lat"
        static let Long = "long"
    }
    
    private var battery : Int = 0
    private var id : Int = 0
    private var lat : Double = 0.0
    private var long : Double = 0.9
    
    override init() {
        
    }
    
    init(id : Int, battery : Int, lat : Double, long : Double)
    {
        self.id = id
        self.battery = battery
        self.lat = lat
        self.long = long
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        if let idObj = aDecoder.decodeObject(forKey: Keys.Id) as? Int {
            self.id = idObj
        }
        if let batteryObj = aDecoder.decodeObject(forKey: Keys.Battery) as? Int {
            self.battery = batteryObj
        }
        if let latObj = aDecoder.decodeObject(forKey: Keys.Lat) as? Double {
            self.lat = latObj
        }
        if let longObj = aDecoder.decodeObject(forKey: Keys.Long) as? Double {
            self.long = longObj
        }
        
    }
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(id, forKey: Keys.Id)
        aCoder.encode(battery,forKey:Keys.Battery)
        aCoder.encode(lat,forKey:Keys.Lat)
        aCoder.encode(long,forKey:Keys.Long)
        
    }
    
    var Id : Int {
        get {
            return self.id
        } set {
            self.id = newValue
        }
    }
    
    var Battery : Int {
        get {
            return self.battery
        } set {
            self.battery = newValue
        }
    }
    
    var Lat : Double {
        get {
            return self.lat
        } set {
            self.lat = newValue
        }
    }
    
    var Long : Double {
        get {
            return self.long
        } set {
            self.long = newValue
        }
    }
    
    
}
