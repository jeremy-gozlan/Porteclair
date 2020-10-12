//
//  logSnapshotView.swift
//  Porteclair
//
//  Created by Jeremy on 02/04/2018.
//  Copyright © 2018 Jeremy. All rights reserved.
//

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

class logSnapshotView : UIView, Modal {
    
    
    var backgroundView = UIView()
    var dialogView = UIView()
    var textView = UITextView()
    
    
    
    
    convenience init(timeGap : [Date], logs : String) {
        self.init(frame: UIScreen.main.bounds)
        
        
        let startTime = timeGap[0]
        let endTime = timeGap[1]
        
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
        //dialogView.addSubview(separatorLineView)
        
       
        
        
        textView.frame.origin = CGPoint(x: 8, y: separatorLineView.frame.height + separatorLineView.frame.origin.y + 8)
        textView.frame.size = CGSize(width: dialogViewWidth - 16 , height: 500 - separatorLineView.frame.height  - 8)
        textView.textColor = secondColor
        textView.backgroundColor = UIColor(red: 255/255, green: 252/255, blue: 237/255, alpha: 1)
        textView.layer.cornerRadius = 4
        textView.clipsToBounds = true
        textView.text = logs
        textView.font = .systemFont(ofSize: 8)
        textView.isUserInteractionEnabled = true
        dialogView.addSubview(textView)
        
        var currentY : CGFloat =  separatorLineView.frame.height + separatorLineView.frame.origin.y + 8 + 500
        
        dialogView.frame.origin = CGPoint(x: 25, y: frame.height)
        dialogView.frame.size = CGSize(width: frame.width-50, height: currentY)
        
        dialogView.layer.cornerRadius = 6
        dialogView.clipsToBounds = true
        addSubview(dialogView)
        dialogView.backgroundColor = .clear
        dialogView.setGradient(colors: [firstColor,secondColor])
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTappedOnBackgroundView)))
    
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
    
   
    
}

class selectRangeView : UIView, Modal, UIPickerViewDelegate,UIPickerViewDataSource {
    
    
    var backgroundView = UIView()
    var dialogView = UIView()
    var downloadButton = UIButton()
    
    var datePicker: UIPickerView!
   
    var delegate : downloadProtocol?
    
    var recordedDays = [Date]()
    var recordedDaysString = [String]()
    
    var days = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
    var months = ["January","February","March","April","May","June","July","August","September","October","November","December"]

    convenience init(recordedDays : [Date]) {
        self.init(frame: UIScreen.main.bounds)
        
        self.recordedDays = recordedDays
        dateToString()
        
        backgroundView.frame = frame
        backgroundView.backgroundColor = UIColor.black
        backgroundView.alpha = 0.8
        addSubview(backgroundView)
        
        let dialogViewWidth = frame.width-50
        let startLabel = UILabel(frame: CGRect(x: 8, y: 8, width: (dialogViewWidth-16)/2, height: 30))
        startLabel.text = "Start date"
       startLabel.textColor = .white
        startLabel.textAlignment = .center
        dialogView.addSubview(startLabel)
        
        let endLabel = UILabel(frame: CGRect(x: 8+(dialogViewWidth-16)/2, y: 8, width: 8+(dialogViewWidth-16)/2, height: 30))
        endLabel.text = "End date"
        endLabel.textColor = .white
        endLabel.textAlignment = .center
        dialogView.addSubview(endLabel)
        
        let separatorLineView = UIView()
        separatorLineView.frame.origin = CGPoint(x: 0, y: startLabel.frame.height + 8)
        separatorLineView.frame.size = CGSize(width: dialogViewWidth, height: 1)
        separatorLineView.backgroundColor = UIColor.groupTableViewBackground
        //dialogView.addSubview(separatorLineView)
        
        
        datePicker = UIPickerView()
        self.datePicker.delegate = self
        self.datePicker.dataSource = self
        var currentY : CGFloat =  separatorLineView.frame.height + separatorLineView.frame.origin.y + 8
        
        datePicker.frame.origin = CGPoint(x: 8, y: currentY)
        datePicker.frame.size = CGSize(width: (dialogViewWidth - 16) , height: 150 - separatorLineView.frame.height  - 8)
        datePicker.backgroundColor = UIColor(red: 255/255, green: 252/255, blue: 237/255, alpha: 1)
        datePicker.clipsToBounds = true
        datePicker.layer.cornerRadius = CGFloat(4)
        dialogView.addSubview(datePicker)
        
        currentY += 150 - separatorLineView.frame.height  - 8
 
        downloadButton.frame.origin = CGPoint(x: 8, y: currentY + 8)
        downloadButton.frame.size = CGSize(width: (dialogViewWidth - 16) , height: 40)
        downloadButton.backgroundColor = UIColor(red: 255/255, green: 252/255, blue: 237/255, alpha: 1)
        downloadButton.setTitle("Download all", for: .normal)
        downloadButton.layer.cornerRadius = CGFloat(4)
        downloadButton.setTitleColor(secondColor, for: .normal)
        downloadButton.addTarget(self, action: #selector(downloadForDate), for: .touchUpInside)
        dialogView.addSubview(downloadButton)
        
        currentY += 56
        
        dialogView.frame.origin = CGPoint(x: 25, y: frame.height)
        dialogView.frame.size = CGSize(width: frame.width-50, height: currentY)
        
        dialogView.layer.cornerRadius = 6
        dialogView.clipsToBounds = true
        addSubview(dialogView)
        dialogView.backgroundColor = .clear
        dialogView.setGradient(colors: [firstColor,secondColor])
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTappedOnBackgroundView)))
        
    }
    
    func dateToString()
    {
        let myCalendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        let calendar = Calendar.current
        for date in self.recordedDays
        {
         let weekDayComp = myCalendar.components(.weekday, from: date)
         let year = calendar.component(.year, from: date)
         let month = calendar.component(.month, from: date)
         let day = calendar.component(.day, from: date)
        // self.recordedDaysString.append("\(days[weekDayComp.weekday!-1]) \(day) \(months[month-1]) \(year)")
         self.recordedDaysString.append("\(day)/\(month)/\(year)")
        }
        //print (self.recordedDaysString)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.recordedDays.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        var str = self.recordedDaysString[row]
        if component == 0 {
            str = self.recordedDaysString.reversed()[row]
        }
        return str
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        
        var startDay = self.recordedDays.reversed()[datePicker.selectedRow(inComponent: 0)]
        var endDay = self.recordedDays[datePicker.selectedRow(inComponent: 1)]
        //var end = self.recordedDays.count - datePicker.selectedRow(inComponent: 1)
        var nbDays = Calendar.current.dateComponents([.day], from: startDay, to: endDay).day!
        print(self.recordedDays.count)
        if nbDays == self.recordedDays.count-1  {
            self.downloadButton.setTitle("Download all", for: .normal)
        }
        else
        {
        self.downloadButton.setTitle("Download \(nbDays) days", for: .normal)
        }
    }
    
    @objc func downloadForDate()
    {
        var startDay = self.recordedDays.reversed()[datePicker.selectedRow(inComponent: 0)]
        var endDay = self.recordedDays[datePicker.selectedRow(inComponent: 1)]
        print(startDay,endDay)
        self.delegate?.download(startDay: startDay,endDay: endDay)
        dismiss(animated: true)
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        var str = self.recordedDaysString[row]
        if component == 0 {
            str = self.recordedDaysString.reversed()[row]
        }
        return NSAttributedString(string: str, attributes: [NSAttributedStringKey.foregroundColor:secondColor])
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
    
    
    
}
