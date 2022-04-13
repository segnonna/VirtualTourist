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

class DetailViewController: MapViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var loader: UIActivityIndicatorView!
    @IBOutlet var button: UIButton!
    @IBOutlet var labelEmptyList: UILabel!
    var coordinate:CLLocationCoordinate2D!
    var dataController: DataController!
    var pinLocation: PinLocation!
    
    private var list: [Photo]!
    private var fetchedResultController: NSFetchedResultsController<LocationImage>!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        labelEmptyList.isHidden = true
        self.navigationController?.navigationBar.isHidden = false
    }
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
    
    
    
    
    @IBAction func fetchImage(_ sender: Any) {
        setUpView(true)
        removeAllPhotos {
            self.loadImagesFromRemote()
        }
    }
    
    
    
    private func requestImageFromLocal() -> NSFetchRequest<LocationImage>{
        let fetchRequest: NSFetchRequest<LocationImage> = LocationImage.fetchRequest()
        let predicate = NSPredicate(format: "pinlocation == %@", pinLocation)
        fetchRequest.predicate = predicate
        let sortDescriptor =  NSSortDescriptor(key: "id", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        return fetchRequest
    }
    
    fileprivate func setupFetchedResultsController() {
        fetchedResultController = NSFetchedResultsController(
            fetchRequest: requestImageFromLocal(),
            managedObjectContext: dataController.viewContex,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultController.delegate = self
        do {
            try fetchedResultController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func addPhotoToLocal(_ listPhotos: [Photo]?, _ bgContext: NSManagedObjectContext?) {
        listPhotos?.forEach({ photo_ in
            
            bgContext?.perform {
                let image = LocationImage(context: bgContext!)
                image.id = photo_.id
                image.secret = photo_.secret
                image.server = photo_.server
                image.pinlocation = self.pinLocation
                try? bgContext!.save()
            }
            
        })
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
        let aLocationImage = fetchedResultController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        if aLocationImage.imageData == nil {
        VirtualTouristClient.loadPhoto(aLocationImage) { data, error in
            guard error == nil else {
                return
            }
            aLocationImage.imageData = data
            cell.imageView?.image = UIImage(data: data!)
            try? self.dataController.backgroundContext.save()
        }
        }
        else {
            cell.imageView?.image = UIImage(data: aLocationImage.imageData!)
        }
        
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let aLocationImage = fetchedResultController.object(at: indexPath)
        showAlertForImageDeletion(aLocationImage)
    }
    
    
    fileprivate func showAlertForImageDeletion(_ aLocationImage : LocationImage) {
        let alertVC = UIAlertController(title: "", message: "Do you want to delete this photo?", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [self](alert: UIAlertAction!) in
            dataController.viewContex.delete(aLocationImage)
            try? dataController.viewContex.save()
        }))
        alertVC.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showEmptyListLabel(_ show: Bool) {
        self.collectionView.isHidden = show
        self.labelEmptyList.isHidden = !show
    }
    
    fileprivate func loadImagesFromRemote() {
        debugPrint("loadImagesFromRemote")
        VirtualTouristClient.loadImagesByLocation(latitude: coordinate.latitude, longitude: coordinate.longitude) { listPhotos, error in
            let bgContext:NSManagedObjectContext! = self.dataController?.backgroundContext
            self.setUpView(false)
            if listPhotos?.isEmpty ?? false {
                self.showEmptyListLabel(true)
            } else {
                self.showEmptyListLabel(false)
                self.list = listPhotos
                self.addPhotoToLocal(listPhotos, bgContext)
            }
        }
    }
    
    fileprivate func removeAllPhotos(completion: @escaping () -> Void) {
        debugPrint("removeAllPhotos")
        for photo in fetchedResultController.fetchedObjects! {
            dataController.viewContex.delete(photo)
            do {
                try dataController.viewContex.save()
            } catch {
                print(error)
            }
        }
        completion()
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
    
    fileprivate func fetchPinLocationByCoordinates() {
        debugPrint("fetchPinLocationByCoordinates")
        let fetchPinLocationRequest: NSFetchRequest<PinLocation> = PinLocation.fetchRequest()
        let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", String(coordinate.latitude), String(coordinate.longitude))
        fetchPinLocationRequest.predicate = predicate
        let sortDescriptor =  NSSortDescriptor(key: "latitude", ascending: false)
        fetchPinLocationRequest.sortDescriptors = [sortDescriptor]
        
        do {
            guard let pinLocation = try dataController.backgroundContext.fetch(fetchPinLocationRequest).first else {
                return
            }
            self.pinLocation = pinLocation
            fetchImageFromLocal()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func fetchImageFromLocal() {
        debugPrint("fetchImageFromLocal:\(pinLocation.longitude) \(pinLocation.latitude)")
        do {
            setupFetchedResultsController()
            let locationImages = try dataController.backgroundContext.fetch(requestImageFromLocal())
            
            if locationImages.isEmpty {
                loadImagesFromRemote()
            }
            else {
                DispatchQueue.main.async {
                    self.setUpView(false)
                }
                list = locationImages.map {
                    Photo(id: $0.id ?? "", secret: $0.secret ?? "", server: $0.server ?? ""  )
                }
            }
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        
    }
}
