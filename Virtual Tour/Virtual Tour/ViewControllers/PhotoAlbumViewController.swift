//
//  PhotoAlbumViewController.swift
//  Virtual Tour
//
//  Created by Juan Arcos on 12/4/19.
//  Copyright © 2019 Arcos. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var pinModel: Pin!
    var dataController: DataController!
    var resource: [Photo] = [Photo]()

    
    private let itemsPerRow: CGFloat = 3
    private let reuseIdentifier = "PhotoCell"
    private let sectionInsets = UIEdgeInsets(top: 10.0,
                                             left: 11.0,
                                             bottom: 10.0,
                                             right: 11.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setRegionMapView()
        searchForPhotos()
        //getPhotoPages()
        getPhotosUrls()
    }
    
    @IBAction func loadNewCollection(_ sender: UIButton) {
        //Delete all photos
        deleteAllPhoto()
        getPhotosUrls()
    }
    
    
    private func setRegionMapView(){
        let center = CLLocationCoordinate2D(latitude: pinModel.latitude, longitude: pinModel.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        
        mapView.setRegion(region, animated: true)
        mapView.isUserInteractionEnabled = false
        addPinToMap()
    }
    
    private func addPinToMap() {
        
        let myCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D.init(latitude: pinModel.latitude, longitude: pinModel.longitude)
        
        let virtualTourPin: VirtualTourPointAnnotation = VirtualTourPointAnnotation(pinModel: pinModel)
        
        virtualTourPin.coordinate = myCoordinate
        
        mapView.addAnnotation(virtualTourPin)
    }
    
    private func searchForPhotos(){
        let searchParams = SearchParams(lat: pinModel.latitude, lon: pinModel.longitude, radius: 5, format: "json", nojsoncallback: "1", per_page: 21)
        VTClient.getSearchPhotos(params: searchParams, completion: handleSearchResponse(phostosResult:error:))
    }
    
    func handleSearchResponse(phostosResult: PhotosResult?, error: Error?){
        if let result = phostosResult {
            print(result.photo.count)
            if Int(result.total) != 0 {
                self.storePhotosOnPinLocation(result: result)
            }
        }else {
            print("error: \(error?.localizedDescription ?? "")")
        }
    }
    
    fileprivate func storePhotoPage(_ result: PhotosResult) {
        let photoPage = PhotoPage(context: dataController.viewContext)
        photoPage.page = Int64(result.page)
        photoPage.pages = Int64(result.pages)
        photoPage.perPage = Int64(result.perpage)
        photoPage.total = Int64(result.total) ?? 0
        photoPage.pin = pinModel
        try? dataController.viewContext.save()
    }
    
    fileprivate func storePhotos(_ result: PhotosResult) {
        
        for photo in result.photo {
            let photoModel = Photo(context: dataController.viewContext)
            photoModel.creationDate = Date()
            photoModel.url = "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret)_c.jpg"
            photoModel.pin = pinModel
            try? dataController.viewContext.save()
        }
        
        resource = getPhotosUrls()
        self.collectionView?.reloadData()
    }
    
    func storePhotosOnPinLocation(result: PhotosResult) {
        
        storePhotoPage(result)
        storePhotos(result)
    }
    
    
    func getPhotoPages(){
        let fetchRequest: NSFetchRequest<PhotoPage> = PhotoPage.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pinModel)
        fetchRequest.predicate = predicate
        do {
            let commits = try dataController.viewContext.fetch(fetchRequest)
            print("Pages: \(commits.last?.pages ?? 0)")
        } catch {
            print("PhotoPage Fetch failed")
        }
    }
    
    func getPhotosUrls() -> [Photo] {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pinModel)
        fetchRequest.predicate = predicate
        do {
            let commits = try dataController.viewContext.fetch(fetchRequest)
            print("URL: \(commits.last?.url ?? "NO URL")")
            return commits
        } catch {
            print("PhotoPage Fetch failed")
        }
        return [Photo]()
    }
    
    func deleteAllPhoto() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pinModel)
        fetchRequest.predicate = predicate
        do {
            let photos = try dataController.viewContext.fetch(fetchRequest)
            for photo in photos {
                dataController.viewContext.delete(photo)
            }
            try? dataController.viewContext.save()
        } catch {
            print("PhotoPage Fetch failed")
        }
    }
    
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    // Delegate method called when addAnnotation is done.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let myPinIdentifier = "PinAnnotationIdentifier"
        
        let myPinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: myPinIdentifier)
        
        myPinView.animatesDrop = false
        
        myPinView.canShowCallout = false
        
        myPinView.annotation = annotation
        
        return myPinView
    }

}

extension PhotoAlbumViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photo = resource[indexPath.row]
        
    }
}


extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return resource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: reuseIdentifier, for: indexPath) as? PhotoCollectionViewCell
            else {
                preconditionFailure("Invalid cell type")
        }
        
        let photo = resource[indexPath.row]
        
        // 1
        cell.activityIndicator.stopAnimating()
        cell.contentLoader.isHidden = true
        
        // 2
        if let imagePhoto = photo.imageData {
            cell.imageView.image = UIImage(data: imagePhoto)
            return cell
        }
        
        // 3
        performLargeImageFetch(photo: photo, cell: cell)
        
        
        // Configure the cell
        return cell
    }
    
    fileprivate func performLargeImageFetch(photo: Photo, cell: PhotoCollectionViewCell){
        
        cell.activityIndicator.startAnimating()
        cell.contentLoader.isHidden = false
        
        loadLargeImage(photo: photo) { [weak self] result in 
            cell.activityIndicator.stopAnimating()
            cell.contentLoader.isHidden = true
            
            switch result {
            case .results(let photo):
                cell.imageView.image = photo
                return
            case .error(_), .success(_):
                cell.imageView.image = UIImage(named: "")
                return
            }
            
        }
        
    }
    
    
    func loadLargeImage(photo: Photo, completion: @escaping (Result<UIImage>) -> Void) {
        
        guard let urlPhotoStr = photo.url, let urlPhoto = URL(string: urlPhotoStr) else {
            DispatchQueue.main.async {
                completion(Result.success(false))
            }

            return
        }
        
        let loadRequest = URLRequest(url:urlPhoto)
        
        URLSession.shared.dataTask(with: loadRequest) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    completion(Result.error(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(Result.success(false))
                }
                return
            }
            
            guard let returnedImage = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(Result.success(false))
                }
                return
            }
            
            photo.imageData = data
            DispatchQueue.main.async {
                completion(Result.results(returnedImage))
            }
            try? self.dataController.viewContext.save()
            
            }.resume()
    }
    
}

extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
    //1
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        //2
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    //3
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    // 4
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}
