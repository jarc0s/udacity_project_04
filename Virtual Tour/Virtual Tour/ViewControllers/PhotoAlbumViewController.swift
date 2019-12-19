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
    @IBOutlet weak var labelNoImages: UILabel!
    
    
    enum Mode {
        case view
        case select
    }
    
    
    var pinModel: Pin!
    var dataController: DataController!
    var resource: [Photo] = [Photo]()
    var cellsToDelete: [Photo] = [Photo]()
    
    
    var dictionarySeletedIndexPath: [IndexPath : Bool] = [:]
    var mMode: Mode = .view {
        didSet{
            switch mMode {
            case .view:
                newCollectionButton.setTitle("New Collection", for: .normal)
            case .select:
                newCollectionButton.setTitle("Remove Selected Pictures", for: .normal)
            }
        }
    }
    
    private let itemsPerRow: CGFloat = 3
    private let reuseIdentifier = "PhotoCell"
    private let sectionInsets = UIEdgeInsets(top: 10.0,
                                             left: 11.0,
                                             bottom: 10.0,
                                             right: 11.0)
    
    
    
    
    //MARK: - View Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setRegionMapView()
        resource = getPhotosUrls()
        if resource.isEmpty {
            collectionView.isHidden = true
            labelNoImages.isHidden = false
        }
        collectionView.allowsMultipleSelection = true
    }
    
    //MARK: - IBAction
    @IBAction func loadNewCollection(_ sender: UIButton) {
        switch mMode {
        case .view:
            updateCollectionViewState(isVisible: false)
            searchForPhotos()
        case .select:
            deleteSelectedPhotos()
        }
        
    }
    
    
    //MARK: - UICollection Actions
    fileprivate func updateCollectionViewState(isVisible: Bool) {
        collectionView.isHidden = !isVisible
        newCollectionButton.isEnabled = isVisible
    }
    
    fileprivate func updateDataCollectionView( result: PhotosResult) {
        deleteAllPhoto()
        storePhotoPage(result)
        storePhotos(result)
        resource = getPhotosUrls()
        collectionView.reloadData()
        updateCollectionViewState(isVisible: true)
    }
    
    //MARK: - MapView Actions
    fileprivate func setRegionMapView(){
        let center = CLLocationCoordinate2D(latitude: pinModel.latitude, longitude: pinModel.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        
        mapView.setRegion(region, animated: true)
        mapView.isUserInteractionEnabled = false
        addPinToMap()
    }
    
    fileprivate func addPinToMap() {
        
        let myCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D.init(latitude: pinModel.latitude, longitude: pinModel.longitude)
        
        let virtualTourPin: VirtualTourPointAnnotation = VirtualTourPointAnnotation(pinModel: pinModel)
        
        virtualTourPin.coordinate = myCoordinate
        
        mapView.addAnnotation(virtualTourPin)
    }
    
    
    //MARK: - API Actions
    fileprivate func searchForPhotos(){
        
        guard let photoPage = getPhotoPages() else {
            return
        }
        
        if photoPage.pages != 1 {
            let number = Int.random(in: 0 ... Int(photoPage.pages))
            
            if number != photoPage.pages {
                let searchParams = SearchParams(lat: pinModel.latitude, lon: pinModel.longitude, radius: 5, format: "json", nojsoncallback: "1", per_page: 21, page:number)
                VTClient.getSearchPhotos(params: searchParams, pinModel: pinModel, completion: handleSearchResponse(phostosResult:error:pinModel:))
            }else {
                print("No more photos")
            }
        }else {
            collectionView.isHidden = true
            labelNoImages.isHidden = false
        }
    }
    
    func handleSearchResponse(phostosResult: PhotosResult?, error: Error?, pinModel: Pin){
        if let result = phostosResult {
            if Int(result.total) != 0 {
                updateDataCollectionView(result: result)
            }
        }else {
            print("error: \(error?.localizedDescription ?? "")")
        }
    }
    
    //MARK: - CoreData Actions
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
            photoModel.url = "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret)_b.jpg"
            photoModel.pin = pinModel
            try? dataController.viewContext.save()
        }
        
        resource = getPhotosUrls()
        self.collectionView?.reloadData()
    }
    
    
    func getPhotoPages() -> PhotoPage?{
        
        let predicate = NSPredicate(format: "pin == %@", pinModel)
        guard let photoPage = DataSource.retrieve(entityClass: PhotoPage.self, context: dataController.viewContext, isAscending: true, predicate: predicate) else {
            return nil
        }
        return photoPage.last
    }
    
    func getPhotosUrls() -> [Photo] {
        
        let predicate = NSPredicate(format: "pin == %@", pinModel)
        guard let photos = DataSource.retrieve(entityClass: Photo.self, context: dataController.viewContext, isAscending: true, predicate: predicate) else {
            return []
        }
        
        return photos
    }
    
    func deleteAllPhoto() {

        let predicate = NSPredicate(format: "pin == %@", pinModel)
        guard let photos = DataSource.retrieve(entityClass: Photo.self, context: dataController.viewContext, isAscending: true, predicate: predicate) else {
            return
        }
        
        for photo in photos {
            dataController.viewContext.delete(photo)
        }
        try? dataController.viewContext.save()

    }
    
    //MARK: - Image
    fileprivate func performLargeImageFetch(photo: Photo, cell: PhotoCollectionViewCell){
        
        cell.activityIndicator.startAnimating()
        cell.contentLoader.isHidden = false
        
        VTClient.loadLargeImage(photo: photo) { result in
            cell.activityIndicator.stopAnimating()
            cell.contentLoader.isHidden = true
            
            switch result {
            case .results(let photoData):
                cell.imageView.image = UIImage(data: photoData)
                cell.imageView.isHidden = false
                photo.imageData = photoData
                try? self.dataController.viewContext.save()
                return
            case .error(_), .success(_):
                cell.imageView.image = UIImage(named: "")
                return
            }
            
        }
    }
    
    fileprivate func deleteSelectedPhotos() {
        var deleteNeededIndexPath: [IndexPath] = []
        for (key, value) in dictionarySeletedIndexPath {
            if value {
                deleteNeededIndexPath.append(key)
            }
        }
        
        for i in deleteNeededIndexPath.sorted(by: { $0.item > $1.item }) {
            let photoToDelete = resource[i.item]
            dataController.viewContext.delete(photoToDelete)
            try? dataController.viewContext.save()
            resource.remove(at: i.item)
        }
        
        collectionView.deleteItems(at: deleteNeededIndexPath)
        dictionarySeletedIndexPath.removeAll()
        mMode = .view
    }
    
    //MARK: - States
    fileprivate func updateButtonState() {
        var isItemSelected = false
        for (_ , value) in dictionarySeletedIndexPath {
            if value {
                isItemSelected = true
                break
            }
        }
        mMode = isItemSelected ? .select : .view
    }
}

//MARK: - MKMapViewDelegate

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

//MARK: - UICollectionViewDelegate

extension PhotoAlbumViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        mMode = .select
        dictionarySeletedIndexPath[indexPath] = true
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        dictionarySeletedIndexPath[indexPath] = false
        updateButtonState()
    }
}

//MARK: - UICollectionViewDataSource

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
        cell.imageView.isHidden = true
        // 2
        if let imagePhoto = photo.imageData {
            cell.imageView.image = UIImage(data: imagePhoto)
            cell.imageView.isHidden = false
            return cell
        }
        
        // 3
        performLargeImageFetch(photo: photo, cell: cell)
        
        
        // Configure the cell
        return cell
    }
}

//MARK: - UICollectionViewDelegateFlowLayout

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
