//
//  PlacesTableViewController.swift
//  Memorable Places
//
//  Created by Johan Nilsson on 2017/07/20.
//  Copyright © 2017 Johan Nilsson. All rights reserved.
//

import UIKit
import CoreData

class PlacesTableViewController: UITableViewController {
    
    var container: NSPersistentContainer? = AppDelegate.persistentContainer // NOTE - using conviniance method
    private var places: [Place] = []
    private var currentlySelectedPlace: Place?
    
    @IBOutlet var placeTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getAllPlaces()
    }
    
    // MARK: - Data storage 
    
    private func getAllPlaces() {
        print("getting all places")
        // NOTE this need to hapen on the MAIN thread if using viewContext --> context.perform()
        if let context = container?.viewContext  {
            context.perform {
                let request: NSFetchRequest<Place> = Place.fetchRequest()
                if let placeArray = try? context.fetch(request) {
                    self.places = placeArray
                    self.placeTableView.reloadData()
                    self.printDatabaseStatistics()
                }
            }
        }
    }
    
    private func deletePlace(place: Place) {
        print("delete")
        // NOTE this need to hapen on the MAIN thread if using viewContext --> context.perform()
        if let context = container?.viewContext  {
            context.perform {
                context.delete(place)
                try? context.save() // NOTE - no save, no permanent delete
            }
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return places.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "placeCell", for: indexPath)

        cell.textLabel?.text = places[indexPath.row].name
        let lat = places[indexPath.row].latitude
        let lon = places[indexPath.row].longitude
        cell.detailTextLabel?.text = "(\(String(format: "%.03f", lat)), \(String(format: "%.03f",lon)))"

        return cell
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        self.currentlySelectedPlace = places[indexPath.row]
        // print("willSelect \(self.currentlySelectedPlace?.name ?? "")")
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.currentlySelectedPlace = places[indexPath.row]
        // print("didSelect \(self.currentlySelectedPlace?.name ?? "")")
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source FIRST
            // TODO
            let placeToDeleteFromDatabase = places.remove(at: indexPath.row)
            deletePlace(place: placeToDeleteFromDatabase)
            tableView.deleteRows(at: [indexPath], with: .fade)

        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let placeViewController = segue.destination as? PlaceViewController {
            placeViewController.container = container // use the same container - the default would work just fine in this case
            if let identifier = segue.identifier {
                switch identifier {
                case "addPlace":
                    placeViewController.mapViewMode = .add
                    placeViewController.displayPlace = nil
                case "showPlace":
                    placeViewController.mapViewMode = .show
                    placeViewController.displayPlace = currentlySelectedPlace
                default:
                    print("unknown identifier")
                    break
                }
                
            }
            
        }
    }
    
    private func printDatabaseStatistics() {
        // NOTE this need to hapen on the MAIN thread if using viewContext --> context.perform()
        if let context = container?.viewContext {
            context.perform {
                if let placeCountToo = (try? context.count(for: Place.fetchRequest())) {
                    print("Number of Places in  the Database: \(placeCountToo)")
                }
            }
        }
    }

}
