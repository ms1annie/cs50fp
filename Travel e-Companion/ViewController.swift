//
//  ViewController.swift
//  Travel e-Companion
//
//  Created by Annie on 6/15/17.
//  Copyright © 2017 Annie. All rights reserved.
//
//  I followed the MyToDo tutorial by Bruno Philipe, and then changed the code to make Travel e-Companion.
//  https://www.brunophilipe.com/blog/articles/swift-tutorial-mytodo/
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UITableViewController, CLLocationManagerDelegate {
    

    private var todoItems = [ToDoItem]()
    let locationManager = CLLocationManager()
    let mapView = MKMapView()
    let mapViewPin = MKPointAnnotation()
    let sortButton = UIButton(type: .system)
    var sortAZ = true

    @objc
    public func applicationDidEnterBackground(_ notification: NSNotification)
    {
        do
        {
            try todoItems.writeToPersistence()
        }
        catch let error
        {
            NSLog("Error writing to persistence: \(error)")
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        if CLLocationManager.authorizationStatus() == .notDetermined
        {
            locationManager.requestWhenInUseAuthorization()
        }
        
        
        // Do any additional setup after loading the view, typically from a nib.
        
        self.title = "Travel e-Companion"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ViewController.didTapAddItemButton(_:)))
        self.navigationItem.leftBarButtonItem = MKUserTrackingBarButtonItem(mapView: mapView)
        
        sortButton.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 40)
        sortButton.backgroundColor = .white
        sortButton.addTarget(self, action:#selector(self.sort), for: .touchUpInside)
        
        let topBorder = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 1))
        topBorder.backgroundColor = .lightGray
        sortButton.addSubview(topBorder)
        
        // Setup a notification to let us know when the app is about to close,
        // and that we should store the user items to persistence. This will call the
        // applicationDidEnterBackgound() function in this class
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(UIApplicationDelegate.applicationDidEnterBackground(_:)),
            name: NSNotification.Name.UIApplicationDidEnterBackground,
            object: nil)
        
        do
        {
            // Try to load from persistence
            self.todoItems = try [ToDoItem].readFromPersistence()
        }
        catch let error as NSError
        {
            if error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError
            {
                NSLog("No persistence file found, not necesserially an error...")
            }
            else
            {
                let alert = UIAlertController(
                    title: "Error",
                    message: "Could not load the item",
                    preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
                
                NSLog("Error loading from persistence: \(error)")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return todoItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell_todo", for: indexPath)
        if indexPath.row < todoItems.count
        {
            let item = todoItems[indexPath.row]
            cell.textLabel?.text = item.title
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row < todoItems.count
        {
            let item = todoItems[indexPath.row]
            item.done = !item.done
            tableView.reloadRows(at: [indexPath], with: .automatic)
            
            mapViewPin.title = item.title
            mapViewPin.coordinate = item.location.coordinate
            mapView.showAnnotations([mapViewPin], animated: true)
            mapView.selectAnnotation(mapViewPin, animated: true)
        }
    }
    
    func didTapAddItemButton(_ sender: UIBarButtonItem)
    {
        // Create an alert
        let alert = UIAlertController(
            title: "New Place",
            message: "Enter something memorable",
            preferredStyle: .alert)
        
        // Add a text field to the alert for the new item's title
        alert.addTextField(configurationHandler: nil)
        
        // Add a "cancel" button to the alert. This one doesn't need a handler
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
        
        // Add a "OK" button to the alert. The handler calls addNewToDoItem()
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in if let title = alert.textFields?[0].text
    
        {
            if let location = self.locationManager.location {
                self.addNewToDoItem(title: title, location: location)
            }
            }
        }))
        
        // Present the alert to the user
            self.present(alert, animated: true, completion: nil)
        
    }
        
    func addNewToDoItem(title: String, location: CLLocation)
    {
        // The index of the new item will be the current item count
        let newIndex = todoItems.count
        
        // Create new item and add it to the todo items list
        todoItems.append(ToDoItem(title: title, location: location))
        
        // Tell the table view a new row has been created
        tableView.insertRows(at: [IndexPath(row: newIndex, section: 0)], with: .top)
        
        updateSortButton()
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if indexPath.row < todoItems.count
        {
            todoItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .top)
            updateSortButton()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 300
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        mapView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 300)
        return mapView
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        updateSortButton()
        return sortButton
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        if status == .authorizedAlways || status == .authorizedWhenInUse
        {
            manager.startUpdatingLocation()
            mapView.setUserTrackingMode(.follow, animated: true)
            mapView.showsUserLocation = true
            mapView.showsPointsOfInterest = true
        }
    }
    
    func updateSortButton() {
        if todoItems.count == 0 {
            sortButton.setTitle("Tap + to add a new place", for: .normal)
            sortButton.isEnabled = false
        } else {
            if sortAZ {
                sortButton.setTitle("Sort A to Z", for: .normal)
                sortButton.isEnabled = true
            } else {
                sortButton.setTitle("Sort Z to A", for: .normal)
                sortButton.isEnabled = true
            }
        }
    }
    
    func sort() {
        if sortAZ {
            let n = todoItems.count
            var swapCounter = 1
            while swapCounter != 0
            {
                swapCounter = 0
                for j in 0 ..< n-1
                {
                    if todoItems[j].title > todoItems[j+1].title
                    {
                        let temp = todoItems[j]
                        todoItems[j] = todoItems[j+1]
                        todoItems[j+1] = temp
                        
                        swapCounter = swapCounter + 1
                    }
                }
            }
        } else {
            let n = todoItems.count
            var swapCounter = 1
            while swapCounter != 0
            {
                swapCounter = 0
                for j in 0 ..< n-1
                {
                    if todoItems[j].title < todoItems[j+1].title
                    {
                        let temp = todoItems[j]
                        todoItems[j] = todoItems[j+1]
                        todoItems[j+1] = temp
                        
                        swapCounter = swapCounter + 1
                    }
                }
            }
        }
        
        tableView.reloadData()
        sortAZ = !sortAZ
    }
}











































