//
//  PickupVC.swift
//  htchhkr
//
//  Created by Aris Doxakis on 10/1/18.
//  Copyright © 2018 DASoftware. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import FirebaseAuth

class PickupVC: UIViewController {

    var pickupCoordinate: CLLocationCoordinate2D!
    var passengerKey: String!
    var locationPlacemark: MKPlacemark!
    
    var regionRadius: CLLocationDistance = 2000
    var pin: MKPlacemark? = nil
    
    @IBOutlet weak var pickupMApView: RoundMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickupMApView.delegate = self
        
        locationPlacemark = MKPlacemark(coordinate: pickupCoordinate)
        dropPinForPlaceMark(placemark: locationPlacemark)
        centerMapOnLocation(location: locationPlacemark.location!)
        
        DataService.instance.REF_TRIPS.child(self.passengerKey).observe(.value, with: { (tripSnapshot) in
            if tripSnapshot.exists() {
                if tripSnapshot.childSnapshot(forPath: TRIP_IS_ACCEPTED).value as? Bool == true {
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        })
    }

    func initData(coordinate: CLLocationCoordinate2D, passengerKey: String) {
        self.pickupCoordinate = coordinate
        self.passengerKey = passengerKey
    }
    
    @IBAction func canceButtonClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func acceptTripClicked(_ sender: Any) {
        UpdateSerice.instance.acceptTrip(withPassengerKey: passengerKey, forDriverKey: (Auth.auth().currentUser?.uid)!)
        presentingViewController?.shouldPresentLoadingView(true)
    }
    
}

extension PickupVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "pickupPoint"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        } else {
            annotationView?.annotation = annotation
        }
        annotationView?.image = UIImage(named: "destinationAnnotation")
        
        return annotationView
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius, regionRadius)
        pickupMApView.setRegion(coordinateRegion, animated: true)
    }
    
    func dropPinForPlaceMark(placemark: MKPlacemark) {
        pin = placemark
        
        for annotation in self.pickupMApView.annotations {
            self.pickupMApView.removeAnnotation(annotation)
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        
        pickupMApView.addAnnotation(annotation)
    }
}
