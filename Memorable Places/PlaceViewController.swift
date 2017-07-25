//
//  PlaceViewController.swift
//  Memorable Places
//
//  Created by Johan Nilsson on 2017/07/20.
//  Copyright © 2017 Johan Nilsson. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class PlaceViewController: UIViewController, CLLocationManagerDelegate {

    var container: NSPersistentContainer? = AppDelegate.persistentContainer // NOTE - using conviniance method
    
    var mapViewMode: ViewMode = .add
    var displayPlace: Place?
    var locationManager = CLLocationManager()
    var addingPlace = false
    
    @IBOutlet weak var map: MKMapView!
    
    @IBAction func longPress(_ sender: UILongPressGestureRecognizer) {
        print("Pressed for a long time")
        // to avoid multiple events, you should use --> 
        //    --> if sender.state == UIGestureRecognizerState.began {
        if self.mapViewMode == .add && !addingPlace {
            addingPlace = true
            let point = sender.location(in: map)
            print("x: \(point.x) y: \(point.y)")
            let cooardinate = map.convert(point, toCoordinateFrom: map)
            let location = CLLocation(latitude: cooardinate.latitude, longitude: cooardinate.longitude)
            
            let annotation: MKPointAnnotation = MKPointAnnotation()
            annotation.coordinate = cooardinate
            map.addAnnotation(annotation)
            
            CLGeocoder().reverseGeocodeLocation(location , completionHandler: { (placemarks, error) in
                if error != nil {
                    print(error!)
                    self.addingPlace = false
                } else {
                    if let placemark = placemarks?[0] {
                        let subThoroughfare = placemark.subThoroughfare ?? ""
                        let thoroughfare = placemark.thoroughfare ?? ""
                        let subAdministrativeArea = placemark.subAdministrativeArea ?? ""
                        // let country = placemark.country ?? ""
                        // let postalCode = placemark.postalCode ?? ""
                        
                        let newPlace = UnmanagedPlace()
                        var newName = "Unknown Address"
                        if !thoroughfare.isEmpty {
                            if !subThoroughfare.isEmpty {
                                newName = subThoroughfare + " " + thoroughfare
                            } else {
                                newName = thoroughfare
                            }
                        } else if !subAdministrativeArea.isEmpty {
                            // TODO Prompt the user for a Name!
                            newName = subAdministrativeArea
                        }
                        newPlace.name = newName
                        newPlace.longitude = cooardinate.longitude
                        newPlace.latitude = cooardinate.latitude
                        
                        self.map.removeAnnotation(annotation)
                        
                        self.showOnMap(place: newPlace)
                        self.saveNewPlace(newPlace)
                        self.addingPlace = false
                    }
                }
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print(mapViewMode)
        if mapViewMode == .show {
            if displayPlace != nil {
               showOnMap(place: displayPlace!)
            }
        } else {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation: CLLocation = locations[0] // Just use the first one
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        setRegionOnMap(latitude: latitude, longitude: longitude)
        // You dont need to repeatedly update the location --> stopUpdatingLocation
        locationManager.stopUpdatingLocation()
    }

    private func saveNewPlace(_ place: UnmanagedPlace) {
        container?.performBackgroundTask { [weak self] (context) in
            _ = try? Place.createPlace(place, in: context)
            try? context.save()
            self?.printDatabaseStatistics()
        }
    }
    
    private func printDatabaseStatistics() {
        // NOTE this need to hapen on the MAIN thread if using viewContext --> context.perform()
        if let context = container?.viewContext {
            context.perform {
                /*
                    // Not efficient
                    let request: NSFetchRequest<Place> = Place.fetchRequest()
                    if let placeCount = (try? context.fetch(request))?.count {
                        print("Number of Places in  the Database: \(placeCount)")
                    }
                */
                if let placeCountToo = (try? context.count(for: Place.fetchRequest())) {
                    print("Number of Places in  the Database: \(placeCountToo)")
                }
            }
        }
    }
    
    private func setRegionOnMap(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        print("setRegionOnMap --> lat: \(latitude) lon: \(longitude)")
        let latDelta: CLLocationDegrees = MapHelper.spanDelta
        let lonDelta: CLLocationDegrees = MapHelper.spanDelta
        let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        let locationCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region: MKCoordinateRegion = MKCoordinateRegion(center: locationCoordinate, span: span)
        map.setRegion(region, animated: true)
    }

    private func showOnMap(place: UnmanagedPlace) {
        let latitude: CLLocationDegrees = place.latitude
        let longitude: CLLocationDegrees = place.longitude
        setRegionOnMap(latitude: latitude, longitude: longitude)
        
        let annotation: MKPointAnnotation = MKPointAnnotation()
        annotation.title = place.name
        annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        map.addAnnotation(annotation)
    }
    
    private func showOnMap(place: Place) {
        let unmanagedPlace = UnmanagedPlace()
        unmanagedPlace.name = place.name ?? ""
        unmanagedPlace.latitude = place.latitude
        unmanagedPlace.longitude = place.longitude
        showOnMap(place: unmanagedPlace)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    enum ViewMode {
        case add
        case show
    }
}
