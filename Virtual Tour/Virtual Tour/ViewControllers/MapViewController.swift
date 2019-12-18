//
//  MapViewController.swift
//  Virtual Tour
//
//  Created by Juan Arcos on 12/3/19.
//  Copyright © 2019 Arcos. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var labelDeleteHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var isDeletingPings = false
    var dataController: DataController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getCurrentLocations()
        //updateZoomRegion()
    }
    
    
    fileprivate func getCurrentLocations() {
        guard let result = DataSource.retrieve(entityClass: Pin.self, context: dataController.viewContext) else {
            return
        }
        
        addPinsToMap(pins: result)
    }
    
    
    @IBAction func recognizeLongPress(_ sender: UILongPressGestureRecognizer) {
        // Do not generate pins many times during long press.
        if !isDeletingPings {
            if sender.state != UIGestureRecognizer.State.began {
                return
            }
            
            let location = sender.location(in: mapView)
            
            let myCoordinate: CLLocationCoordinate2D = mapView.convert(location, toCoordinateFrom: mapView)
            
            let pin = Pin(context: dataController.viewContext)
            pin.latitude = myCoordinate.latitude
            pin.longitude = myCoordinate.longitude
            pin.creationDate = Date()
            try? dataController.viewContext.save()
            
            //Ask for photos in that place
            getPhotosForPlace(pinModel: pin)
            
            addPinToMap(pinModel: pin)
        }
        
    }
    
    //MARK: - IBActions
    @IBAction func deletePinsAction(_ sender: UIBarButtonItem) {
        isDeletingPings = !isDeletingPings
        updateButtonDelete(isVisible: isDeletingPings)
        
        deSelectAnnotations()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        deSelectAnnotations()
        if segue.identifier == "segueToPhotoAlbum" {
            if let photoAlbumViewController = segue.destination as? PhotoAlbumViewController, let pin = sender as? Pin {
                photoAlbumViewController.pinModel = pin
                photoAlbumViewController.dataController = dataController
            }
        }
    }
    
    fileprivate func updateButtonDelete(isVisible: Bool){
        editButton.title = isDeletingPings ? "Done" : "Edit"
        self.animateButton(heightConstraint: isVisible ? 60 : 0)
    }
    
    fileprivate func animateButton(heightConstraint: CGFloat) {
        DispatchQueue.main.async {
            self.labelDeleteHeightConstraint.constant = heightConstraint
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    fileprivate func addPinToMap(pinModel: Pin) {
        
        let myCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D.init(latitude: pinModel.latitude, longitude: pinModel.longitude)
        
        let virtualTourPin: VirtualTourPointAnnotation = VirtualTourPointAnnotation(pinModel: pinModel)
        
        virtualTourPin.coordinate = myCoordinate
        
        mapView.addAnnotation(virtualTourPin)
        
    }
    
    fileprivate func addPinsToMap(pins:[Pin] ){
        for pin in pins {
            addPinToMap(pinModel: pin)
        }
    }
    
    fileprivate func deSelectAnnotations() {
        for annotation in mapView.selectedAnnotations {
            mapView.deselectAnnotation(annotation, animated: false)
        }
    }
    
    fileprivate func getPhotosForPlace(pinModel: Pin) {
        let searchParams = SearchParams(lat: pinModel.latitude, lon: pinModel.longitude, radius: 5, format: "json", nojsoncallback: "1", per_page: 21, page: 1)
        VTClient.getSearchPhotos(params: searchParams, pinModel: pinModel, completion: handleSearchResponse(phostosResult:error:pinModel:))
    }
    
    
    fileprivate func handleSearchResponse(phostosResult: PhotosResult?, error: Error?, pinModel: Pin){
        if let result = phostosResult {
            if Int(result.total) != 0 {
                self.storePhotosOnPinLocation(result: result, pinModel: pinModel)
            }
        }else {
            print("error: \(error?.localizedDescription ?? "")")
        }
    }
    
    fileprivate func storePhotosOnPinLocation(result: PhotosResult, pinModel: Pin) {
        
        storePhotoPage(result, pinModel: pinModel)
        storePhotos(result, pinModel: pinModel)
    }
    
    fileprivate func storePhotoPage(_ result: PhotosResult, pinModel: Pin) {
        let photoPage = PhotoPage(context: dataController.viewContext)
        photoPage.page = Int64(result.page)
        photoPage.pages = Int64(result.pages)
        photoPage.perPage = Int64(result.perpage)
        photoPage.total = Int64(result.total) ?? 0
        photoPage.pin = pinModel
        try? dataController.viewContext.save()
    }
    
    fileprivate func storePhotos(_ result: PhotosResult, pinModel: Pin) {
        
        for photo in result.photo {
            let photoModel = Photo(context: dataController.viewContext)
            photoModel.creationDate = Date()
            photoModel.url = "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret)_c.jpg"
            photoModel.pin = pinModel
            try? dataController.viewContext.save()
        }
        
    }
    
}

extension MapViewController: MKMapViewDelegate {
    
    // Delegate method called when addAnnotation is done.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let myPinIdentifier = "PinAnnotationIdentifier"
        
        let myPinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: myPinIdentifier)
        
        myPinView.animatesDrop = true
        
        myPinView.canShowCallout = false
        
        myPinView.annotation = annotation
        
        return myPinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if let annotation = view.annotation as? VirtualTourPointAnnotation, let pinToDelete = annotation.pinModel {
            if isDeletingPings {
                mapView.removeAnnotation(annotation)
                dataController.viewContext.delete(pinToDelete)
                try? dataController.viewContext.save()
            }else {
                performSegue(withIdentifier: "segueToPhotoAlbum", sender: pinToDelete)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        //storeCurrentRegion()
    }
}
