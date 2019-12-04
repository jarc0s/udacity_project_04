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
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            addPinsToMap(pins: result)
        }
        
        //updateZoomRegion()
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
        if segue.identifier == "segueToPhotoAlbum" {
            if let photoAlbumViewController = segue.destination as? PhotoAlbumViewController, let pin = sender as? Pin {
                photoAlbumViewController.pinModel = pin
                photoAlbumViewController.dataController = dataController
            }
        }
    }
    
    private func updateButtonDelete(isVisible: Bool){
        editButton.title = isDeletingPings ? "Done" : "Edit"
        self.animateButton(heightConstraint: isVisible ? 60 : 0)
    }
    
    private func animateButton(heightConstraint: CGFloat) {
        DispatchQueue.main.async {
            self.labelDeleteHeightConstraint.constant = heightConstraint
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func addPinToMap(pinModel: Pin) {
        
        let myCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D.init(latitude: pinModel.latitude, longitude: pinModel.longitude)
        
        let virtualTourPin: VirtualTourPointAnnotation = VirtualTourPointAnnotation(pinModel: pinModel)
        
        virtualTourPin.coordinate = myCoordinate
        
        mapView.addAnnotation(virtualTourPin)
    }
    
    private func addPinsToMap(pins:[Pin] ){
        for pin in pins {
            addPinToMap(pinModel: pin)
        }
    }
    
    private func deSelectAnnotations() {
        for annotation in mapView.selectedAnnotations {
            mapView.deselectAnnotation(annotation, animated: false)
        }
    }
    
//    private func updateZoomRegion() {
//        if let centerLatitude = UserDefaults.standard.value(forKey: "centerLatitude") as? Double, let centerLongitude = UserDefaults.standard.value(forKey: "centerLongitude") as? Double, let zoomRegion = UserDefaults.standard.value(forKey: "zoomRegion") as? Double {
//            mapView.zoomAndCenter(on: CLLocationCoordinate2D.init(latitude: centerLatitude, longitude: centerLongitude),
//                                  zoom: zoomRegion/100.0)
//        }
//    }
//
//    private func storeCurrentRegion() {
//
//        UserDefaults.standard.set(mapView.centerCoordinate.latitude, forKey: "centerLatitude")
//        UserDefaults.standard.set(mapView.centerCoordinate.longitude, forKey: "centerLongitude")
//        UserDefaults.standard.set(mapView.getZoom(), forKey:"zoomRegion")
//    }
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
