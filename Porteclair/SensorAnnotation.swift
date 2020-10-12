//
//  SensorAnnotation.swift
//  Porteclair
//
//  Created by Jeremy on 08/03/2018.
//  Copyright © 2018 Jeremy. All rights reserved.
//

import Foundation
import MapKit
import SwiftyGif

class Sensor {
    
    var id : Int = 0
    var batteryLevel : Int = 100
    var sensorAnnotation : SensorCustomAnnotation?
    var sensorLatitude : CLLocationDegrees = 0.0
    var sensorLongitude : CLLocationDegrees = 0.0
    
    init(id: Int, lat: CLLocationDegrees, long: CLLocationDegrees, batteryLevel : Int) {
        self.id = id
        self.sensorLatitude = lat
        self.sensorLongitude = long
        self.batteryLevel = batteryLevel
        
    }
    
}

class Lightning {
    
    var date: Date = Date()
    var latitude : CLLocationDegrees = 0.0
    var longitude : CLLocationDegrees = 0.0
    
    init(date: Date,lat: CLLocationDegrees, long: CLLocationDegrees)
    {
        self.date = date
        self.latitude = lat
        self.longitude = long
    }
    
}

class Asset {
    
    var assetAnnotation : AssetCustomAnnotation?
    var AssetLatitude : CLLocationDegrees = 0.0
    var AssetLongitude : CLLocationDegrees = 0.0
    
    init(lat: CLLocationDegrees, long: CLLocationDegrees)
    {
       
        self.AssetLatitude = lat
        self.AssetLongitude = long
    }
}

class SensorCustomAnnotation : MKPointAnnotation {
    
    var batteryLevel: Int?
    var sensorId: Int?
    var circle : MKCircle?
  
    init( sensorId : Int, batteryLevel:Int, coordinate: CLLocationCoordinate2D ) {
        super.init()
        self.batteryLevel = batteryLevel
        self.sensorId = sensorId
        self.coordinate = coordinate
    
    }
}

class lightningCustomAnnotation : MKPointAnnotation {
    
    var dateOfOccuring : Date?

    init(date : Date, coordinate: CLLocationCoordinate2D ) {
        super.init()
        self.dateOfOccuring = date
        self.coordinate = coordinate
        
    }
}

class AssetCustomAnnotation : MKPointAnnotation {
    
    var circle : MKCircle?
    
    init(coordinate: CLLocationCoordinate2D ) {
        super.init()
        self.coordinate = coordinate
        
    }
}


class SensorAnnotationCustomView : MKAnnotationView {
    
    weak var customSensorView : UIView?
    var customAnnotation : SensorCustomAnnotation?
    
    var sensorIdLabel : UILabel?
    var sensorPositionLabel : UILabel?
    var sensorBatteryLabel : UILabel?
    var sensorStatusLabel: UILabel?
    var batteryImageView : UIImageView?
    var sensorLogoImageView : UIImageView?
    
    
   
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.canShowCallout = false // 1
        self.customAnnotation = annotation as? SensorCustomAnnotation
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.canShowCallout = false // 1
    }
    
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
       
       if selected {
        
        if customSensorView != nil {
            if animated { // fade out animation, then remove it.
                UIView.animate(withDuration: 0.1, animations: {
                    self.customSensorView!.alpha = 0.0
                }, completion: { (success) in
                    self.customSensorView?.removeFromSuperview()
                })
            } else {
                self.customSensorView!.removeFromSuperview() } // just remove it.
        }
            let newCustomCalloutView = UIView(frame: CGRect(x: 0, y: 0, width: 160, height: 100))
                newCustomCalloutView.layer.cornerRadius = CGFloat(5)
                newCustomCalloutView.layer.borderWidth = CGFloat(1)
                newCustomCalloutView.layer.borderColor = secondColor.cgColor
                newCustomCalloutView.backgroundColor = .white
        
              var containerView = UIView(frame:CGRect(x: 60, y: 0, width: 100, height: 100))
                containerView.layer.cornerRadius = CGFloat(5)
              // containerView.layer.borderWidth = CGFloat(1)
                containerView.backgroundColor = secondColor
                //containerView.setGradient(colors: [firstColor,secondColor])
        
                // fix location from top-left to its right place.
                newCustomCalloutView.frame.origin.x -= newCustomCalloutView.frame.width / 2.0 - (self.frame.width / 2.0)
                newCustomCalloutView.frame.origin.y -= newCustomCalloutView.frame.height
                sensorIdLabel = UILabel()
                sensorIdLabel?.textColor = .white
                sensorIdLabel?.backgroundColor = UIColor.clear
                sensorIdLabel?.frame.origin = CGPoint(x: 20, y: 10)
                sensorIdLabel?.frame.size = CGSize(width: 90, height: 20)
                sensorIdLabel?.text = "Sensor \(customAnnotation!.sensorId!)"
                containerView.addSubview(sensorIdLabel!)
        
        
        
                let gif = UIImage(gifName: "antennaGif.gif")
                sensorLogoImageView = UIImageView(gifImage: gif, manager: SwiftyGifManager.defaultManager, loopCount: -1)
                sensorLogoImageView?.frame.origin = CGPoint(x: 10, y: 10)
                sensorLogoImageView?.frame.size = CGSize(width: 40, height: 40)
        
                newCustomCalloutView.addSubview(sensorLogoImageView!)
        
                sensorPositionLabel = UILabel()
                sensorPositionLabel?.backgroundColor = UIColor.clear
                sensorPositionLabel?.textColor = .white
                sensorPositionLabel?.font =  sensorPositionLabel?.font.withSize(13)
                sensorPositionLabel?.frame.origin = CGPoint(x: 0, y: 40)
                sensorPositionLabel?.frame.size = CGSize(width: 100, height: 20)
                sensorPositionLabel?.text = "[\(customAnnotation!.coordinate.latitude.rounded(toPlaces: 2)),\(customAnnotation!.coordinate.longitude.rounded(toPlaces: 2))]"
                sensorPositionLabel?.textAlignment = .center
                containerView.addSubview(sensorPositionLabel!)
                // set custom callout view
        
                let gif1 = UIImage(gifName: "batteryGif1.gif")
                batteryImageView = UIImageView(gifImage: gif1, manager: SwiftyGifManager.defaultManager, loopCount: -1)
                batteryImageView?.frame.origin = CGPoint(x: 15, y: 65)
                batteryImageView?.frame.size = CGSize(width: 30, height: 25)
                
                newCustomCalloutView.addSubview(batteryImageView!)
        
                sensorBatteryLabel = UILabel()
                sensorBatteryLabel?.textColor = .white
                sensorBatteryLabel?.backgroundColor = UIColor.clear
                sensorBatteryLabel?.font =  sensorPositionLabel?.font.withSize(15) 
                sensorBatteryLabel?.frame.origin = CGPoint(x:0, y: 70)
                sensorBatteryLabel?.frame.size = CGSize(width: 50, height: 20)
                sensorBatteryLabel?.text = "\(customAnnotation!.batteryLevel!)%"
                sensorBatteryLabel?.textAlignment = .center
                containerView.addSubview(sensorBatteryLabel!)
        
                sensorStatusLabel = UILabel()
                sensorStatusLabel?.textColor = .white
                sensorStatusLabel?.backgroundColor = UIColor.clear
                sensorStatusLabel?.font =  sensorPositionLabel?.font.withSize(15)
                sensorStatusLabel?.frame.origin = CGPoint(x: 50, y: 70)
                sensorStatusLabel?.frame.size = CGSize(width: 50, height: 20)
                sensorStatusLabel?.text = "On"
                sensorStatusLabel?.textAlignment = .center
                containerView.addSubview(sensorStatusLabel!)
        
                newCustomCalloutView.addSubview(containerView)
                self.addSubview(newCustomCalloutView)
                self.customSensorView = newCustomCalloutView
                
                // animate presentation
                if animated {
                    self.customSensorView!.alpha = 0.0
                    UIView.animate(withDuration: 0.1, animations: {
                        self.customSensorView!.alpha = 1.0
                    })
                }
            
        } else { // 3
            if customSensorView != nil {
                if animated { // fade out animation, then remove it.
                    UIView.animate(withDuration: 0.1, animations: {
                        self.customSensorView!.alpha = 0.0
                    }, completion: { (success) in
                        self.customSensorView?.removeFromSuperview()
                    })
                } else { self.customSensorView!.removeFromSuperview() } // just remove it.
            }
        }
    }
    
   
        
    
    override func prepareForReuse() { // 5
    
        super.prepareForReuse()
        self.customSensorView?.removeFromSuperview()
    }
}


class lightningAnnotationCustomView : MKAnnotationView {
    
    weak var customLightningView : UIView?
    var customAnnotation : lightningCustomAnnotation?
    
    
    var lightningTimeLabel : UILabel?
    var  lightningPositionLabel : UILabel?
    var lightningImageView : UIImageView?
    
    
    
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.canShowCallout = false // 1
        self.customAnnotation = annotation as? lightningCustomAnnotation
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.canShowCallout = false // 1
    }
    
    func getStringFrom(seconds: Int) -> String {
        
        return seconds < 10 ? "0\(seconds)" : "\(seconds)"
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            
            if customLightningView != nil {
                if animated { // fade out animation, then remove it.
                    UIView.animate(withDuration: 0.1, animations: {
                        self.customLightningView!.alpha = 0.0
                    }, completion: { (success) in
                        self.customLightningView?.removeFromSuperview()
                    })
                } else {
                    self.customLightningView!.removeFromSuperview() } // just remove it.
            }
            let newCustomCalloutView = UIView(frame: CGRect(x: 0, y: 0, width: 160, height: 70))
            newCustomCalloutView.layer.cornerRadius = CGFloat(5)
            newCustomCalloutView.layer.borderWidth = CGFloat(1)
            newCustomCalloutView.layer.borderColor = secondColor.cgColor
            newCustomCalloutView.backgroundColor = .white
            
            let containerView = UIView(frame: CGRect(x: 40, y: 0, width: 120, height: 70))
            containerView.layer.cornerRadius = CGFloat(5)
            
            let gif = UIImage(gifName: "lightningGif4.gif")
            lightningImageView = UIImageView(gifImage: gif, manager: SwiftyGifManager.defaultManager, loopCount: -1)
            lightningImageView?.frame.origin = CGPoint(x: 5, y: 10)
            lightningImageView?.frame.size = CGSize(width: 30, height: 50)
           
            newCustomCalloutView.addSubview(lightningImageView!)
            // fix location from top-left to its right place.
            newCustomCalloutView.frame.origin.x -= newCustomCalloutView.frame.width / 2.0 - (self.frame.width / 2.0)
            newCustomCalloutView.frame.origin.y -= newCustomCalloutView.frame.height
            
            
            lightningTimeLabel = UILabel()
            lightningTimeLabel?.textColor = UIColor.white
            lightningTimeLabel?.backgroundColor = UIColor.clear
            lightningTimeLabel?.frame.origin = CGPoint(x: 0, y: 10)
            lightningTimeLabel?.frame.size = CGSize(width: 100, height: 20)
            lightningTimeLabel?.textAlignment = .center
            
            let gregorian = Calendar(identifier: .gregorian)
            var components1 = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: customAnnotation!.dateOfOccuring!)
            var hour = getStringFrom(seconds: components1.hour!)
            var minute = getStringFrom(seconds: components1.minute!)
            var second = getStringFrom(seconds: components1.second!)
            lightningTimeLabel?.text = "  \(hour):\(minute):\(second)"
            containerView.addSubview(lightningTimeLabel!)
            
            
            lightningPositionLabel = UILabel()
           
            lightningPositionLabel?.textColor = .white
            lightningPositionLabel?.font =  lightningPositionLabel?.font.withSize(13)
            lightningPositionLabel?.backgroundColor = UIColor.clear
            lightningPositionLabel?.frame.origin = CGPoint(x: 0, y: 40)
            lightningPositionLabel?.frame.size = CGSize(width: 100, height: 20)
            lightningPositionLabel?.text = "     [\(customAnnotation!.coordinate.latitude.rounded(toPlaces: 2)),\(customAnnotation!.coordinate.longitude.rounded(toPlaces: 2))]"
            lightningPositionLabel?.textAlignment = .center
            containerView.addSubview(lightningPositionLabel!)
            containerView.backgroundColor = secondColor
            
            //containerView.setGradient(colors: [firstColor,secondColor])
            // set custom callout view
            newCustomCalloutView.addSubview(containerView)
            self.addSubview(newCustomCalloutView)
            self.customLightningView = newCustomCalloutView
            
            // animate presentation
            if animated {
                self.customLightningView!.alpha = 0.0
                UIView.animate(withDuration: 0.1, animations: {
                    self.customLightningView!.alpha = 1.0
                })
            }
            
        } else { // 3
            if customLightningView != nil {
                if animated { // fade out animation, then remove it.
                    UIView.animate(withDuration: 0.1, animations: {
                        self.customLightningView!.alpha = 0.0
                    }, completion: { (success) in
                        self.customLightningView?.removeFromSuperview()
                    })
                } else { self.customLightningView!.removeFromSuperview() } // just remove it.
            }
        }
    }
    
    
    
    
    override func prepareForReuse() { // 5
        
        super.prepareForReuse()
        self.customLightningView?.removeFromSuperview()
    }
}

class AssetAnnotationCustomView : MKAnnotationView {
    
    weak var customAssetView : UIView?
    var customAnnotation : AssetCustomAnnotation?

    var  assetPositionLabel : UILabel?
    var assetImageView : UIImageView?
    
    
    
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.canShowCallout = false // 1
        self.customAnnotation = annotation as? AssetCustomAnnotation
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.canShowCallout = false // 1
    }
    
  
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            
            if customAssetView != nil {
                if animated { // fade out animation, then remove it.
                    UIView.animate(withDuration: 0.1, animations: {
                        self.customAssetView!.alpha = 0.0
                    }, completion: { (success) in
                        self.customAssetView?.removeFromSuperview()
                    })
                } else {
                    self.customAssetView!.removeFromSuperview() } // just remove it.
            }
            let newCustomCalloutView = UIView(frame: CGRect(x: 0, y: 0, width: 150, height: 80))
            newCustomCalloutView.layer.cornerRadius = CGFloat(5)
            newCustomCalloutView.layer.borderWidth = CGFloat(1)
            newCustomCalloutView.layer.borderColor = secondColor.cgColor
            newCustomCalloutView.backgroundColor = .white
            
            let containerView = UIView(frame: CGRect(x: 50, y: 0, width: 100, height: 80))
            containerView.layer.cornerRadius = CGFloat(5)
            
            assetImageView = UIImageView()
            assetImageView?.frame.origin = CGPoint(x: 5, y: 20)
            assetImageView?.frame.size = CGSize(width: 40, height: 40)
            assetImageView?.image = UIImage(named:"pinRed")


            newCustomCalloutView.addSubview(assetImageView!)
            // fix location from top-left to its right place.
            newCustomCalloutView.frame.origin.x -= newCustomCalloutView.frame.width / 2.0 - (self.frame.width / 2.0)
            newCustomCalloutView.frame.origin.y -= newCustomCalloutView.frame.height
            
            var assetLabel = UILabel()
            assetLabel.textColor = UIColor.white
            assetLabel.backgroundColor = UIColor.clear
            assetLabel.frame.origin = CGPoint(x: 0, y: 10)
            assetLabel.frame.size = CGSize(width: 100, height: 30)
            assetLabel.textAlignment = .center
            
            assetLabel.text = "Asset"
            containerView.addSubview(assetLabel)
            
            
            assetPositionLabel = UILabel()
            assetPositionLabel?.textColor = UIColor.white
            assetPositionLabel?.backgroundColor = UIColor.clear
            assetPositionLabel?.frame.origin = CGPoint(x: 0, y: 40)
            assetPositionLabel?.frame.size = CGSize(width: 100, height: 30)
            assetPositionLabel?.font =  assetPositionLabel?.font.withSize(13)
            assetPositionLabel?.text = "[\(customAnnotation!.coordinate.latitude.rounded(toPlaces: 2)),\(customAnnotation!.coordinate.longitude.rounded(toPlaces: 2))]"
            assetPositionLabel?.textAlignment = .center
            containerView.addSubview(assetPositionLabel!)
            
            
            containerView.backgroundColor = secondColor
            
            newCustomCalloutView.addSubview(containerView)
            self.addSubview(newCustomCalloutView)
            self.customAssetView = newCustomCalloutView
            
            // animate presentation
            if animated {
                self.customAssetView!.alpha = 0.0
                UIView.animate(withDuration: 0.1, animations: {
                    self.customAssetView!.alpha = 1.0
                })
            }
            
        } else { // 3
            if customAssetView != nil {
                if animated { // fade out animation, then remove it.
                    UIView.animate(withDuration: 0.1, animations: {
                        self.customAssetView!.alpha = 0.0
                    }, completion: { (success) in
                        self.customAssetView?.removeFromSuperview()
                    })
                } else { self.customAssetView!.removeFromSuperview() } // just remove it.
            }
        }
    }
    
    
    
    
    override func prepareForReuse() { // 5
        
        super.prepareForReuse()
        self.customAssetView?.removeFromSuperview()
    }
}


