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
    
    var pins: [Pin] = []
    var isDeletingPings = false
    var dataController: DataController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            pins = result
            addPinsToMap()
        }
    }
    
    
    
    
    @IBAction func recognizeLongPress(_ sender: UILongPressGestureRecognizer) {
        // Do not generate pins many times during long press.
        if !isDeletingPings {
            if sender.state != UIGestureRecognizer.State.began {
                return
            }
            
            // Get the coordinates of the point you pressed long.
            let location = sender.location(in: mapView)
            
            // Convert location to CLLocationCoordinate2D.
            let myCoordinate: CLLocationCoordinate2D = mapView.convert(location, toCoordinateFrom: mapView)
            
            addPinToMap(myCoordinate)
        }
        
    }
    
    //MARK: - IBActions
    @IBAction func deletePinsAction(_ sender: UIBarButtonItem) {
        isDeletingPings = !isDeletingPings
        updateButtonDelete(isVisible: isDeletingPings)
        editButton.title = isDeletingPings ? "Done" : "Edit"
        deSelectAnnotations()
    }
    
    
    private func updateButtonDelete(isVisible: Bool){
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
    
    fileprivate func addPinToMap(_ myCoordinate: CLLocationCoordinate2D) {
        // Generate pins.
        let myPin: MKPointAnnotation = MKPointAnnotation()
        
        // Set the coordinates.
        myPin.coordinate = myCoordinate
        
        // Added pins to MapView.
        mapView.addAnnotation(myPin)
        
        //Store pin in core data
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = myPin.coordinate.latitude
        pin.longitude = myPin.coordinate.longitude
        pin.creationDate = Date()
        try? dataController.viewContext.save()
    }
    
    fileprivate func addPinsToMap(){
        for pin in pins {
            let myCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D.init(latitude: pin.latitude, longitude: pin.longitude)
            addPinToMap(myCoordinate)
        }
    }
    
    private func deSelectAnnotations() {
        for annotation in mapView.selectedAnnotations {
            mapView.deselectAnnotation(annotation, animated: false)
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    
    // Delegate method called when addAnnotation is done.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let myPinIdentifier = "PinAnnotationIdentifier"
        
        // Generate pins.
        let myPinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: myPinIdentifier)
        
        // Add animation.
        myPinView.animatesDrop = true
        
        // Display callouts.
        myPinView.canShowCallout = false
        
        // Set annotation.
        myPinView.annotation = annotation
        
        print("latitude: \(annotation.coordinate.latitude), longitude: \(annotation.coordinate.longitude)")
        
        return myPinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if isDeletingPings {
            if let annotation = view.annotation {
                mapView.removeAnnotation(annotation)
            }
        }else {
            print("selected: \(String(describing: view.annotation?.coordinate))")
        }
    }
}
