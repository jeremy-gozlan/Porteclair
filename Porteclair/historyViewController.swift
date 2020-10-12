//
//  historyViewController.swift
//  Porteclair
//
//  Created by Jeremy on 09/03/2018.
//  Copyright © 2018 Jeremy. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import CoreLocation
import CoreData
import MapKit
import ImageIO
import SwiftyGif
import MessageUI
import NVActivityIndicatorView

protocol downloadProtocol
{
    func download(startDay:Date,endDay: Date)
}

class customTapRecognizer: UITapGestureRecognizer {
    var section: Int?
}
class subclassedUIButton: UIButton
{
    var indexPath: IndexPath?
}

class historyTableViewCell: UITableViewCell {
    
    

    @IBOutlet weak var historyImageView: UIImageView!
    
    
    @IBOutlet weak var menuCellLabel: UILabel!
    

    
    @IBOutlet weak var simulationButton: subclassedUIButton!
    
    @IBOutlet weak var logButton: subclassedUIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

class historyViewController : UIViewController, UITableViewDelegate , UITableViewDataSource,UIGestureRecognizerDelegate,MFMailComposeViewControllerDelegate, downloadProtocol{
    

    @IBOutlet weak var tableView: UITableView!
    
    
    
    var handle : AuthStateDidChangeListenerHandle?
    
    var storageRef : StorageReference!
    var refDict : CollectionReference!
    
    var appDelegate : AppDelegate!
    var context : NSManagedObjectContext!
    
    var sectionToShowStatus : (Int,Bool)?
    
    var days = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
    var months = ["January","February","March","April","May","June","July","August","September","October","November","December"]
    var hourStringGapForCell = ["00:00 - 06:00","06:00 - 12:00","12:00 - 18:00","18:00 - 24:00"]
    var hourGapForCell : [[Int]] = [[0,6],[6,12],[12,18],[18,24]]
    
    var previousRecords = [[String:Any]] ()
    var timeGap = [Date]()
    var recordedDays = [Date]()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        getTimeRange()
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        context = appDelegate.persistentContainer.viewContext
        tableView.delegate = self
        tableView.dataSource = self
        self.tableView.separatorStyle = .none
        self.navigationItem.title = "History"
        

        let downloadBarButtonItem = UIBarButtonItem(title: "Download", style: .plain, target: self, action: #selector(downloadButtonPressed))
        downloadBarButtonItem.tintColor = .white
        self.navigationItem.setRightBarButton(downloadBarButtonItem, animated: true)
        self.navigationController?.navigationBar.tintColor = .white
        
    }
    
    
    override func viewWillAppear(_ animated: Bool)
    {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if user == nil {
                let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "loginVC") as! loginViewController
                // .instantiatViewControllerWithIdentifier() returns AnyObject! this must be downcast to utilize it
                
                self.present(viewController, animated: false, completion: nil)
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func getTimeRange()
    {
        self.refDict = Firestore.firestore().collection("LiveReception")
        
        self.storageRef = Storage.storage().reference()
        
        
        self.refDict.order(by: "Date", descending: true).limit(to:1).addSnapshotListener { querySnapshot, error in
            guard let document = querySnapshot?.documents else {
                print("Error fetching document: \(error!)")
                return
            }

            for doc in (querySnapshot?.documents)!
            {
                
                let lastReception = doc.data() as! [String:Any]
                if let dateReceived = lastReception["Date"] as? Date
                {
                    self.timeGap.append(dateReceived)
                    
                }
            }
            self.refDict.order(by: "Date", descending: false).limit(to:1).addSnapshotListener { querySnapshot, error in
                guard let document = querySnapshot?.documents else {
                    print("Error fetching document: \(error!)")
                    return
                }
                for doc in (querySnapshot?.documents)!
                {
                    
                    let firstReception = doc.data() as! [String:Any]
                    if let dateReceived = firstReception["Date"] as? Date
                    {
                        self.timeGap.append(dateReceived)
                        let calendar = Calendar.current
                        let fmt = DateFormatter()
                        fmt.dateFormat = "dd/MM/yyyy"
                        let gregorian = Calendar(identifier: .gregorian)
                        var components1 = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self.timeGap[1])
                        var components2 = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self.timeGap[0])
                        components1.hour = 0
                        components1.minute = 0
                        components1.second = 0
                        components2.hour = 0
                        components2.minute = 0
                        components2.second = 0
                        var firstReceptionDay = gregorian.date(from: components1)!
                        var lastReceptionDay = gregorian.date(from: components2)!
                        while  lastReceptionDay >= firstReceptionDay
                        {
                            self.recordedDays.append(lastReceptionDay)
                            lastReceptionDay = calendar.date(byAdding: .day, value: -1, to: lastReceptionDay)!
                        
                        }
                       // self.recordedDays = self.recordedDays.reversed()
                        self.tableView.reloadData()
                    }
                }
                
            }
            
        }
        
       
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell") as! historyTableViewCell
        cell.setGradient(colors: [firstColor,secondColor])
        cell.menuCellLabel.text = hourStringGapForCell[indexPath.row]
        cell.simulationButton.layer.cornerRadius = CGFloat(10)
        cell.simulationButton.backgroundColor = UIColor(red: 255/255, green: 252/255, blue: 237/255, alpha: 1)
        cell.simulationButton.setTitleColor(secondColor, for: .normal)
        cell.simulationButton.indexPath = indexPath
        cell.simulationButton.addTarget(self, action: #selector(simulateForLocation), for: .touchUpInside)
        
        cell.logButton.indexPath = indexPath
        cell.logButton.addTarget(self, action: #selector(showLog), for: .touchUpInside)
        
        
       
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)  {
       
    }
    
    @objc func showLog(sender : subclassedUIButton)
    {
        var contentActivityView = UIView(frame: CGRect(x: (self.view.frame.width/2)-30, y: (self.view.frame.height/2)-30, width: 60 , height: 60))
        contentActivityView.layer.cornerRadius = CGFloat(5)
        contentActivityView.layer.borderWidth = CGFloat(1)
        contentActivityView.layer.borderColor = firstColor.cgColor
        contentActivityView.backgroundColor = UIColor(red: 255/255, green: 252/255, blue: 237/255, alpha: 1)
        
        
        var activityView = NVActivityIndicatorView(frame:CGRect(x: 10, y: 10, width: 40 , height: 40))
        activityView.color = secondColor
        contentActivityView.addSubview(activityView)
        
        view.addSubview(contentActivityView)
        view.bringSubview(toFront: contentActivityView)
        
        activityView.startAnimating()
    
        var logText = "Date, Sensors, Asset, Lightning, Warnings\n\n"
        
        if let indexPath = sender.indexPath
        {
            print("enter")
            let day = self.recordedDays[indexPath.section]
            let gregorian = Calendar(identifier: .gregorian)
            var components1 = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: day)
            var components2 = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: day)
            components1.hour = hourGapForCell[indexPath.row][0]
            components2.hour = hourGapForCell[indexPath.row][1]
            var startTime = gregorian.date(from: components1)!
            var endTime = gregorian.date(from: components2)!
            
            self.refDict.whereField("Date", isGreaterThan: startTime).whereField("Date", isLessThan: endTime).order(by: "Date", descending:true).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else
            {
                
                for document in querySnapshot!.documents {
                    
                    let reception = document.data() as! [String:Any]
                    
                    var receptionDate = Date()
                    var receptionSensorList = [Sensor]()
                    var receptionLightningList = [Lightning]()
                    
                    
                    
                    if let dateReceived = reception["Date"] as? Date
                    {
                        receptionDate = dateReceived
                        var newLine = "Date : \(receptionDate), Sensors : "
                        
                        if let sensorList = reception["Sensor"] as? [[String:Any]]
                        {
                            
                            for sen in sensorList
                            {
                                if let point = sen["location"] as? GeoPoint
                                {
                                    if let id = sen["id"] as? Int
                                    {
                                        if let batteryLevel = sen["battery"] as? Int
                                        {
                                            
                                            receptionSensorList.append(Sensor(id:id, lat: point.latitude , long : point.longitude , batteryLevel: batteryLevel))
                                            
                                        }
                                    }
                                }
                            }
                            
                        }
                        
                        for (index,sensor) in receptionSensorList.sorted(by: { $0.id < $1.id }).enumerated()
                        {
                            if index == receptionSensorList.count-1
                            {
                                newLine.append(contentsOf: "[id:\(sensor.id), battery:\(sensor.batteryLevel), status:On, location:[\(sensor.sensorLatitude),\(sensor.sensorLongitude)]")
                            }
                            else
                            {
                                newLine.append(contentsOf: "[id:\(sensor.id), battery:\(sensor.batteryLevel),status:On, location:[\(sensor.sensorLatitude),\(sensor.sensorLongitude)],")
                            }
                            
                        }
                        
                        
                         newLine.append(contentsOf: ", Asset : ")
                        
                        if let assetLocation = reception["Asset"] as? GeoPoint
                        {
                             newLine.append(contentsOf: "[location: [\(assetLocation.latitude),\(assetLocation.longitude)]")
                           
                        }
                        
                        
                        newLine.append(contentsOf: ", Lightning : ")
                        
                        if let lightningStrikeList = reception["Lightning"] as? [[String:Any]]
                        {
                            
                            for (index,light) in lightningStrikeList.enumerated()
                            {
                                
                                    if let location = light["location"] as? GeoPoint
                                    {
                                        if let time = light["time"] as? Date
                                        {
                                            if index == lightningStrikeList.count-1
                                            {
                                                 newLine.append(contentsOf: "[time:\(time), location: [\(location.latitude),\(location.longitude)]")
                                            }
                                            else
                                            {
                                                newLine.append(contentsOf: "[time:\(time), location: [\(location.latitude),\(location.longitude)],")
                                            }
                                        }
                                        else
                                        {
                                            if index==lightningStrikeList.count-1{
                                                 newLine.append(contentsOf: "[time:\(receptionDate), location: [\(location.latitude),\(location.longitude)]")
                                            }
                                            else {
                                                 newLine.append(contentsOf: "[time:\(receptionDate), location: [\(location.latitude),\(location.longitude)],")
                                            }
                                
                                        }
                                    }
                                
                             }
                        }
                        
                        
                        newLine.append(contentsOf: ", Warning : ")
                        
                        if let warningList = reception["Warning"] as? [String]
                        {
                            print (warningList)
                            for (index,warning) in warningList.enumerated()
                            {
                                
                                if index == warningList.count-1
                                {
                                    newLine.append(contentsOf: "\(warning)")
                                }
                                else
                                {
                                    newLine.append(contentsOf: "\(warning), ")
                                }
                            }
                            
                        }
                        
                        newLine.append(contentsOf: "\n\n")
                        logText.append(contentsOf: newLine)
                        
                    }
                    
                }
                activityView.stopAnimating()
                contentActivityView.removeFromSuperview()
                let logView = logSnapshotView(timeGap:[startTime,endTime], logs : logText)
                logView.show(animated: true)
                
               
            }
            
        }
        
        }
    }
    
    //
    @objc func simulateForLocation(sender : subclassedUIButton)
    {
        
       
        if let indexPath = sender.indexPath
        {
            print("enter")
        let day = self.recordedDays[indexPath.section]
        let gregorian = Calendar(identifier: .gregorian)
        var components1 = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: day)
        var components2 = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: day)
        components1.hour = hourGapForCell[indexPath.row][0]
        components2.hour = hourGapForCell[indexPath.row][1]
        var startTime = gregorian.date(from: components1)!
        var endTime = gregorian.date(from: components2)!
        self.refDict.whereField("Date", isGreaterThan: startTime).whereField("Date", isLessThan: endTime).order(by: "Date", descending: false).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                
                var receptionsInOrder = [[String:Any]] ()
                
                for document in querySnapshot!.documents {
                    
                    let reception = document.data() as! [String:Any]
                    
                    var receptionDate = Date()
                    var receptionSensorList = [Sensor]()
                    var receptionLightningList = [Lightning]()
                    
                    if let dateReceived = reception["Date"] as? Date
                    {
                        receptionDate = dateReceived
                        
                        if let sensorList = reception["Sensor"] as? [[String:Any]]
                        {
                            for sen in sensorList
                            {
                                if let point = sen["location"] as? GeoPoint
                                {
                                    if let id = sen["id"] as? Int
                                    {
                                        if let batteryLevel = sen["battery"] as? Int
                                        {
                                            
                                            receptionSensorList.append(Sensor(id:id, lat: point.latitude , long : point.longitude , batteryLevel: batteryLevel))
                                        }
                                    }
                                }
                            }
                            
                        }
                        
                        if let lightningStrikeList = reception["Lightning"] as? [[String:Any]]
                        {
                            
                            for light in lightningStrikeList
                            {
                                
                                if let location = light["location"] as? GeoPoint
                                {
                                    if let time = light["time"] as? Date
                                    {
                                           receptionLightningList.append(Lightning(date: time, lat: location.latitude, long: location.longitude))
                                    }
                                    else
                                    {
                                            receptionLightningList.append(Lightning(date: receptionDate, lat: location.latitude, long: location.longitude))
                                    }
                                }
                                
                            }
                        }
                        
                        var asset = CLLocationCoordinate2D()
                                
                        if let assetLocation = reception["Asset"] as? GeoPoint
                         {
                            asset = CLLocationCoordinate2D(latitude: assetLocation.latitude,longitude: assetLocation.longitude)
                            
                         }
                        
                        receptionsInOrder.append(["Date": receptionDate,"SensorList":receptionSensorList,"LightningList":receptionLightningList,"Asset":asset])
                    }
                    print("receptionInOrder",receptionsInOrder)
                }
                
                let activityAnimationView = SnapshotView(timeGap:[startTime,endTime],receptionsList:receptionsInOrder)
                activityAnimationView.show(animated: true)
                
                
            }
        }
        }
    }
    //ERROR HANDLING
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.recordedDays.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(50)
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if (indexPath.section == sectionToShowStatus?.0) && (sectionToShowStatus?.1 == true) {
            return 50.0
            
        }
        return 0.0
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UIView(frame : CGRect(x: 0.0, y: 0.0, width: self.tableView.frame.width, height: 50.0))
        let borderLine = UIView(frame: CGRect(x: 0 , y: 49, width: self.view.frame.width, height: 1))
        borderLine.backgroundColor = secondColor
        
        let tap = customTapRecognizer(target: self,action : #selector(showHideCellForSection))
        headerView.backgroundColor = UIColor(red: 255/255, green: 252/255, blue: 237/255, alpha: 1)
        tap.section = section
        headerView.addGestureRecognizer(tap)
       
        let myCalendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        let calendar = Calendar.current
        let weekDayComp = myCalendar.components(.weekday, from: self.recordedDays[section])
        let year = calendar.component(.year, from: self.recordedDays[section])
        let month = calendar.component(.month, from: self.recordedDays[section])
        let day = calendar.component(.day, from: self.recordedDays[section])
        
        var humanDate = "   \(days[weekDayComp.weekday!-1]) \(day) \(months[month-1]) \(year)"
        

        let label = UILabel(frame : CGRect(x: 8, y: 8, width: headerView.frame.width-8 , height: 45))
        label.font = label.font.withSize(15)
        label.textColor = secondColor
        label.backgroundColor = .clear
        label.text = humanDate
        
        //let previewButton = UIButton(frame: CGRect(x: self.view.frame.width - 70, y: 10, width: 60 , height: 30))
        //previewButton.backgroundColor = .blue
        //previewButton.layer.cornerRadius = CGFloat(8)
       // previewButton.layer.borderWidth = CGFloat(0)
        //previewButton.setTitle("View", for: .normal)
        //previewButton.setTitleColor(.blue, for: .normal)
        //previewButton.addGestureRecognizer(tap)
        
       
        headerView.addSubview(label)
        headerView.addSubview(borderLine)
    
        return headerView
    }
    
    @objc func showHideCellForSection(gestureRecognizer: customTapRecognizer){
        //print (gestureRecognizer.section)
        if gestureRecognizer.section == sectionToShowStatus?.0 {
            sectionToShowStatus?.1 = !(sectionToShowStatus?.1)!
        }
        else {
            sectionToShowStatus = (gestureRecognizer.section!, true)
        }
        tableView.reloadData()
    }
    
    func download(startDay : Date, endDay : Date){
        
        
        var contentActivityView = UIView(frame: CGRect(x: (self.view.frame.width/2)-30, y: (self.view.frame.height/2)-30, width: 60 , height: 60))
         contentActivityView.layer.cornerRadius = CGFloat(5)
         contentActivityView.layer.borderWidth = CGFloat(1)
         contentActivityView.layer.borderColor = firstColor.cgColor
         contentActivityView.backgroundColor = UIColor(red: 255/255, green: 252/255, blue: 237/255, alpha: 1)
         
         
         var activityView = NVActivityIndicatorView(frame:CGRect(x: 10, y: 10, width: 40 , height: 40))
         activityView.color = secondColor
         contentActivityView.addSubview(activityView)
         
         view.addSubview(contentActivityView)
         view.bringSubview(toFront: contentActivityView)
         
         activityView.startAnimating()
         
         let filename = "lightningActivity.txt"
         let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
         var logText = "Date,Sensors,Lightning\n"
         
         self.refDict.whereField("Date", isGreaterThan: startDay).whereField("Date", isLessThan: endDay).order(by: "Date", descending: false).getDocuments() { (querySnapshot, err) in
         if let err = err {
         print("Error getting documents: \(err)")
         } else
         {
         
         for document in querySnapshot!.documents {
         
         let reception = document.data() as! [String:Any]
         
         var receptionDate = Date()
         var receptionSensorList = [Sensor]()
         var receptionLightningList = [Lightning]()
         
         
         
         if let dateReceived = reception["Date"] as? Date
         {
         receptionDate = dateReceived
         var newLine = "Date : \(receptionDate), Sensors : "
         
         if let sensorList = reception["Sensor"] as? [[String:Any]]
         {
         
         for sen in sensorList
         {
         if let point = sen["location"] as? GeoPoint
         {
         if let id = sen["id"] as? Int
         {
         if let batteryLevel = sen["battery"] as? Int
         {
         
         receptionSensorList.append(Sensor(id:id, lat: point.latitude , long : point.longitude , batteryLevel: batteryLevel))
         
         }
         }
         }
         }
         
         }
         
         for (index,sensor) in receptionSensorList.sorted(by: { $0.id < $1.id }).enumerated()
         {
         if index == receptionSensorList.count-1
         {
            newLine.append(contentsOf: "[id:\(sensor.id),battery:\(sensor.batteryLevel),status: On, location:[\(sensor.sensorLatitude),\(sensor.sensorLongitude)]")
         }
         else
         {
         newLine.append(contentsOf: "[id:\(sensor.id),battery:\(sensor.batteryLevel),status: On, location:[\(sensor.sensorLatitude),\(sensor.sensorLongitude)],")
         }
         
         }
         
         
         newLine.append(contentsOf: ", Lightning : ")
         
        if let lightningStrikeList = reception["Lightning"] as? [[String:Any]]
            {
                
                for (index,light) in lightningStrikeList.enumerated()
                {
                    
                    if let location = light["location"] as? GeoPoint
                    {
                        if let time = light["time"] as? Date
                        {
                            if index == lightningStrikeList.count-1
                            {
                                newLine.append(contentsOf: "[time:\(time), location: [\(location.latitude),\(location.longitude)]")
                            }
                            else
                            {
                                newLine.append(contentsOf: "[time:\(time), location: [\(location.latitude),\(location.longitude)],")
                            }
                        }
                        else
                        {
                            if index==lightningStrikeList.count-1{
                                newLine.append(contentsOf: "[time:\(receptionDate), location: [\(location.latitude),\(location.longitude)]")
                            }
                            else {
                                newLine.append(contentsOf: "[time:\(receptionDate), location: [\(location.latitude),\(location.longitude)],")
                            }
                            
                        }
                    }
                    
                }
         }
            
        newLine.append(contentsOf: ", Warnings : ")
            
        if let warningList = reception["Warning"] as? [String]
        {
            
            for (index,warning) in warningList.enumerated()
            {
                    
                if index == warningList.count-1
                {
                    newLine.append(contentsOf: "\(warning)")
                }
                else
                {
                    newLine.append(contentsOf: "\(warning), ")
                }
            }
                
        }
         
         newLine.append(contentsOf: "\n\n")
         logText.append(contentsOf: newLine)
         
         }
         
         }
         do {
         try logText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
         if MFMailComposeViewController.canSendMail() {
         let emailController = MFMailComposeViewController()
         emailController.mailComposeDelegate = self
         emailController.setToRecipients([]) //I usually leave this blank unless it's a "message the developer" type thing
         emailController.setSubject("Porteclair historical lightning activity")
            
        let calendar = Calendar.current
        
        let startDayYear = calendar.component(.year, from: startDay)
        let startDayMonth = calendar.component(.month, from: startDay)
        let startDayDay = calendar.component(.day, from: startDay)
            
        let endDayYear = calendar.component(.year, from: endDay)
        let endDayMonth = calendar.component(.month, from: endDay)
        let endDayDay = calendar.component(.day, from: endDay)
        
        let periodString = "\(startDayDay)/\(startDayMonth)/\(startDayYear) and \(endDayDay)/\(endDayMonth)/\(endDayYear)"
            emailController.setMessageBody("Lightning activity log between the \(periodString).", isHTML: false)
         emailController.view.backgroundColor = UIColor(red: 255/255, green: 252/255, blue: 237/255, alpha: 1)
         let fileData = try Data(contentsOf: path!)
            
         emailController.addAttachmentData(fileData, mimeType: "text/plain", fileName: "Log.txt")
         activityView.stopAnimating()
         contentActivityView.removeFromSuperview()
         self.present(emailController, animated: true, completion: nil)
         }
         
         } catch {
         print("Failed to create file")
         print("\(error)")
         }
         }
         
         }
         
         
        
    }
    
    @objc func downloadButtonPressed()
    {
        
        let activityAnimationView = selectRangeView(recordedDays: self.recordedDays)
        activityAnimationView.delegate = self
        activityAnimationView.show(animated: true)
        
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    
   
}
