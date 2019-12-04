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
    
    var pinModel: Pin!
    var dataController: DataController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setRegionMapView()
    }
    
    @IBAction func loadNewCollection(_ sender: UIButton) {
        
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
