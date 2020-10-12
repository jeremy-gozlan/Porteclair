//
//  olfHisoty.swift
//  Porteclair
//
//  Created by Jeremy on 15/03/2018.
//  Copyright © 2018 Jeremy. All rights reserved.
//

import Foundation

//
//  historyViewController.swift
//  Porteclair
//
//  Created by Jeremy on 09/03/2018.
//  Copyright © 2018 Jeremy. All rights reserved.
//
/*
import Foundation
import UIKit
import Firebase
import CoreLocation
import CoreData
import MapKit
import ImageIO
import SwiftyGif

class customTapRecognizer: UITapGestureRecognizer {
    var section: Int?
}

class historyTableViewCell: UITableViewCell {
    
    
    
    @IBOutlet weak var historyImageView: UIImageView!
    
    
    @IBOutlet weak var menuCellLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

class historyViewController : UIViewController, UITableViewDelegate , UITableViewDataSource,UIGestureRecognizerDelegate {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    var handle : AuthStateDidChangeListenerHandle?
    
    var appDelegate : AppDelegate!
    var context : NSManagedObjectContext!
    
    var sectionToShowStatus : (Int,Bool)?
    
    var previousRecords = [[String:Any]] ()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        context = appDelegate.persistentContainer.viewContext
        tableView.delegate = self
        tableView.dataSource = self
        self.tableView.separatorStyle = .none
        recoverCoreDataReceptions()
        
        
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
    
    func recoverCoreDataReceptions()
    {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ServerReception")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject]
            {
                if let date = data.value(forKey: "Date") as? Date
                {
                    var listSensorForRecord = [[Double]]()
                    var listLightningForRecord = [[Double]] ()
                    
                    if let sensorList = data.value(forKey: "sensorList") as? [[Double]]
                    {
                        listSensorForRecord = sensorList
                    }
                    
                    if let lightningList = data.value(forKey:"lightningList") as? [[Double]]
                    {
                        listLightningForRecord = lightningList
                    }
                    
                    previousRecords.append(formatCoreDataRecord(rawDate: date, rawSensorList: listSensorForRecord, rawLightningList: listLightningForRecord))
                    
                }
                
                
            }
        } catch {
            
            print("Failed")
        }
        print(previousRecords)
        previousRecords = previousRecords.sorted {
            switch ($0["Date"], $1["Date"]) {
            case (nil, nil), (_, nil):
                return true
            case (nil, _):
                return false
            case let (lhs as Date, rhs as Date):
                return lhs > rhs
            default:
                return true
            }
        }
        print("voila")
        // A ORDER BY DATE OU CHECK SI CA ORDER TT SEUL !
        print(previousRecords)
    }
    
    func formatCoreDataRecord(rawDate : Date, rawSensorList : [[Double]], rawLightningList : [[Double]]) -> [String:Any]
    {
        
        var formattedSensorList = [Sensor] ()
        var formattedLightningList = [Lightning] ()
        var formattedDate : Date = Date()
        
        if let date = rawDate as? Date
        {
            formattedDate = date
        }
        
        for sensor in rawSensorList
        {
            if sensor.count == 4
            {
                var id = 0
                var battery = 0
                var latitude = 0.0
                var longitude = 0.0
                
                if let Id = sensor[0] as? Double
                {
                    id = Int(Id)
                }
                if let Battery = sensor[1] as? Double
                {
                    battery = Int(Battery)
                }
                if let Latitude = sensor[2] as? Double
                {
                    latitude  = Latitude
                }
                if let Longitude = sensor[3] as? Double
                {
                    longitude = Longitude
                }
                
                formattedSensorList.append(Sensor(id: id, lat: latitude , long: longitude, batteryLevel: battery))
            }
            
            
        }
        
        for light in rawLightningList
        {
            if light.count == 2
            {
                var latitude = 0.0
                var longitude = 0.0
                
                if let Latitude = light[0] as? Double
                {
                    latitude  = Latitude
                }
                if let Longitude = light[1] as? Double
                {
                    longitude = Longitude
                }
                formattedLightningList.append(Lightning(date: formattedDate, lat: latitude, long: longitude))
            }
            
        }
        
        
        return ["Date":formattedDate,"SensorList":formattedSensorList,"LightningList":formattedLightningList] as! [String:Any]
        
    }
    
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell") as! historyTableViewCell
        cell.backgroundColor = .red
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alert = SnapshotView(model: "titre")
        alert.show(animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(63)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if (indexPath.section == sectionToShowStatus?.0) && (sectionToShowStatus?.1 == true) {
            return 63.0
            
        }
        return 0.0
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UIView(frame : CGRect(x: 0.0, y: 0.0, width: self.tableView.frame.width, height: 70.0))
        let borderLine = UIView(frame: CGRect(x: 20 , y: 65, width: 250, height: 1))
        borderLine.backgroundColor = .gray
        let tap = customTapRecognizer(target: self,action : #selector(showHideCellForSection))
        headerView.backgroundColor = .blue
        tap.section = section
        headerView.addGestureRecognizer(tap)
        let label = UILabel(frame : CGRect(x: 8, y: 8, width: headerView.frame.width-8 , height: 45))
        label.font = label.font.withSize(20)
        let shoeImageView = UIImageView(frame : CGRect(x: 20, y: 8, width: 47, height: 53))
        shoeImageView.contentMode = .scaleAspectFit
        label.text = "Monday 15 December"
        label.textColor = UIColor.white
        //shoeImageView.image = UIImage(named: menuImagesLabels[section])
        headerView.addSubview(label)
        // headerView.addSubview(shoeImageView)
        headerView.addSubview(borderLine)
        
        return headerView
    }
    
    @objc func showHideCellForSection(gestureRecognizer: customTapRecognizer){
        print (gestureRecognizer.section)
        if gestureRecognizer.section == sectionToShowStatus?.0 {
            sectionToShowStatus?.1 = !(sectionToShowStatus?.1)!
        }
        else {
            sectionToShowStatus = (gestureRecognizer.section!, true)
        }
        tableView.reloadData()
    }
    
    @objc func displaySnapshotViewForTimeGap()
    {
        
    }
    
    
    
}
*/
