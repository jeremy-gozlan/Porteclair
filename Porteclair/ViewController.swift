//
//  ViewController.swift
//  Porteclair
//
//  Created by Jeremy on 06/03/2018.
//  Copyright © 2018 Jeremy. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import ImageIO
import SwiftyGif
import Firebase
import CoreData
import AudioToolbox
import UserNotifications

//sun, wind, humidity , antenna3, lightning6


var firstColor = UIColor(red:255/255, green: 67/255, blue: 67/255, alpha:1)
var secondColor = UIColor(red: 255/255, green: 93/255, blue: 93/255, alpha: 1)

extension CAGradientLayer {
    
    convenience init(frame: CGRect, colors: [UIColor]) {
        self.init()
        self.frame = frame
        self.colors = []
        for color in colors {
            self.colors?.append(color.cgColor)
        }
        startPoint = CGPoint(x: 0, y: 0)
        endPoint = CGPoint(x: 0, y: 1)
    }
    
    func creatGradientImage() -> UIImage? {
        
        var image: UIImage? = nil
        UIGraphicsBeginImageContext(bounds.size)
        if let context = UIGraphicsGetCurrentContext() {
            render(in: context)
            image = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        return image
    }
    
}

extension UIView {
    
    func setGradient(colors: [UIColor]) {
        
        var updatedFrame = self.bounds
        let gradientLayer = CAGradientLayer(frame: updatedFrame, colors: colors)
        self.layer.insertSublayer(gradientLayer, at: 0)
        
    }
    
}

extension UINavigationBar {
    
    func setGradientBackground(colors: [UIColor]) {
        
        var updatedFrame = bounds
        updatedFrame.size.height += self.frame.origin.y
        let gradientLayer = CAGradientLayer(frame: updatedFrame, colors: colors)
        
        setBackgroundImage(gradientLayer.creatGradientImage(), for: UIBarMetrics.default)
        shadowImage = UIImage()
    }
}


class ViewController: UIViewController , MKMapViewDelegate, CLLocationManagerDelegate  {
    
    var locationManager : CLLocationManager!
    var contextNS : UNMutableNotificationContent!
    var temperatureLabel : UILabel?
    var windLabel : UILabel?
    var humidityLabel : UILabel?
    
    var temperature = 0.0
    var wind = 0.0
    var humidity = 0.0
    
    var handle : AuthStateDidChangeListenerHandle?
    var storageRef : StorageReference!
    var refDict : CollectionReference!
    
    var appDelegate : AppDelegate!
    var context : NSManagedObjectContext!
    
    var lastReception : [String:Any]!

    var currentSensorNbInMap = 0;
    var sensorsListForDisplay : [Sensor] = []
    var lightningsListForDisplay : [Lightning] = []
    var warningListForDisplay : [String] = []
    
    var currentCenter2D : CLLocationCoordinate2D!
    var currentCenterLocation : CLLocation!
    
    var riskPulseEffect : LFTPulseAnimation!
    
    @IBOutlet weak var generalWeatherView: UIView!
    
    @IBOutlet weak var riskView: UIView!
    
    @IBOutlet weak var mapView:MKMapView!
    
    @IBOutlet weak var topView: UIView!
    
    @IBOutlet weak var connectionView: UIView!
    
    var wasDisconnected = false
    
    @IBOutlet weak var connectionLabel: UILabel!
    
    var testCore = [SensorCore]()
   
  
    @IBOutlet weak var userLocationButton: UIButton!
    
    var userDesiredLocation : CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
         getWeather()
        //self.navigationController?.navigationBar.isTranslucent = false
        //elf.navigationController?.navigationBar.barTintColor = .blue
        
       
        let textAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        //var firstCC = UIColor(
        
        
        navigationController?.navigationBar.setGradientBackground(colors: [firstColor,secondColor])
        //navigationController?.navigationBar.barTintColor = UIColor(red: 255/255, green: 93/255, blue: 93/255, alpha: 1)
        
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        context = appDelegate.persistentContainer.viewContext
        //deleteAllData(entity: "ServerReception")
        
        setupGeneralView()
        setupRiskLevelView()
        
        var helloWorldTimer = Timer.scheduledTimer(timeInterval: 600.0, target: self, selector: #selector(getWeather), userInfo: nil, repeats: true)
        
      
        fetchLastData()
        connectionView.layer.cornerRadius  = CGFloat(4)
        connectionLabel.backgroundColor = .clear
        connectionLabel.textColor = .white
        connectionView.isHidden = true
        
        let timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(checkConnection), userInfo: nil, repeats: true)
        

    }
    
    
    
    @IBAction func changeUserLocation(_ sender: Any)
    {
       
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        
        let alertController = UIAlertController(title: "Porteclair", message: "Change asset location", preferredStyle: .alert)
        alertController.addTextField(configurationHandler: {(_ textField: UITextField) -> Void in
            textField.placeholder = "Latitude" })
        alertController.addTextField(configurationHandler: {(_ textField: UITextField) -> Void in
                textField.placeholder = "Longitude"
        })
        let changeLocation = UIAlertAction(title: "Change", style: .default, handler: {(_ action: UIAlertAction) -> Void in
            
            
            if let lat = Double(alertController.textFields![0].text!),let long = Double(alertController.textFields![1].text!)
            {
                    print(lat,long)
                
                    let location = GeoPoint(latitude: lat, longitude: long)
                    let ref = Firestore.firestore().collection("AssetLocations").document("user1")
                    let dataLocation : [String : GeoPoint] = ["location": location]
                    self.userDesiredLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                    ref.setData(dataLocation)
                    blurEffectView.removeFromSuperview()
                
                    self.updateAssetAnnotation()
                
                
            }
            else
            {
                let errorController = UIAlertController(title: "Porteclair", message: "The location entered is erroneous", preferredStyle: UIAlertControllerStyle.alert)
                
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
                {
                    (result : UIAlertAction) -> Void in
                }
                errorController.addAction(okAction)
                self.present(errorController, animated: true)
                blurEffectView.removeFromSuperview()
                
            }

            
        })
        alertController.addAction(changeLocation)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(_ action: UIAlertAction) -> Void in
            blurEffectView.removeFromSuperview()
        })
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
        
        
    }
    
    
    @objc func checkConnection()
    {
        if !Reachability.isConnectedToNetwork(){
            wasDisconnected = true
            connectionLabel.text = "Disconnected !"
            connectionView.backgroundColor = secondColor
            connectionView.isHidden = false
        }
        else
        {
            if wasDisconnected {
                connectionLabel.text = "  Connected !"
                connectionView.backgroundColor = UIColor(red: 50/255, green: 205/255, blue: 50/255, alpha: 1)
                wasDisconnected = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute:
                    {
                        self.connectionView.isHidden = true
                })
                
            }
        }
    
    }
    
    
    func deleteAllData(entity: String)
    {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.returnsObjectsAsFaults = false
        do
        {
            let results = try context.fetch(fetchRequest)
            for managedObject in results
            {
                let managedObjectData:NSManagedObject = managedObject as! NSManagedObject
                context.delete(managedObjectData)
            }
        } catch let error as NSError {
            print("Detele all data in \(entity) error : \(error) \(error.userInfo)")
        }
    }
    
    func recoverLastCoreDataReceptions()->NSManagedObject
    {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ServerReception")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request) as! [NSManagedObject]
            
            if let lastReception = result[result.count-1] as? NSManagedObject
            {
                
                
                print(lastReception.value(forKey: "Date") as? Date)
                print(lastReception.value(forKey: "sensorList") as? [[Double]])
                print(lastReception.value(forKey:"lightningList") as? [[Double]])
                print(lastReception.value(forKey : "weatherInformation") as? [Double])
                return lastReception
            }
        } catch {
            
            print("Failed")
        }
        return NSManagedObject()
       
    }
   
    func appendLastReceptionToCoreData(date : Date, sensorlist : [Sensor], lightninglist : [Lightning])
    {
        
        let context = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "ServerReception", in: context)
        
        let  newReceptionObject = NSManagedObject(entity: entity!, insertInto: context)
        
        var sensorCDlist = [[Double]]()
        var lightningCDList = [[Double]]()
        var weatherInformation = [Double]()
        
        for sensor in sensorlist
        {
            sensorCDlist.append([Double(sensor.id),Double(sensor.batteryLevel),sensor.sensorLatitude, sensor.sensorLongitude])
        }
        for light in lightninglist
        {
            lightningCDList.append([light.latitude,light.longitude])
        }
    
       newReceptionObject.setValue(date, forKey: "Date")
       newReceptionObject.setValue(sensorCDlist, forKey:"sensorList")
       newReceptionObject.setValue(lightningCDList, forKey:"lightningList")
       
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute:
            {
                if self.temperature != 0.0 {
                    weatherInformation.append(self.temperature)
                }
                else {
                    weatherInformation.append(0.0)
                }
                
                if self.wind != 0.0 {
                    weatherInformation.append(self.wind)
                }
                else {
                    weatherInformation.append(0.0)
                }
                if self.humidity != 0 {
                    weatherInformation.append(self.humidity)
                }
                else {
                    weatherInformation.append(0.0)
                }
                newReceptionObject.setValue(weatherInformation, forKey: "weatherInformation")
                do {
                    
                    try context.save()
                } catch {
                    print("failed")
                }
                self.recoverLastCoreDataReceptions()
        })
        
       
        
    }
    
    func illustrateFetchFirestore()
    {
        self.refDict = Firestore.firestore().collection("LiveReception")
        // Get documents
        self.refDict.order(by: "Date", descending: true).getDocuments(){ querySnapshot, error in
            guard (querySnapshot?.documents) != nil else {
                print("Error fetching document: \(error!)")
                return
            }
            for doc in (querySnapshot?.documents)!
            {
                self.lastReception = doc.data()
                //Data for each document
                if let dateReceived = self.lastReception["Date"] as? Date
                {
                    let date = dateReceived // date of the document
                    print (date)
                }
            }
        }
        
        // Add a listener that listen and get the last 2 data received
        self.refDict.order(by: "Date", descending: true).limit(to:2).addSnapshotListener()
            { querySnapshot, error in
            guard (querySnapshot?.documents) != nil else {
                print("Error fetching document: \(error!)")
                return
            }
            for doc in (querySnapshot?.documents)!
            {
                // same
            }
            }
    }
    
    
    
    
    func fetchLastData()
    {
        self.refDict = Firestore.firestore().collection("LiveReception")
        
       // self.storageRef = Storage.storage().reference()
        
        
        self.refDict.order(by: "Date", descending: true).limit(to:1).addSnapshotListener { querySnapshot, error in
            guard let document = querySnapshot?.documents else {
                print("Error fetching document: \(error!)")
                return
            }
            for doc in (querySnapshot?.documents)!
            {
                self.lastReception = doc.data() as! [String:Any]
                
                var  date = Date()
                self.sensorsListForDisplay = []
                self.lightningsListForDisplay = []
                
                if let dateReceived = self.lastReception["Date"] as? Date
                {
                    date = dateReceived
                    
                   
                    
                    if let sensorList = self.lastReception["Sensor"] as? [[String:Any]]
                    {
                      for sen in sensorList
                       {
                        if let point = sen["location"] as? GeoPoint
                         {
                            if let id = sen["id"] as? Int
                            {
                                if let batteryLevel = sen["battery"] as? Int
                                {
                                    
                                   self.sensorsListForDisplay.append(Sensor(id:id, lat: point.latitude , long : point.longitude , batteryLevel: batteryLevel))
                                    
                                }
                            }
                         }
                      }
                    self.setupMapView()
                   }
                    
                    var coordinateList = [CLLocationCoordinate2D]()
                    for sensor in self.sensorsListForDisplay {
                        coordinateList.append(CLLocationCoordinate2DMake(sensor.sensorLatitude, sensor.sensorLongitude))
                    }
                    var point = self.computeMidPoint(locations: coordinateList)
                    let regionRadius: CLLocationDistance = 100000
                    
                    if point != nil {
                        let region = MKCoordinateRegionMakeWithDistance(point,
                                                                        regionRadius * 2.0, regionRadius * 2.0)
                        self.mapView.setRegion(region, animated: true)
                    }
                    
                    if let assetLocation = self.lastReception["Asset"] as? GeoPoint
                    {
                         self.userDesiredLocation = CLLocation(latitude: assetLocation.latitude,longitude: assetLocation.longitude)
                        
                    }
                    
                    if self.userDesiredLocation == nil
                    {
                        self.userDesiredLocation = CLLocation(latitude: point.latitude,longitude: point.longitude)
                        print ( self.userDesiredLocation)
                        
                    }
                   
                    var distances = [CLLocationDistance]()
                    if let lightningStrikeList = self.lastReception["Lightning"] as? [[String:Any]]
                    {
                        
                        for light in lightningStrikeList
                        {
                            if let location = light["location"] as? GeoPoint
                            {
                                if let time = light["time"] as? Date
                                {
                                    self.lightningsListForDisplay.append(Lightning(date: time, lat: location.latitude, long: location.longitude))
                                }
                                else {
                                    self.lightningsListForDisplay.append(Lightning(date: date, lat: location.latitude, long: location.longitude))
                                }
                                 distances.append(self.calculateDistancefromCenter(lightninglocation: CLLocationCoordinate2DMake(location.latitude, location.longitude)))
                            }
                            
                        }
                        
                        self.changeRiskColorAccording(distances : distances)
                        /// ------
                    }
                    
                    if let warningList = self.lastReception["Warning"] as? [String]
                    {
                        self.warningListForDisplay = warningList
                    }
                    
                   self.alertUserOfWarning(distances:distances,warnings:self.warningListForDisplay)
    
                   // self.appendLastReceptionToCoreData(date: date, sensorlist: self.sensorsListForDisplay, lightninglist: self.lightningsListForDisplay)
                    self.updateAnnotationsForLastReception(date: date, sensorlist: self.sensorsListForDisplay, lightninglist: self.lightningsListForDisplay)
                    self.updateAssetAnnotation()
                    
                    self.contextNS = UNMutableNotificationContent()
                    self.contextNS.title = "A notable event occured"
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60,
                                                                    repeats: true)
                    let request = UNNotificationRequest(identifier: "60_seconds", content: self.contextNS, trigger: trigger)
                    self.contextNS.body = "A notable event occured"
                    self.contextNS.sound = UNNotificationSound.default()
                    let center = UNUserNotificationCenter.current()
                    center.add(request, withCompletionHandler: nil)
                 
                    
                   
                    
               }
          }
        
       }
    }
    
    func fetch(_ completion: () -> Void) {
    completion()
    }
    
    func triggerNotificationInCaseOfLightning()
    {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(identifier: "test", content: self.contextNS, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if user == nil {
                // If token is invalid, redirect to Login View Controller)
                let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "loginVC") as! loginViewController

                self.present(viewController, animated: false, completion: nil)
            }
        }
        
    }
    
    
    @IBAction func disconnect(_ sender: Any) {
        
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    
    var risksLevelView : UIView?
    var blurEffectView : UIVisualEffectView!
    var chartView : UIView!

    @IBAction func riskButtonDown(_ sender: Any) {
    
       self.view.addSubview(blurEffectView)
       self.view.addSubview(risksLevelView!)
       self.view.addSubview(chartView)
        
    }
    
    
    @IBAction func riskButtonUp(_ sender: Any) {
       
    blurEffectView.removeFromSuperview()
       risksLevelView?.removeFromSuperview()
        chartView.removeFromSuperview()
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateAnnotationsForLastReception(date : Date, sensorlist : [Sensor], lightninglist : [Lightning])
    {
        if sensorlist.count != currentSensorNbInMap
        {
            for annot in mapView.annotations
            {
                if let annotation = annot as? SensorCustomAnnotation
                {
                    mapView.remove(annotation.circle!)
                    mapView.removeAnnotation(annotation)
                }
            }
            
            for sens in sensorlist
                {
                    sens.sensorAnnotation = SensorCustomAnnotation(sensorId: sens.id, batteryLevel: sens.batteryLevel, coordinate: CLLocationCoordinate2DMake(sens.sensorLatitude,sens.sensorLongitude))
                    sens.sensorAnnotation?.circle = MKCircle(center: CLLocationCoordinate2DMake(sens.sensorLatitude, sens.sensorLongitude), radius: CLLocationDistance(50000))
                    sens.sensorAnnotation?.title = "sensor:\(sens.id)"
                    sens.sensorAnnotation?.circle?.title = "sensor"
                    mapView.add((sens.sensorAnnotation?.circle)!)
                    mapView.addAnnotation(sens.sensorAnnotation!)
                    
                }
            currentSensorNbInMap = sensorlist.count
        }
        else
        {
            for sens in sensorlist
            {
                for annot in mapView.annotations
                {
                    if let annot = annot as? SensorCustomAnnotation
                    {
                        if annot.sensorId == sens.id {
                            
                            annot.batteryLevel = sens.batteryLevel
                            let receivedCoordinate = CLLocationCoordinate2DMake(sens.sensorLatitude,sens.sensorLongitude)
                            if receivedCoordinate.latitude != annot.coordinate.latitude || receivedCoordinate.longitude != annot.coordinate.longitude
                            {
                                annot.coordinate = receivedCoordinate
                                mapView.remove(annot.circle!)
                                annot.circle = MKCircle(center: receivedCoordinate, radius: CLLocationDistance(50000))
                                annot.circle?.title = "sensor"
                                mapView.add(annot.circle!)
                            }
                           
                          //
                        }
                       
                    }
                }
            }
        }
        
         
        for light in lightninglist
        {
            let lightningPin = lightningCustomAnnotation(date:light.date, coordinate: CLLocationCoordinate2DMake(light.latitude,light.longitude))
            mapView.addAnnotation(lightningPin)
            DispatchQueue.main.asyncAfter(deadline: .now() + 120.0, execute:
                {
                self.mapView.removeAnnotation(lightningPin)
            })
        }
        
        
        
    }
    
    var asset : Asset!
    
    func updateAssetAnnotation()
    {
        var assetInMap = false
        for annot in mapView.annotations
        {
            if let annotation = annot as? AssetCustomAnnotation
            {
                var newLocation = CLLocationCoordinate2DMake((self.userDesiredLocation?.coordinate.latitude)!, (self.userDesiredLocation?.coordinate.longitude)!)
                
                if ((annotation.coordinate.longitude != newLocation.longitude) || (annotation.coordinate.latitude != newLocation.latitude))
                 {
                    annotation.coordinate = newLocation
                 }
                assetInMap = true
            }
            
        }
        if assetInMap == false
        {
            
            asset = Asset(lat: (self.userDesiredLocation?.coordinate.latitude)!, long: (self.userDesiredLocation?.coordinate.longitude)!)
            asset.assetAnnotation = AssetCustomAnnotation( coordinate: CLLocationCoordinate2DMake((self.userDesiredLocation?.coordinate.latitude)!, (self.userDesiredLocation?.coordinate.longitude)!))
            mapView.addAnnotation(asset.assetAnnotation!)
            print(asset.assetAnnotation?.coordinate)
        }
    }
    
    
    func removeLightningAtLocationAndTag(time : String)
    {
        for ann in self.mapView.annotations
        {
            if ann.title??.range(of :"lightning :\(time)") != nil
            {
                self.mapView.removeAnnotation(ann)
            }
        }
    
    }
    
    func setupMapView()
    {
       
        mapView.mapType = MKMapType.mutedStandard
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
                circle.fillColor = UIColor(red:125 , green: 0, blue: 255, alpha: 0.1)
            circle.lineWidth = 1
            }
           else if  overlay.title?.range(of: "center") != nil {
                
                //circle.strokeColor = UIColor.red
                circle.fillColor = UIColor(red:0 , green: 0, blue: 255, alpha: 0.1)
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
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "lightning")
        }
        if annotation is AssetCustomAnnotation {
             annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "asset")
        }
        
        if annotationView == nil
        {
            
            if annotation is SensorCustomAnnotation
            {
              annotationView = SensorAnnotationCustomView(annotation: annotation, reuseIdentifier: sensorTag)
            
              let pinImage = UIImage(named: "antenna7")
              let size = CGSize(width: 40, height: 40)
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
                let size = CGSize(width: 50, height: 50)
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
                let size = CGSize(width: 40, height: 40)
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
    
     func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
     {
    
     
     // Call stopUpdatingLocation() to stop listening for location updates,
     // other wise this function will be called every time when user location changes.
     //manager.stopUpdatingLocation()
       /* let regionRadius: CLLocationDistance = 10000
        
        if currentCenter2D != nil {
            let region = MKCoordinateRegionMakeWithDistance(currentCenter2D,
                                                            regionRadius * 2.0, regionRadius * 2.0)
            mapView.setRegion(region, animated: true)
        }
        else {
     
     let latitude : CLLocationDegrees = 51.3758
     let longitude : CLLocationDegrees = -2.3999
     let center = CLLocationCoordinate2D(latitude: latitude, longitude:longitude)
     let region = MKCoordinateRegionMakeWithDistance(center,
     regionRadius * 2.0, regionRadius * 2.0)
     mapView.setRegion(region, animated: true)
 
        }
    */
     }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
    }
    
    @objc func getWeather()
    {
        if Reachability.isConnectedToNetwork(){
            print("Internet Connection Available!")
        
        let session = URLSession.shared
        let weatherURL = URL(string: "http://api.openweathermap.org/data/2.5/weather?q=Bath,uk&units=imperial&APPID=3e79b079e2edb1da69a40bd645bb555f")!
        let dataTask = session.dataTask(with: weatherURL) {
            (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                print("Error:\n\(error)")
            } else {
                if let data = data {
                    let dataString = String(data: data, encoding: String.Encoding.utf8)
                    print("All the weather data:\n\(dataString!)")
                    if let jsonObj = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary {
                        if let mainDictionary = jsonObj!.value(forKey: "main") as? NSDictionary
                           {
                            if let temp = mainDictionary.value(forKey: "temp")
                               {
 
                                if let humid = mainDictionary.value(forKey :"humidity")
                                    {
                                            
                                        if let windDictionary = jsonObj!.value(forKey: "wind") as? NSDictionary{
                                            if let speed = windDictionary.value(forKey: "speed")
                                            {
                                        
                                        DispatchQueue.main.async {
                                            self.temperature = temp as! Double
                                            self.temperature = ((self.temperature - 32)*(5/9)).rounded(toPlaces: 1)
                                            self.wind = (speed as! Double).rounded(toPlaces: 1)
                                            self.humidity = (humid as! Double).rounded(toPlaces: 0)
                                            self.temperatureLabel?.text = "\(self.temperature) °C"
                                            self.windLabel?.text = "\(self.wind) km/h"
                                            self.humidityLabel?.text = "\(self.humidity) %"
                                          //print("lol",temperature,speed,humidity)
                                        }
                                        
                                        }
                                        
                                    }
 
                                }
                                
                            }
                        } else {
                            print("Error: unable to find temperature in dictionary")
                        }
                    } else {
                        print("Error: unable to convert json data")
                    }
                } else {
                    print("Error: did not receive data")
                }
            }
        }
        dataTask.resume()
        }else
    {
        
    //print("Internet Connection not Available!")
   //var lastReceptionReceived = self.recoverLastCoreDataReceptions().value(forKey : "weatherInformation") as? [Double]
       // if lastReceptionReceived?.count == 3
       // {
            self.temperatureLabel?.text = " - °C"
            self.windLabel?.text = " - km/h"
            self.humidityLabel?.text = " - %"
       // }
 
    }
 
    }
    
    func setupGeneralView()
    {
        
    
        generalWeatherView.backgroundColor = secondColor
        
        var tempImageView = UIImageView()
        tempImageView.image = UIImage(named: "sun")
        tempImageView.frame = CGRect(x: 15, y: 15, width: 40, height: 40)
        tempImageView.layer.cornerRadius = CGFloat(3)
        generalWeatherView.addSubview(tempImageView)
        
        temperatureLabel = UILabel()
        temperatureLabel?.frame = CGRect(x: 65, y: 15, width: 70, height: 40)
        temperatureLabel?.text = "45 C"
        temperatureLabel?.font = temperatureLabel?.font.withSize(15)
        temperatureLabel?.textColor = UIColor.white
        generalWeatherView.addSubview(temperatureLabel!)
        
        var windImageView = UIImageView()
        windImageView.frame = CGRect(x: 125, y: 15, width: 40, height: 35)
        windImageView.image = UIImage(named: "wind")
        windImageView.layer.cornerRadius = CGFloat(3)
        generalWeatherView.addSubview(windImageView)
        
        windLabel = UILabel()
        windLabel?.frame = CGRect(x: 175, y: 15, width: 85, height: 40)
        windLabel?.text = "20 m/s"
        windLabel?.font = windLabel?.font.withSize(15)
        windLabel?.textColor = UIColor.white
        generalWeatherView.addSubview(windLabel!)
        
        var humidityImageView = UIImageView()
        humidityImageView.frame = CGRect(x: 255, y: 15, width: 40, height: 40)
        humidityImageView.image = UIImage(named: "humidity")
        humidityImageView.layer.cornerRadius = CGFloat(3)
        generalWeatherView.addSubview(humidityImageView)
        
        humidityLabel = UILabel()
        humidityLabel?.frame = CGRect(x: 305, y: 15, width: 70, height: 40)
        humidityLabel?.text = "30 %"
        humidityLabel?.textColor = UIColor.white
        humidityLabel?.font = humidityLabel?.font.withSize(15)
        generalWeatherView.addSubview(humidityLabel!)
        
        
        userLocationButton.setImage(UIImage(named:"locationImage2"), for: .normal)
        userLocationButton.contentMode = .scaleAspectFit
        userLocationButton.backgroundColor = .clear
        
    }
    
    
    func setupRiskLevelView()
    {
        
        risksLevelView = UIView()
        risksLevelView?.frame.size = CGSize(width: self.view.frame.width/2, height: self.view.frame.width/2)
        risksLevelView?.frame.origin = CGPoint(x: 0,y: -self.view.frame.height/8)
        
        let time : TimeInterval = 1.0
        let positionForBigAnimation = CGPoint(x: (view?.center.x)!, y: (view?.center.y)!-85)
        let greenPulseEffect = LFTPulseAnimation(repeatCount: Float.infinity, radius: 150, position: positionForBigAnimation)
        greenPulseEffect .backgroundColor = UIColor.green.cgColor
        greenPulseEffect .opacity = 1
        greenPulseEffect.animationDuration = time
        var animationDuration: TimeInterval = 1.0
        risksLevelView?.layer.insertSublayer(greenPulseEffect , below: risksLevelView?.layer)
        
        let yellowPulseEffect = LFTPulseAnimation(repeatCount: Float.infinity, radius: 120, position: positionForBigAnimation)
        yellowPulseEffect.backgroundColor = UIColor.yellow.cgColor
        yellowPulseEffect.opacity = 1
        //yellowPulseEffect.animationDuration = time
        risksLevelView?.layer.insertSublayer(yellowPulseEffect, below: risksLevelView?.layer)
        
        let orangePulseEffect = LFTPulseAnimation(repeatCount: Float.infinity, radius: 90, position: positionForBigAnimation)
        orangePulseEffect.backgroundColor = UIColor.orange.cgColor
        orangePulseEffect.opacity = 1
        //orangePulseEffect.animationDuration = time
        risksLevelView?.layer.insertSublayer(orangePulseEffect, below: risksLevelView?.layer)
        
        let redPulseEffect = LFTPulseAnimation(repeatCount: Float.infinity, radius: 60, position: positionForBigAnimation)
        redPulseEffect.backgroundColor = UIColor.red.cgColor
        redPulseEffect.opacity = 1
        //redPulseEffect.animationDuration = time
        risksLevelView?.layer.insertSublayer(redPulseEffect, below: risksLevelView?.layer)
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let backgroundTouch =  UITapGestureRecognizer(target: self, action: #selector(riskButtonUp(_:)))
        blurEffectView.isUserInteractionEnabled = true
        blurEffectView.addGestureRecognizer(backgroundTouch)
        
        chartView = UIView()
        chartView.frame = CGRect(x: self.view.frame.width/4, y: (self.view.frame.height/2), width: self.view.frame.width/2, height: 250)
        chartView.layer.cornerRadius = CGFloat(8)
        chartView.backgroundColor = .white
        
        let chartLabel = UILabel(frame: CGRect(x: 0, y: 0, width: chartView.frame.width, height: chartView.frame.height/5))
        chartLabel.text = "Danger color code"
        chartLabel.textAlignment = .center
        chartView.addSubview(chartLabel)
        
        let separatorLineView = UIView(frame: CGRect(x: 0, y: (chartView.frame.height/5)-1, width: chartView.frame.width, height: 1))
        separatorLineView.backgroundColor = .black
       
        chartView.addSubview(separatorLineView)
        
        let greenLabel = UILabel(frame: CGRect(x: 5, y: chartView.frame.height/5, width: chartView.frame.width, height: chartView.frame.height/5))
        greenLabel.text = " 100-50 km"
        chartView.addSubview(greenLabel)
        let greenPosition = CGPoint(x: greenLabel.frame.width - 40, y: greenLabel.frame.height/2)
        let greenLegendEffect = LFTPulseAnimation(repeatCount: Float.infinity, radius: 25, position: greenPosition)
        greenLegendEffect .backgroundColor = UIColor.green.cgColor
        greenLegendEffect .opacity = 1
        greenLegendEffect.animationDuration = time
        greenLabel.layer.insertSublayer(greenLegendEffect , below: greenLabel.layer)
        
        let yellowLabel = UILabel(frame: CGRect(x: 5, y:  2*chartView.frame.height/5, width: chartView.frame.width, height: chartView.frame.height/5))
        yellowLabel.text = " 50-30 km"
        chartView.addSubview(yellowLabel)
        let yellowPosition = CGPoint(x: yellowLabel.frame.width - 40, y: yellowLabel.frame.height/2)
        let yellowLegendEffect = LFTPulseAnimation(repeatCount: Float.infinity, radius: 25, position: yellowPosition)
        yellowLegendEffect.backgroundColor = UIColor.yellow.cgColor
        yellowLegendEffect.opacity = 1
        yellowLegendEffect.animationDuration = time
        yellowLabel.layer.insertSublayer(yellowLegendEffect , below: yellowLabel.layer)
        
        let orangeLabel = UILabel(frame: CGRect(x: 5, y:  3*chartView.frame.height/5, width: chartView.frame.width, height: chartView.frame.height/5))
        orangeLabel.text = " 30-20 km"
        chartView.addSubview(orangeLabel)
        let orangePosition = CGPoint(x: orangeLabel.frame.width - 40, y: greenLabel.frame.height/2)
        let orangeLegendEffect = LFTPulseAnimation(repeatCount: Float.infinity, radius: 25, position: orangePosition)
        orangeLegendEffect .backgroundColor = UIColor.orange.cgColor
        orangeLegendEffect .opacity = 1
        orangeLegendEffect.animationDuration = time
        orangeLabel.layer.insertSublayer(orangeLegendEffect , below: orangeLabel.layer)
        
        let redLabel = UILabel(frame: CGRect(x: 5, y: 4*chartView.frame.height/5 , width: chartView.frame.width, height: chartView.frame.height/5))
        redLabel.text = " 20-0 km"
        chartView.addSubview(redLabel)
        let redPosition = CGPoint(x: redLabel.frame.width - 40, y: redLabel.frame.height/2)
        let redLegendEffect = LFTPulseAnimation(repeatCount: Float.infinity, radius: 25, position: redPosition)
        redLegendEffect .backgroundColor = UIColor.red.cgColor
        redLegendEffect .opacity = 1
        redLegendEffect.animationDuration = time
        redLabel.layer.insertSublayer(redLegendEffect , below: redLabel.layer)
        
        topView.layer.cornerRadius = CGFloat(5)
        topView.layer.borderWidth = CGFloat(1)
        topView.layer.borderColor = secondColor.cgColor
        
        //containerView.layer.borderColor = secondColor.cgColor
        
        let positionForSmallAnimation = CGPoint(x:35, y: topView.frame.height/2)
        riskPulseEffect = LFTPulseAnimation(repeatCount: Float.infinity, radius: 30, position: positionForSmallAnimation)
        riskPulseEffect.backgroundColor = UIColor.green.cgColor
        riskPulseEffect.opacity = 1
        riskPulseEffect.animationDuration = time
        topView?.layer.insertSublayer(riskPulseEffect, below: topView?.layer)
        
       
       
        
        let touchDown = UILongPressGestureRecognizer(target:self, action: #selector(riskButtonDown))
        touchDown.minimumPressDuration = 0
        topView.addGestureRecognizer(touchDown)
        

        topView.backgroundColor = UIColor(red: 255/255, green: 252/255, blue: 237/255, alpha: 1)
        
        
        
    }
    
    func changeRiskColorAccording(distances : [CLLocationDistance])
    {
       
        let minimumDistance = distances.min()
        
        if minimumDistance! <= 20000.0 {
                riskPulseEffect.backgroundColor = UIColor.red.cgColor
            }
            else if (minimumDistance! > 20000.0) && (minimumDistance! <= 30000.0)
            {
                 riskPulseEffect.backgroundColor = UIColor.orange.cgColor
            }
            else if ( minimumDistance! > 30000.0) && (minimumDistance! <= 50000.0)
            {
                 riskPulseEffect.backgroundColor = UIColor.yellow.cgColor
            }
            else
            {
                riskPulseEffect.backgroundColor = UIColor.green.cgColor
            }
        
    }
    
    
    func calculateDistancefromCenter(lightninglocation : CLLocationCoordinate2D)->CLLocationDistance
    {
        var lightningLocation = CLLocation(latitude: lightninglocation.latitude, longitude: lightninglocation.longitude)
        return userDesiredLocation!.distance(from: lightningLocation)
    }
    
    func alertUserOfWarning(distances : [CLLocationDistance], warnings : [String])
    {
        
        let testView = UIView(frame: CGRect(x: (self.view.frame.width/2)-90,y: self.view.frame.height, width: 180, height: 100))
        testView.backgroundColor = secondColor
        testView.layer.cornerRadius = CGFloat(5)
        testView.layer.borderWidth = CGFloat(1)
        testView.layer.borderColor = secondColor.cgColor
        AudioServicesPlaySystemSound(1520)
        
        let lightningLabel = UITextView(frame : CGRect(x: 0,y: 0, width: 180, height: 100))
        lightningLabel.textColor =  .white
        lightningLabel.font = .systemFont(ofSize: 15)
        lightningLabel.backgroundColor = .clear
        if distances.count > 1 {
            lightningLabel.text = "   Lightnings detected! \n\n"
            for dist in distances {
                lightningLabel.text?.append(contentsOf: "              \(dist.rounded(toPlaces: 0)) m\n")
            }
        }
        else if distances.count == 1 {
            lightningLabel.text = "   Lightning detected! \n\n            \(distances[0].rounded(toPlaces: 0)) m"
        }
        
        if warnings.isEmpty == false {
            testView.frame.size.height = 160
            lightningLabel.frame.size.height = 160
            lightningLabel.text?.append(contentsOf: "\n\n")
            for warning in warnings
            {
               lightningLabel.text?.append(contentsOf: "  \(warning)\n")
            }
        }
        
        let gif1 = UIImage(gifName: "lightningGif4.gif")
        let dangerImageView = UIImageView(gifImage: gif1, manager: SwiftyGifManager.defaultManager, loopCount: -1)
        dangerImageView.frame = CGRect(x:10,y: 35, width: 30, height:50)
        testView.addSubview(dangerImageView)
        testView.addSubview(lightningLabel)
        self.view.addSubview(testView)
        
        UIView.animate(withDuration: 3, delay: 2, options: UIViewAnimationOptions.curveEaseIn, animations: {
            //Frame Option 1:
             testView.frame = CGRect(x: (self.view.frame.width/2)-90 ,y: (self.view.frame.height/2)-100, width: 180, height: 160)
            
            
        },completion: { finish in
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 6, execute:
                {
                    UIView.animate(withDuration: 0.5, delay: 0,options: UIViewAnimationOptions.curveEaseOut,animations: {
                        lightningLabel.frame = CGRect(x: 0 ,y:0, width:0, height:0)
                        dangerImageView.image = nil
                        
                        testView.frame = CGRect(x: (self.view.frame.width/2) ,y: 50, width: 0, height:0)
                        //lightningLabel.frame = CGRect(x: 0 ,y:0, width:10, height:10)
                        //testView.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
                        
                        // If you want to restrict the button not to repeat animation..You can enable by setting into true
                       
                    },completion: { finish in testView.removeFromSuperview()})
        })
        
      })
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
    
    
    

}

extension Float {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Float{
        let divisor = pow(10.0, Float(places))
        return (self * divisor).rounded() / divisor
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double{
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}





