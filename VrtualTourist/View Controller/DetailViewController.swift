//
//  DetailViewController.swift
//  VrtualTourist
//
//  Created by Segnonna Hounsou on 12/04/2022.
//

import Foundation
import UIKit
import MapKit
import CoreData

class DetailViewController: MapViewController, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var loader: UIActivityIndicatorView!
    @IBOutlet var button: UIButton!
    @IBOutlet var labelEmptyList: UILabel!
    var coordinate:CLLocationCoordinate2D!
    var dataController: DataController!
    
    var list: [Photo]!
    var fetchedResultController: NSFetchedResultsController<LocationImage>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchPinLocationByCoordinates()
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        mapView.centerCoordinate = coordinate
        setUpView(true)
        loader.startAnimating()
        
        let width = (view.frame.width-20)/3
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: width, height: width)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultController = nil
    }
    
    fileprivate func fetchPinLocationByCoordinates() {
        let fetchPinLocationRequest: NSFetchRequest<PinLocation> = PinLocation.fetchRequest()
        let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", String(coordinate.latitude), String(coordinate.longitude))
        fetchPinLocationRequest.predicate = predicate
        let sortDescriptor =  NSSortDescriptor(key: "latitude", ascending: false)
        fetchPinLocationRequest.sortDescriptors = [sortDescriptor]
        
        do {
            guard let pinLocation = try dataController.backgroundContext.fetch(fetchPinLocationRequest).first else {
                return
            }
            fetchImageFromLocal(pinLocation)
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func setDelegates() {
        self.collectionView.reloadData()
    }
    
    fileprivate func fetchImageFromLocal(_ pinLocations: PinLocation) {
        print("fetchImageFromLocal")
        let fetchRequest: NSFetchRequest<LocationImage> = LocationImage.fetchRequest()
        let predicate = NSPredicate(format: "pinlocation == %@", pinLocations)
        fetchRequest.predicate = predicate
        let sortDescriptor =  NSSortDescriptor(key: "id", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContex, sectionNameKeyPath: nil, cacheName: "locationsimage")
        fetchedResultController.delegate = self
        
        do{
            try fetchedResultController.performFetch()
        }catch {
            fatalError("The fetch could not be perfomed: \(error.localizedDescription)")
        }
    }
    
    
    fileprivate func addPhotoToLocal(_ pinLocations: PinLocation, _ listPhotos: [Photo]?, _ bgContext: NSManagedObjectContext?) {
        listPhotos?.forEach({ photo_ in
            
            bgContext?.perform {
                let image = LocationImage(context: bgContext!)
                image.id = photo_.id
                image.secret = photo_.secret
                image.server = photo_.server
                image.pinlocation = pinLocations
                try? bgContext!.save()
            }
            
        })
    }
    
    fileprivate func loadImages(_ pinLocations: PinLocation) {
        VirtualTouristClient.loadImagesByLocation(latitude: coordinate.latitude, longitude: coordinate.longitude) { listPhotos, error in
            let bgContext:NSManagedObjectContext! = self.dataController?.backgroundContext
            self.setUpView(false)
            self.setDelegates()
            self.list = listPhotos
            self.addPhotoToLocal(pinLocations, listPhotos, bgContext)
        }
    }
    
    @IBAction func fetchImage(_ sender: Any) {
    }
    
    private func setUpView( _ isLoading: Bool){
        loader.isHidden = !isLoading
        collectionView.isHidden = isLoading
        button.isEnabled = !isLoading
        
        if isLoading {
            loader.startAnimating()
        } else {
            loader.stopAnimating()
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
       return fetchedResultController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let anImage = fetchedResultController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        
        cell.imageView?.loadImageUsingCache(withUrl: VirtualTouristClient.Endpoints.urlImage(anImage.server ?? "", anImage.id ?? "", anImage.secret ?? "").stringValue)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //let anImage = fetchedResultController.object(at: indexPath)
        //let detailController = storyboard?.instantiateViewController(withIdentifier: "CollectionViewCell") as! CollectionViewCell
        // detailController.memeImage = self.memes[indexPath.row].memedImage
        //  navigationController?.pushViewController(detailController, animated: true)
    }
    
}

extension DetailViewController {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
           switch type {
           case .insert:
               collectionView.insertItems(at: [newIndexPath!])
               break
           case .delete:
               collectionView.deleteItems(at: [indexPath!])
               break
           case .update:
               collectionView.reloadItems(at: [indexPath!])
               break
           case .move:
               collectionView.moveItem(at: indexPath!, to: newIndexPath!)
           default:
               break
           }
       }

       func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
           
           let indexSet = IndexSet(integer: sectionIndex)
           
           switch type {
           case .insert:
               collectionView.insertSections(indexSet)
               break
           case .delete:
               collectionView.deleteSections(indexSet)
               break
           default:
               break
           }
       }
}

let imageCache = NSCache<NSString, UIImage>()
extension UIImageView {
    func loadImageUsingCache(withUrl urlString : String) {
        let url = URL(string: urlString)
        if url == nil {return}
        self.image = nil
        
        // check cached image
        if let cachedImage = imageCache.object(forKey: urlString as NSString)  {
            self.image = cachedImage
            return
        }
        
        let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView.init(style: .gray)
        addSubview(activityIndicator)
        activityIndicator.startAnimating()
        activityIndicator.center = self.center
        
        // if not, download image from url
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            if error != nil {
                print(error!)
                activityIndicator.removeFromSuperview()
                return
            }
            
            DispatchQueue.main.async {
                if let image = UIImage(data: data!) {
                    imageCache.setObject(image, forKey: urlString as NSString)
                    self.image = image
                    activityIndicator.removeFromSuperview()
                }
            }
            
        }).resume()
    }
}

