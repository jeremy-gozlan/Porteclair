//
//  SnapshotView.swift
//  Porteclair
//
//  Created by Jeremy on 13/03/2018.
//  Copyright © 2018 Jeremy. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import MapKit

protocol Modal {
    func show(animated:Bool)
    func dismiss(animated:Bool)
    var backgroundView:UIView {get}
    var dialogView:UIView {get set}
}

extension Modal where Self:UIView{
    func show(animated:Bool){
        self.backgroundView.alpha = 0
        self.dialogView.center = CGPoint(x: self.center.x, y: self.frame.height + self.dialogView.frame.height/2)
        UIApplication.shared.delegate?.window??.rootViewController?.view.addSubview(self)
        if animated {
            UIView.animate(withDuration: 0.33, animations: {
                self.backgroundView.alpha = 0.66
            })
            UIView.animate(withDuration: 0.33, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 10, options: UIViewAnimationOptions(rawValue: 0), animations: {
                self.dialogView.center  = self.center
            }, completion: { (completed) in
                
            })
        }else{
            self.backgroundView.alpha = 0.66
            self.dialogView.center  = self.center
        }
    }
    
    func dismiss(animated:Bool){
        if animated {
            UIView.animate(withDuration: 0.33, animations: {
                self.backgroundView.alpha = 0
            }, completion: { (completed) in
                
            })
            UIView.animate(withDuration: 0.33, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 10, options: UIViewAnimationOptions(rawValue: 0), animations: {
                self.dialogView.center = CGPoint(x: self.center.x, y: self.frame.height + self.dialogView.frame.height/2)
            }, completion: { (completed) in
                self.removeFromSuperview()
            })
        }else{
            self.removeFromSuperview()
        }
        
    }
}

class SnapshotView : UIView,Modal,UINavigationBarDelegate, MKMapViewDelegate, CLLocationManagerDelegate {
 

    var backgroundView = UIView()
    var dialogView = UIView()
    var timeLabel = UILabel()
    
    var locationManager : CLLocationManager!
    var mapView : MKMapView!
    
    var seconds = 0
    var timer = Timer()
    var currentSimulationTime = Date()
    var originalSimulationTime = Date()
    var finalTime = Date()
    
    var currentSensorNbInMap = 0
    
    var receptionTime = Date()
    
    var currentIndex = 0
    var receptionList : [[String:Any]]!
    var receptionCount = 0;
    
    
    convenience init(timeGap : [Date], receptionsList : [[String:Any]] ) {
        self.init(frame: UIScreen.main.bounds)
        
        backgroundView.frame = frame
        backgroundView.backgroundColor = UIColor.black
        backgroundView.alpha = 0.8
        addSubview(backgroundView)
        let dialogViewWidth = frame.width-50
        let titleLabel = UILabel(frame: CGRect(x: 8, y: 8, width: dialogViewWidth-16, height: 30))
        titleLabel.text = "Activity"
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        dialogView.addSubview(titleLabel)
        
        let separatorLineView = UIView()
        separatorLineView.frame.origin = CGPoint(x: 0, y: titleLabel.frame.height + 8)
        separatorLineView.frame.size = CGSize(width: dialogViewWidth, height: 1)
        separatorLineView.backgroundColor = UIColor.groupTableViewBackground
       // dialogView.addSubview(separatorLineView)
        
        setupMapView()
       
        
        mapView.frame.origin = CGPoint(x: 8, y: separatorLineView.frame.height + separatorLineView.frame.origin.y + 8)
        mapView.frame.size = CGSize(width: dialogViewWidth - 16 , height: 500 - separatorLineView.frame.height  - 8)
        mapView.contentMode = .scaleAspectFit
        mapView.backgroundColor = .blue
        mapView.layer.cornerRadius = 4
        mapView.clipsToBounds = true
        dialogView.addSubview(mapView)
        
        let centerMapPosition = ( mapView.frame.origin.x + mapView.frame.width )/2
        timeLabel.frame.origin = CGPoint(x: centerMapPosition - 40 , y: separatorLineView.frame.height + separatorLineView.frame.origin.y + 8 + 20)
        timeLabel.frame.size = CGSize(width: 80, height: 40)
        timeLabel.textColor = firstColor
        timeLabel.backgroundColor = UIColor(red: 255/255, green: 252/255, blue: 237/255, alpha: 1)
        timeLabel.layer.cornerRadius = CGFloat(4)
        timeLabel.layer.borderWidth = CGFloat(1)
        timeLabel.layer.borderColor = firstColor.cgColor
        timeLabel.text = ""
        
        dialogView.addSubview(timeLabel)
        var currentY : CGFloat =  separatorLineView.frame.height + separatorLineView.frame.origin.y + 8 + 500
        
        dialogView.frame.origin = CGPoint(x: 25, y: frame.height)
        dialogView.frame.size = CGSize(width: frame.width-50, height: currentY)
        
        dialogView.layer.cornerRadius = 6
        dialogView.clipsToBounds = true
        addSubview(dialogView)
        dialogView.backgroundColor = .clear
        dialogView.setGradient(colors: [firstColor,secondColor])
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTappedOnBackgroundView)))
        
        currentSimulationTime = timeGap[0]
        originalSimulationTime = timeGap[0]
        finalTime = timeGap[1]
       
        receptionList = receptionsList
        receptionCount = receptionsList.count
        startAnimation(receptionsList: receptionsList)
        
    }
    
    func computeMidPoint(locations : [CLLocationCoordinate2D]) -> CLLocationCoordinate2D
    {
        var maxLat : Double = -200
        var maxLong : Double = -200
        var minLat : Double = 200
        var minLong : Double = 200
        
        for location in locations
        {
            if (location.latitude < minLat) {
                minLat = location.latitude;
            }
            
            if (location.longitude < minLong) {
                minLong = location.longitude;
            }
            
            if (location.latitude > maxLat) {
                maxLat = location.latitude;
            }
            
            if (location.longitude > maxLong) {
                maxLong = location.longitude;
            }
        }
        
        return CLLocationCoordinate2DMake((maxLat + minLat) * 0.5, (maxLong + minLong) * 0.5)
    }
    
    @objc func tryToSimulateForNextDate()
    {
        
        if currentIndex <= receptionList.count-1
        {
        let reception = receptionList[currentIndex]
        receptionTime = reception["Date"] as! Date
        
        if (currentSimulationTime>=receptionTime)
        {

        var sensorList = reception["SensorList"] as! [Sensor]
        var lightningList = reception["LightningList"] as! [Lightning]
        var assetLocation = reception["Asset"] as! CLLocationCoordinate2D

        if sensorList.count != self.currentSensorNbInMap
        {
            for annot in self.mapView.annotations
            {
                if let annotation = annot as? SensorCustomAnnotation
                {
                    self.mapView.remove(annotation.circle!)
                    self.mapView.removeAnnotation(annotation)
                }
            }
            var coordinateList = [CLLocationCoordinate2D]()
            for sens in sensorList
            {
                sens.sensorAnnotation = SensorCustomAnnotation(sensorId: sens.id, batteryLevel: sens.batteryLevel, coordinate: CLLocationCoordinate2DMake(sens.sensorLatitude,sens.sensorLongitude))
                sens.sensorAnnotation?.circle = MKCircle(center: CLLocationCoordinate2DMake(sens.sensorLatitude, sens.sensorLongitude), radius: CLLocationDistance(50000))
                sens.sensorAnnotation?.title = "sensor:\(sens.id)"
                sens.sensorAnnotation?.circle?.title = "sensor"
                self.mapView.add((sens.sensorAnnotation?.circle)!)
                self.mapView.addAnnotation(sens.sensorAnnotation!)
                coordinateList.append(CLLocationCoordinate2DMake(sens.sensorLatitude, sens.sensorLongitude))
                
            }
           
            var point = self.computeMidPoint(locations: coordinateList)
            let regionRadius: CLLocationDistance = 100000
            
            if point != nil {
                let region = MKCoordinateRegionMakeWithDistance(point,
                                                                regionRadius * 2.0, regionRadius * 2.0)
                self.mapView.setRegion(region, animated: true)
            }
            
            self.currentSensorNbInMap = sensorList.count
        }
        else {
            
            for sens in sensorList
            {
                for annot in self.mapView.annotations
                {
                    if let annot = annot as? SensorCustomAnnotation
                    {
                        if annot.sensorId == sens.id {
                            
                            annot.batteryLevel = sens.batteryLevel
                            let receivedCoordinate = CLLocationCoordinate2DMake(sens.sensorLatitude,sens.sensorLongitude)
                            if receivedCoordinate.latitude != annot.coordinate.latitude || receivedCoordinate.longitude != annot.coordinate.longitude
                            {
                                annot.coordinate = receivedCoordinate
                                self.mapView.remove(annot.circle!)
                                annot.circle = MKCircle(center: receivedCoordinate, radius: CLLocationDistance(50000))
                                annot.circle?.title = "sensor"
                                self.mapView.add(annot.circle!)
                            }
                            
                        }
                        
                    }
                }
            }
        }
        
        for light in lightningList
        {
            let lightningPin = lightningCustomAnnotation(date:receptionTime, coordinate: CLLocationCoordinate2DMake(light.latitude,light.longitude))
            self.mapView.addAnnotation(lightningPin)
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute:
                {
                    self.mapView.removeAnnotation(lightningPin)
            })
        }
        
            var assetInMap = false
            for annot in mapView.annotations
            {
                if let annotation = annot as? AssetCustomAnnotation
                {
                    var newLocation = assetLocation
                    
                    if ((annotation.coordinate.longitude != newLocation.longitude) || (annotation.coordinate.latitude != newLocation.latitude))
                    {
                        annotation.coordinate = newLocation
                    }
                    assetInMap = true
                }
                
            }
            if assetInMap == false
            {
                
                let asset = Asset(lat:assetLocation.latitude,long:assetLocation.longitude)
                asset.assetAnnotation = AssetCustomAnnotation( coordinate:assetLocation)
                mapView.addAnnotation(asset.assetAnnotation!)
                
            }
        
            self.currentIndex+=1
     }
        }
    }
    
    func startAnimation(receptionsList : [[String:Any]])
    {
       
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(tryToSimulateForNextDate), userInfo: nil, repeats: true)
        
    }
    
    func getStringFrom(seconds: Int) -> String {
        
        return seconds < 10 ? "0\(seconds)" : "\(seconds)"
    }
    
    func timeString(time: TimeInterval) -> String
    {
        let hoursNumerical = Int(time) / 3600
        let minutesNumerical  = Int(time) / 60 % 60
        let secondsNumerical = Int (time) % 60
        
        let gregorian = Calendar(identifier: .gregorian)
        var components1 = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: originalSimulationTime)
        var copyComponents  = components1
        
        copyComponents.hour =  components1.hour! + hoursNumerical
        copyComponents.minute  =  components1.minute! + minutesNumerical
        copyComponents.second  = components1.second! + secondsNumerical
        
        let hoursString = getStringFrom(seconds:hoursNumerical+components1.hour!)
        let minutesString = getStringFrom(seconds:minutesNumerical)
        let secondsString = getStringFrom(seconds: secondsNumerical)
        
        currentSimulationTime = gregorian.date(from: copyComponents)!
        if currentSimulationTime <= finalTime
        {
            return " \(hoursString):\(minutesString):\(secondsString)"
        }
        return ""
    }
    
    @objc func updateTimer()
    {
        seconds += 500
        timeLabel.text = timeString(time: TimeInterval(seconds))
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    @objc func didTappedOnBackgroundView(){
        dismiss(animated: true)
    }
    
    func setupMapView()
    {
        mapView = MKMapView()
        mapView.mapType = MKMapType.standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.showsUserLocation = true
        mapView.delegate = self
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
        
    }
    

    
    func mapView(_ mapView: MKMapView!, rendererFor overlay: MKOverlay!) -> MKOverlayRenderer! {
        if overlay is MKCircle {
            var overlay : MKCircle = overlay as! MKCircle
            let circle = MKCircleRenderer(overlay: overlay)
            if  overlay.title?.range(of: "sensor") != nil {
                
                //circle.strokeColor = UIColor.red
                circle.fillColor = UIColor(red: 125, green: 0, blue: 255, alpha: 0.1)
                circle.lineWidth = 1
            }
            
            return circle
        } else {
            return nil
        }
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        
        let sensorTag = "sensor"
        let lightningTag = "lightning"
        let assetTag = "asset"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier:sensorTag)
        
        if annotation is lightningCustomAnnotation{
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: lightningTag)
        }
        if annotation is AssetCustomAnnotation{
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: assetTag)
        }
        
        if annotationView == nil
        {
            
            if annotation is SensorCustomAnnotation
            {
                annotationView = SensorAnnotationCustomView(annotation: annotation, reuseIdentifier: sensorTag)
                
                let pinImage = UIImage(named: "antenna7")
                let size = CGSize(width: 30, height: 30)
                UIGraphicsBeginImageContext(size)
                pinImage!.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                annotationView?.image = resizedImage
                
            }
            else if annotation is lightningCustomAnnotation
            {
                annotationView = lightningAnnotationCustomView(annotation: annotation, reuseIdentifier: lightningTag)
                annotationView?.frame.size = CGSize(width: 50, height: 50)
                
                let pulseEffect = LFTPulseAnimation(repeatCount: Float.infinity, radius: 30, position: (annotationView?.center)!)
                pulseEffect.opacity = 1
                annotationView?.layer.insertSublayer(pulseEffect, below: annotationView?.layer)
                
                let pinImage = UIImage(named: "lightning6")
                let size = CGSize(width:40, height: 40)
                UIGraphicsBeginImageContext(size)
                pinImage!.draw(in: CGRect(x: 13, y: 10, width: size.width/2, height: size.height/2))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                annotationView?.image = resizedImage
            }
            else if annotation is AssetCustomAnnotation
            {
                annotationView = AssetAnnotationCustomView(annotation: annotation, reuseIdentifier: assetTag)
                annotationView?.frame.size = CGSize(width: 50, height: 50)
                
                
                
                let pinImage = UIImage(named: "pinRed")
                let size = CGSize(width: 30, height: 30)
                UIGraphicsBeginImageContext(size)
                pinImage!.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                annotationView?.image = resizedImage
            }
            
        }
        else
        {
            annotationView!.annotation = annotation
            if (annotationView?.isSelected)!
            {
                annotationView?.removeFromSuperview()
            }
            
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let pin = view.annotation
        mapView.deselectAnnotation(pin, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       // let userLocation:CLLocation = locations[0] as CLLocation
        
        // Call stopUpdatingLocation() to stop listening for location updates,
        // other wise this function will be called every time when user location changes.
        //manager.stopUpdatingLocation()
        
        /*let regionRadius: CLLocationDistance = 10000
        let latitude : CLLocationDegrees = 51.3758  // BATH
        let longitude : CLLocationDegrees = -2.3999  // BATH
        let center = CLLocationCoordinate2D(latitude: latitude, longitude:longitude)
        let region = MKCoordinateRegionMakeWithDistance(center,
                                                        regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(region, animated: true)
        */
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
    }
    
    
    
}
