//
//  ViewController.swift
//  VrtualTourist
//
//  Created by Segnonna Hounsou on 12/04/2022.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: MapViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet var mapView: MKMapView!
    var dataController: DataController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(addPoint(longGesture:)))
        mapView.addGestureRecognizer(longGesture)
        loadMyRegion()
    }
    
    fileprivate func fetchPinLocation() {
        let fetchRequest: NSFetchRequest<PinLocation> = PinLocation.fetchRequest()
        
        do {
            let pinLocations = try dataController.backgroundContext.fetch(fetchRequest)

            pinLocations.forEach { pinLocation in
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: pinLocation.latitude, longitude: pinLocation.longitude)
                annotation.title = "\(pinLocation.latitude), \(pinLocation.longitude)"
                mapView.addAnnotation(annotation)
            }
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func addPinLocationToLocalStorage(latitude: Double, longitude: Double) {
        let backgroundContext:NSManagedObjectContext! = dataController?.backgroundContext
        
        backgroundContext.perform {
            let pinLocation = PinLocation(context: backgroundContext)
            pinLocation.latitude = latitude
            pinLocation.longitude = longitude
            try? backgroundContext.save()
        }
    }
    
    @objc private func addPoint(longGesture: UIGestureRecognizer) {
        if longGesture.state == .ended {
            let touchPoint = longGesture.location(in: mapView)
            let wayCoords = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = wayCoords
            annotation.title = "\(wayCoords.latitude), \(wayCoords.longitude)"
            mapView.addAnnotation(annotation)
            
            dataController?.backgroundContext.perform {
                self.addPinLocationToLocalStorage(latitude: wayCoords.latitude, longitude: wayCoords.longitude)
            }
        }
    }
    
    func saveMyRegion(_ region: MKCoordinateRegion) {
        UserDefaults.standard.set(region.center.longitude, forKey: Constants.myLongitude)
        UserDefaults.standard.set(region.center.latitude, forKey: Constants.myLatitude)
        UserDefaults.standard.set(region.span.longitudeDelta, forKey: Constants.myLongitudeDelta)
        UserDefaults.standard.set(region.span.latitudeDelta, forKey: Constants.myLatitudeDelta)
    }
    
    func loadMyRegion() {
        let regionCenterLongitude = UserDefaults.standard.double(forKey: Constants.myLongitude)
        let regionCenterLatitude = UserDefaults.standard.double(forKey: Constants.myLatitude)
        let regionSpanLongitude = UserDefaults.standard.double(forKey: Constants.myLongitudeDelta)
        let regionSpanLatitude = UserDefaults.standard.double(forKey: Constants.myLatitudeDelta)
        
        guard regionCenterLongitude != 0, regionCenterLatitude != 0, regionSpanLongitude != 0, regionSpanLatitude != 0 else {
            return
        }
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: regionCenterLatitude, longitude: regionCenterLongitude),
            span: MKCoordinateSpan(latitudeDelta: regionSpanLatitude, longitudeDelta: regionSpanLongitude)
        )
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
        fetchPinLocation()
    }
}

extension TravelLocationsMapViewController {
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let storyboard = UIStoryboard (name: "Main", bundle: nil)
        let resultVC = storyboard.instantiateViewController(withIdentifier: "DetailViewController")as! DetailViewController
    
        resultVC.coordinate = view.annotation?.coordinate
        resultVC.dataController = dataController
        self.navigationController?.pushViewController(resultVC, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMyRegion(mapView.region)
    }
}
