//
//  EventViewController.swift
//  Time-Scheduling-App
//
//  Created by Kristie Huang on 7/10/17.
//  Copyright © 2017 Kristie Huang. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseDatabase
import JTAppleCalendar

class EventViewController: UIViewController {
    //event page
    
    @IBOutlet weak var calendarView: JTAppleCalendarView!
    @IBOutlet weak var monthYearLabel: UILabel!
    @IBOutlet weak var eventNameTextField: UITextField!
    @IBOutlet weak var availableDatesLabel: UILabel!
    
    var eventss = [Event]()
    var eventsString = [String]()
    
    var performSegue = false
    
    
    @IBAction func backButtonTapped(_ sender: Any) {
        
        print("Transitioning back to home/back")
        let sureAlert = UIAlertController(title: "Are you sure?", message: "Unsaved information will be lost. The Save&Close button will save your event if you wish to edit later.", preferredStyle: .alert)
        let yes = UIAlertAction(title: "Yes", style: .default) { (_) in
            //delete event if it exists
            
            for event in self.eventss {
                self.eventsString.append("\(event.creationDate)")
            }
            if self.eventsString.contains("\(EventViewController.event?.creationDate ?? Date())") {
                for invitee in (EventViewController.event?.invitees!)! {
                    let inviteeRef = Database.database().reference().child("users").child(invitee.key).child("invited events").child((EventViewController.event?.key!)!)
                    inviteeRef.removeValue()
                    print("\(invitee.key) uninvited")
                }
                
                let eventRef = Database.database().reference().child("events").child(User.current.uid).child((EventViewController.event?.key!)!)
                eventRef.removeValue()
                
                
                let hostRef = Database.database().reference().child("users").child(User.current.uid).child("hosting events").child((EventViewController.event?.key!)!)
                hostRef.removeValue()
                

            }
            self.performSegue = true
            self.performSegue(withIdentifier: "backButtonSegue", sender: nil)
        }
        let no = UIAlertAction(title: "No", style: .cancel, handler: nil)
        sureAlert.addAction(no)
        sureAlert.addAction(yes)
        
        if !(self.datesChosen.isEmpty) || !(eventNameTextField.text?.isEmpty)! {
            present(sureAlert, animated: true)
        }
        else {
            self.performSegue = true
            self.performSegue(withIdentifier: "backButtonSegue", sender: nil)
        }
        
        
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "backButtonSegue" {
            return performSegue
        }
        else {
            return true
        }
    }
    
    @IBAction func todayButtonTapped(_ sender: Any) {
        calendarView.scrollToDate(Date())
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        
        firstDispatchGroup.enter()
        newEvent()
        firstDispatchGroup.notify(queue: .main, execute: {
            self.countDates()
            
            InviteEventViewController.event = EventViewController.event
            
            self.performSegue(withIdentifier: "nextSegue", sender: nil)
        })
    }
    
    @IBAction func saveCloseButtonTapped(_ sender: Any) {
        
        //dateschosen is dates form
        //datesarr is string form (to put into firebase)
        
        //merge all user's Counts dictionaries = mergedCounts
        //used mergedCounts instead
        //create users. add users to indiv events.
        
        firstDispatchGroup.enter()
        newEvent()
        firstDispatchGroup.notify(queue: .main, execute: {
            self.countDates()
            
        })
    }
    
    @IBAction func unwindToPage1(_ segue: UIStoryboardSegue) {
        
    }
    
    let outsideMonthColor = UIColor(colorWithHexValue: 0x7FAEE7) //cell date label color in indates/outdates
    let monthColor = UIColor.white //cell date label color in this month
    let selectedMonthColor = UIColor(colorWithHexValue: 0xA3C9F6) //color of selected date label text
    let currentDateSelectedViewColor = UIColor(colorWithHexValue: 0x7FAEE7)
    
    
    let dateFormatter = DateFormatter()
    
    var numberOfDates:Int = 0
    //    var datesChosen: [Date] = []
    var datesChosen: [String] = []
    
    
    let firstDispatchGroup = DispatchGroup()
    
    var newOrderedDict = NSMutableDictionary()
    
    
    static var event: Event?
    static var invitees: [String: Bool] = [:]
    static var emailinvitees: [String] = []
    
    static func getEvent () -> Event {
        return event!
    }
    var existingDates = [String]()
    let dispatchGroup = DispatchGroup()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.existingDates = []
        datesChosen = []
        numberOfDates = 0
        //
        
        
        calendarView.allowsMultipleSelection  = true
        calendarView.isRangeSelectionUsed = true
        
        availableDatesLabel.text = "\(numberOfDates) dates chosen | Press & hold to select a range"
        
        //longpress to select range
        calendarView.allowsMultipleSelection = true
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(didStartRangeSelecting(gesture:)))
        gesture.minimumPressDuration = 0.5
        calendarView.addGestureRecognizer(gesture)
        calendarView.isRangeSelectionUsed = true
        
        //dismiss keyboard
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
    }
    
    //    for existing events
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        existingDates = []
        datesChosen = []
        numberOfDates = 0
        
        dispatchGroup.enter()
        if let event = EventViewController.event {
            eventNameTextField.text = event.name
            
            for (myDate) in event.dates {
                
                self.existingDates.append(myDate)
                self.datesChosen.append(myDate)
                //                self.numberOfDates += 1
                
                
            }
            
            var counts: [String: Int] = [:]
            
            for date1 in existingDates {
                counts[date1] = (counts[date1] ?? 0) + 1
                for (day, count) in counts {
                    if count > 2 { //repetitive
                        let index = existingDates.index(of: day)
                        existingDates.remove(at: index!)
                    }
                    
                }
            }
            
            numberOfDates = existingDates.count
            existingDates = datesChosen
            
            
            self.availableDatesLabel.text = "\(self.numberOfDates) dates chosen | Press & hold to select a range"
            
            dispatchGroup.leave()
            //show selected event.dates
        } else {
            eventNameTextField.text = "Untitled Event"
            dispatchGroup.leave()
        }
        
        
        setUpCalendarView()
        
        
        calendarView.visibleDates { visibleDates in
            self.setupViewsOfCalendar(from: visibleDates)
        }
        
        let currentDate = Date()
        calendarView.scrollToDate(currentDate)
        
        
        calendarView.allowsMultipleSelection  = true
        calendarView.isRangeSelectionUsed = true
        
        
        
        
    }
    
    func setUpCalendarView() {
        calendarView.minimumLineSpacing = 0
        calendarView.minimumInteritemSpacing = 0
        
        
        
    }
    
    
    
    func handleCellSelected(view: JTAppleCell?, cellState: CellState) {
        guard let validCell = view as? CalendarCell
            else { return }
        
        //        if cellState.dateBelongsTo != .thisMonth {
        //            validCell.isUserInteractionEnabled = false
        //        }
        
        if cellState.isSelected {
            //selected view = circle behind text
            validCell.selectedView.isHidden = false //is not hidden
        }
        else {
            validCell.selectedView.isHidden = true //is hidden
        }
    }
    
    func handleCellTextColor(view: JTAppleCell?, cellState: CellState) {
        guard let validCell = view as? CalendarCell
            else { return }
        
        if cellState.isSelected {
            //selected view = circle behind text
            validCell.dateLabel.textColor = selectedMonthColor
        }
        else { //if cell is deselected
            if cellState.dateBelongsTo == .thisMonth {
                validCell.dateLabel.textColor = monthColor
                //cell date label color in this month
            }
            else {
                validCell.dateLabel.textColor = outsideMonthColor
                //cell date label color in indates/outdates
            }
        }
    }
    
    
    func setupViewsOfCalendar(from visibleDates: DateSegmentInfo) {
        let date = visibleDates.monthDates.first!.date
        
        self.dateFormatter.dateFormat = "MMMM yyyy"
        self.monthYearLabel.text = "   \(self.dateFormatter.string(from: date))"
        
    }
    
    private func currentTopViewController() -> UIViewController {
        var topVC: UIViewController? = UIApplication.shared.delegate?.window??.rootViewController
        while ((topVC?.presentedViewController) != nil) {
            topVC = topVC?.presentedViewController
        }
        return topVC!
    }
    
    private func showError(bigErrorMsg: String, smallErrorMsg: String){
        let currentTopVC: UIViewController? = self.currentTopViewController()
        
        let alertController = UIAlertController(title: "\(bigErrorMsg)", message:
            "\(smallErrorMsg)", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
        
        currentTopVC?.present(alertController, animated: true, completion: nil)
        
    }
    
    func newEvent(){
        
        //if event already exists, SAVE to existing
        
        let eventTableViewController = EventTableViewController()
        
        if (self.eventNameTextField.text?.isEmpty)! {
            eventNameTextField.text = "Untitled Event"
        }
        EventViewController.event?.name = self.eventNameTextField.text ?? "Untitled Event"
        
        
        print(" event name is \(EventViewController.event?.name ?? "Untitled Event")")
        var isFound = false
        UserService.events(for: User.current, completion: { (events:[Event]) in
            //for each event in events called from user
            for eventz in events {
                if EventViewController.event?.key == eventz.key {
                    
                    var datesArr = [String]()
                    
                    for date in self.datesChosen.enumerated() {
                        let justDate = date.1
                        datesArr.append("\(justDate)")
                    }
 
                    if datesArr.isEmpty {
                        self.showError(bigErrorMsg: "Enter a date!", smallErrorMsg: "Please.")
                        //unwind to page 1, don't save
                        return
                    }
                    let eventRef = Database.database().reference().child("events").child(User.current.uid).child((EventViewController.event?.key!)!)
                    eventRef.child("name").setValue(EventViewController.event?.name ?? "Untitled Event")
                    
                    eventRef.child("dates").setValue(datesArr)
                    self.datesChosen = []
                    datesArr = []
                    
                    eventTableViewController.tableView.reloadData()
                    isFound = true
                    print("isfound is \(isFound)")
                    self.firstDispatchGroup.leave()
                    
                }
            }
            
            if isFound == false {
                print("new event")
                
                var datesArr = [String]()

                
                //changing type date to type string
                for date in self.datesChosen.enumerated() {
                    let justDate = date.1
                    datesArr.append("\(justDate)")
                }
                
                
                if datesArr.isEmpty {
                    self.showError(bigErrorMsg: "Enter a date!", smallErrorMsg: "Please.")
                    //unwind, don't save
                    return
                }
                
                if EventViewController.invitees.isEmpty {
                    EventViewController.invitees.updateValue(false, forKey: User.current.uid)
                }
                
                //add event to database
                EventViewController.event = EventService.addEvent(name: EventViewController.event!.name!, invitees: EventViewController.invitees, creationDate: (EventViewController.event?.creationDate)!, dates: datesArr, note: "", emailInvitees: (EventViewController.emailinvitees))
                
                
                
                datesArr = []
                self.datesChosen = []
                
                UserService.events(for: User.current) { (events) in
                    self.eventss = events
                }
                

                self.firstDispatchGroup.leave()
                print("dispatch group run")
            }
            
        })
        
    }
    
    
    func countDates() {
        var counts: [String: Int] = [:]
        var array: [Int] = []
        for date in self.datesChosen {
            counts[date] = (counts[date] ?? 0) + 1
        }
        //sort array by count value, then display only top three
        print("counts are \(counts)")  // "[BAR: 1, FOOBAR: 1, FOO: 2]"
        
        for (key, value) in counts {
            print("\(value) of people prefer the \(key) date")
            array.append(value)
            //value is int
            
            for var item in array.sorted() {
                let eventViewController = EventViewController()
                item = value
                eventViewController.newOrderedDict[key] = item
            }
        }
        
    }
    
    
    
    //longpress gesture func!!
    func didStartRangeSelecting(gesture: UILongPressGestureRecognizer) {
        var rangeSelectedDates: [Date] = []
        
        let point = gesture.location(in: gesture.view!)
        rangeSelectedDates = calendarView.selectedDates
        
        
        if let cellState = calendarView.cellStatus(at: point) {
            let date = cellState.date
            if !rangeSelectedDates.contains(date) {
                let dateRange = calendarView.generateDateRange(from: rangeSelectedDates.first ?? date, to: date)
                for aDate in dateRange {
                    if !rangeSelectedDates.contains(aDate) {
                        rangeSelectedDates.append(aDate)
                        
                        handleCellSelected(view: gesture.view as? JTAppleCell, cellState: cellState)
                        handleCellTextColor(view: gesture.view as? JTAppleCell, cellState: cellState)
                        handleSelection(cell: gesture.view as? JTAppleCell, cellState: cellState)
                    }
                }
                calendarView.selectDates(from: rangeSelectedDates.first!, to: date, keepSelectionIfMultiSelectionAllowed: true)
            } else {
                let indexOfNewlySelectedDate = rangeSelectedDates.index(of: date)! + 1
                let lastIndex = rangeSelectedDates.endIndex
                let calendar = Calendar(identifier: .gregorian)
                let followingDay = calendar.date(byAdding: .day, value: 1, to: date)!
                calendarView.selectDates(from: followingDay, to: rangeSelectedDates.last!, keepSelectionIfMultiSelectionAllowed: false)
                rangeSelectedDates.removeSubrange(indexOfNewlySelectedDate..<lastIndex)
                
                handleCellSelected(view: gesture.view as? JTAppleCell, cellState: cellState)
                handleCellTextColor(view: gesture.view as? JTAppleCell, cellState: cellState)
                handleSelection(cell: gesture.view as? JTAppleCell, cellState: cellState)
            }
        }
        
        if gesture.state == .ended {
            rangeSelectedDates = []
        }
    }
}





extension EventViewController: JTAppleCalendarViewDataSource {
    
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        
        dateFormatter.dateFormat = "MMM dd, yyyy, h:mm a"
        
        dateFormatter.timeZone = Calendar.current.timeZone
        dateFormatter.locale = Calendar.current.locale
        dateFormatter.dateStyle = .medium
        
        let startDate = dateFormatter.date(from: "Jan 01, 2017")! //current month
        let endDate = dateFormatter.date(from: "Dec 31, 2018")!
        
        
        let parameters = ConfigurationParameters(startDate: startDate, endDate: endDate)
        return parameters
    }
    
    
    
    
}

extension EventViewController: JTAppleCalendarViewDelegate {
    
    func handleSelection(cell: JTAppleCell?, cellState: CellState) {
        
        if let cell = cell {
            let calendarCell = cell as! CalendarCell // You created the cell view if you followed the tutorial
            switch cellState.selectedPosition() {
            case .full, .left, .right:
                calendarCell.selectedView.isHidden = false
                calendarCell.selectedView.backgroundColor = UIColor.white // Or you can put what ever you like for your rounded corners, and your stand-alone selected cell
                calendarCell.isSelected = true
            case .middle:
                calendarCell.selectedView.isHidden = false
                calendarCell.selectedView.backgroundColor = UIColor.white // Or what ever you want for your dates that land in the middle
                calendarCell.isSelected = true
                
            default:
                calendarCell.selectedView.isHidden = true
                calendarCell.selectedView.backgroundColor = nil // Have no selection when a cell is not selected
                calendarCell.isSelected = false
            }
        }
        else {
            return
        }
        
    }
    
    
    
    
    //display the cell
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "CalendarCell", for: indexPath) as! CalendarCell
        cell.dateLabel.text = cellState.text
        
        
        dispatchGroup.notify(queue: .main) {
            
            for myDate in self.existingDates {
                
                
                let dateFormatter3 = DateFormatter()
                dateFormatter3.dateFormat = "yyyy-MM-dd hh:mm:ss Z"
                
                let dateFormatter4 = DateFormatter()
                dateFormatter4.dateFormat = "EEEE, MMMM d, yyyy"
                
                let dateee: Date? = dateFormatter3.date(from: "\(date)")
                
                
                if myDate == dateFormatter4.string(from: dateee!) {
                    cell.isSelected = true
                    
                    
                    cell.selectedView.isHidden = false
                    cell.selectedView.backgroundColor = UIColor.white
                    cell.dateLabel.textColor = self.selectedMonthColor
                    
                    //
                    
                    //kljhgj
                    
                    break
                    
                }
                else {
                    self.handleCellSelected(view: cell, cellState: cellState)
                    self.handleCellTextColor(view: cell, cellState: cellState)
                    self.handleSelection(cell: cell, cellState: cellState)
                }
                
            }
            if self.existingDates.isEmpty {
                self.handleCellSelected(view: cell, cellState: cellState)
                self.handleCellTextColor(view: cell, cellState: cellState)
                self.handleSelection(cell: cell, cellState: cellState)
            }
            
            
            
            
        }
        return cell
        
        
    }
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        
        //read exisitng dates
        //for date in existing dates

        
        handleCellSelected(view: cell, cellState: cellState)
        handleCellTextColor(view: cell, cellState: cellState)
        
        handleSelection(cell: cell, cellState: cellState)
        numberOfDates += 1
        
        if numberOfDates == 1 {
            availableDatesLabel.text = "\(numberOfDates) date chosen"
        } else {
            availableDatesLabel.text = "\(numberOfDates) dates chosen"
        }
        
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd hh:mm:ss Z"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        
        let formatDate: Date? = dateFormatterGet.date(from: "\(date)")
        print(dateFormatter.string(from: formatDate!))
        
        
        self.datesChosen.append(dateFormatter.string(from: formatDate!))
        //        print("dates chosen array are \(self.datesChosen.enumerated())")
        
        
        
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        
        handleCellSelected(view: cell, cellState: cellState)
        handleCellTextColor(view: cell, cellState: cellState)
        handleSelection(cell: cell, cellState: cellState)
        
        numberOfDates -= 1
        
        if numberOfDates == 1 {
            availableDatesLabel.text = "\(numberOfDates) date chosen"
        } else {
            availableDatesLabel.text = "\(numberOfDates) dates chosen"
        }
        
        
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd hh:mm:ss Z"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        
        let formatDate: Date? = dateFormatterGet.date(from: "\(date)")
        print(dateFormatter.string(from: formatDate!))
        
        
        self.datesChosen = self.datesChosen.filter { $0 != dateFormatter.string(from: formatDate!) }
        
        print("dates chosen array are \(self.datesChosen.enumerated())")
        
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        let date = visibleDates.monthDates.first!.date
        
        dateFormatter.dateFormat = "MMMM yyyy"
        monthYearLabel.text = "   \(dateFormatter.string(from: date))"
    }
}

extension UIColor {
    convenience init(colorWithHexValue value: Int, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((value & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((value & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(value & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}
