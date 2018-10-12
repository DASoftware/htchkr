//
//  ViewController.swift
//  htchhkr
//
//  Created by Aris Doxakis on 9/20/18.
//  Copyright © 2018 DASoftware. All rights reserved.
//

import UIKit
import MapKit
import RevealingSplashView
import CoreLocation
import Firebase

class HomeVC: UIViewController, Alertable {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var actionBtn: RoundedShadowButton!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var destinationCircle: CircleView!
    @IBOutlet weak var centerMapBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    
    var currentUserId: String?
    var selectedItemPlacemark: MKPlacemark? = nil
    var tableView = UITableView()
    var matchingItems: [MKMapItem] = [MKMapItem]()
    var route: MKRoute?
    
    var delegate: CenterVCDelegate?
    var manager: CLLocationManager?
    
    var regionRadius: CLLocationDistance = 1000
    
    var revealingSplashView = RevealingSplashView(iconImage: UIImage(named: "launchScreenIcon")!, iconInitialSize: CGSize(width: 80, height: 80), backgroundColor: UIColor.white)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentUserId = Auth.auth().currentUser?.uid
        
        destinationTextField.delegate = self
        manager?.delegate = self
        manager?.desiredAccuracy = kCLLocationAccuracyBest
        manager = CLLocationManager()
        checkLocationAuthStatus()
        mapView.delegate = self
        centerMapOnUserLocation()
        
        DataService.instance.REF_DRIVERS.observe(.value) { (snapshot) in
            self.loadDriverAnnotationsFromFB()
        }
        
        self.view.addSubview(revealingSplashView)
        revealingSplashView.animationType = SplashAnimationType.heartBeat
        revealingSplashView.startAnimation()
        
        revealingSplashView.heartAttack = true
        
        UpdateSerice.instance.observeTrips { (tripDict) in
            if let tripDict = tripDict {
                let pickUpCoordinateArray = tripDict["pickupCoordinate"] as! NSArray
                let tripKey = tripDict["passengerKey"] as! String
                let acceptanceStatus = tripDict["tripIsAccepted"] as! Bool
                
                if acceptanceStatus == false {
                    DataService.instance.driverIsAvailable(key: self.currentUserId!, handler: { (available) in
                        if let available = available {
                            if available {
                                let storyboard = UIStoryboard.init(name: "main", bundle: Bundle.main)
                                let pickupVC = storyboard.instantiateViewController(withIdentifier: "PickupVC") as? PickupVC
                                let coordinate = CLLocationCoordinate2D(latitude: pickUpCoordinateArray[0] as! CLLocationDegrees, longitude: pickUpCoordinateArray[1] as! CLLocationDegrees)
                                
                                pickupVC!.initData(coordinate: coordinate, passengerKey: tripKey)
                                self.present(pickupVC!, animated: true, completion: nil)
                            }
                        }
                    })
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DataService.instance.driverIsAvailable(key: self.currentUserId!, handler: { (isAvailable) in
            if !isAvailable! {
                DataService.instance.REF_TRIPS.observeSingleEvent(of: .value, with: { (tripSnapshot) in
                    if let tripSnapshot = tripSnapshot .children.allObjects as? [DataSnapshot] {
                        for trip in tripSnapshot {
                            if trip.childSnapshot(forPath: "driverKey").value as? String == self.currentUserId! {
                                let pickupCoordinateArray = trip.childSnapshot(forPath: "pickupCoordinate").value as! NSArray
                                let pickupCoordinate = CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees)
                                let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)
                                
                                self.dropPinFor(placemark: pickupPlacemark)
                                self.searchMapKitForResultsWithPolyline(forOriginMapItem: nil, withDestinationMapItem: MKMapItem(placemark: pickupPlacemark))
                            }
                        }
                    }
                })
            }
        })
        
        DataService.instance.REF_TRIPS.observe(.childRemoved, with: { (removedTripSnapshot) in
            let removedTrip = removedTripSnapshot.value as? [String: AnyObject]
            if removedTrip!["driverKey"] != nil {
                DataService.instance.REF_DRIVERS.child(removedTrip!["driverKey"] as! String).updateChildValues(["driverIsOnTrip": false])
            }
            
            DataService.instance.userIsDriver(userKey: self.currentUserId!, handler: { (isDriver) in
                    if isDriver {
                        self.removeOverlaysAndAnnotations(forDrivers: false, forPassengers: true)
                    } else {
                        self.cancelBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                        self.actionBtn.animateButton(shouldLoad: false, withMessage: "REQUEST RIDE")
                        self.destinationTextField.isUserInteractionEnabled = true
                        self.destinationTextField.text = ""
                        
                        self.removeOverlaysAndAnnotations(forDrivers: true, forPassengers: false)
                        self.centerMapOnUserLocation()
                    }
                })
        })
    }
    
    func checkLocationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            manager?.startUpdatingLocation()
            
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
        } else {
            manager?.requestAlwaysAuthorization()
        }
    }
    
    func loadDriverAnnotationsFromFB() {
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for driver in driverSnapshot {
                    if driver.hasChild("userIsDriver") {
                        if driver.hasChild("coordinate") {
                            if driver.childSnapshot(forPath: "isPickupModeEnabled").value as? Bool == true {
                                if let driverDict = driver.value as? Dictionary<String, Any> {
                                    let coordinateArray = driverDict["coordinate"] as! NSArray
                                    let driverCoordinate = CLLocationCoordinate2D(latitude: coordinateArray[0] as! CLLocationDegrees, longitude: coordinateArray[1] as! CLLocationDegrees)
                                    
                                    let annotation = DriverAnnotation(coordinate: driverCoordinate, withKey: driver.key)
                                    
                                    var driverIsVisible: Bool {
                                        return self.mapView.annotations.contains(where: { (annotation) -> Bool in
                                            if let driverAnnotation = annotation as? DriverAnnotation {
                                                if driverAnnotation.key == driver.key {
                                                    driverAnnotation.update(annotationPosition: driverAnnotation, withKeyCoordiante: driverCoordinate)
                                                    return true
                                                }
                                            }
                                            return false
                                        })
                                    }
                                    
                                    if !driverIsVisible {
                                        self.mapView.addAnnotation(annotation)
                                    }
                                }
                            } else {
                                for annotation in self.mapView.annotations {
                                    if annotation.isKind(of: DriverAnnotation.self) {
                                        if let annotation = annotation as? DriverAnnotation {
                                            if annotation.key == driver.key {
                                                self.mapView.removeAnnotation(annotation)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
    }
    
    func connectUserAndDriverForTrip() {
        DataService.instance.userIsDriver(userKey: currentUserId!) { (status) in
            if status == false {
                DataService.instance.REF_TRIPS.child(self.currentUserId!).observe(.value, with: { (snapshot) in
                    let tripDict = snapshot.value as? Dictionary<String, AnyObject>
                    
                    if tripDict?["tripIsAccepted"] as? Bool == true {
                        self.removeOverlaysAndAnnotations(forDrivers: true, forPassengers: true)
                        
                        let driverId = tripDict?["driverKey"] as! String
                        let pickupCoordinateArr = tripDict?["pickupCoordinate"] as! NSArray
                        let pickupCoordinate = CLLocationCoordinate2D(latitude: pickupCoordinateArr[0] as! CLLocationDegrees, longitude: pickupCoordinateArr[1] as! CLLocationDegrees)
                        let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)
                        
                        
                    }
                })
            }
        }
    }
    
    func centerMapOnUserLocation() {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @IBAction func cancelBtnClicked(_ sender: Any) {
        DataService.instance.driverIsOnTrip(driverKey: self.currentUserId!) { (isOnTrip, driverKey, tripKey) in
            if isOnTrip! {
                UpdateSerice.instance.cancelTrip(withPassengerKey: tripKey!, forDriverKey: driverKey!)
            }
        }
        
        DataService.instance.passengerIsOnTrip(passengerKey: self.currentUserId!) { (isOnTrip, driverKey, tripKey) in
            if isOnTrip! {
                UpdateSerice.instance.cancelTrip(withPassengerKey: self.currentUserId!, forDriverKey: driverKey!)
            } else {
                UpdateSerice.instance.cancelTrip(withPassengerKey: self.currentUserId!, forDriverKey: driverKey)
            }
        }
    }
    
    @IBAction func centerMapBtnClicked(_ sender: Any) {
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for user in userSnapshot {
                    if user.key == self.currentUserId {
                        if user.hasChild("tripCoordinate") {
                            self.zoom(toFitAnnotationsFromMapview: self.mapView)
                            self.centerMapBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                        } else {
                            self.centerMapOnUserLocation()
                            self.centerMapBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                        }
                    }
                }
            }
        })
    }
    
    @IBAction func actionBtnPressed(_ sender: Any) {
        actionBtn.animateButton(shouldLoad: true, withMessage: nil)
        UpdateSerice.instance.updateTripsWithCoordinatesUponRequest()
        
        self.view.endEditing(true)
        destinationTextField.isUserInteractionEnabled = false
    }
    
    @IBAction func menuBtnClicked(_ sender: Any) {
        delegate?.toggleLeftPanel()
    }
}

extension HomeVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            checkLocationAuthStatus()
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
        }
    }
}

extension HomeVC: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == destinationTextField {
            tableView.frame = CGRect(x: 20, y: view.frame.height, width: view.frame.width - 40, height: view.frame.height - 170)
            tableView.layer.cornerRadius = 5.0
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "locationCell")
            
            tableView.delegate = self
            tableView.dataSource = self
            
            tableView.tag = 18
            tableView.rowHeight = 60
            
            view.addSubview(tableView)
            animateTableView(shouldShow: true)
            
            UIView.animate(withDuration: 0.2) {
                self.destinationCircle.backgroundColor = UIColor.red
                self.destinationCircle.borderColor = UIColor.init(red: 199/255, green: 0/255, blue: 0/255, alpha: 1.0)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == destinationTextField {
            performSearch()
            shouldPresentLoadingView(true)
            view.endEditing(true)
        }
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == destinationTextField {
            if destinationTextField.text == "" {
                UIView.animate(withDuration: 0.2) {
                    self.destinationCircle.backgroundColor = UIColor.lightGray
                    self.destinationCircle.borderColor = UIColor.darkGray
                }
            } else {
                
            }
        }
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        matchingItems.removeAll()
        tableView.reloadData()
        centerMapOnUserLocation()
        
        DataService.instance.REF_USERS.child(currentUserId!).child("tripCoordinate").removeValue()
        mapView.removeOverlays(mapView.overlays)
        for annotation in mapView.annotations {
            if annotation.isKind(of: PassengerAnnotation.self) {
                mapView.removeAnnotation(annotation)
            } else if let annotation = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(annotation)
            }
        }
        
        return true
    }
    
    func animateTableView(shouldShow: Bool) {
        if shouldShow {
            UIView.animate(withDuration: 0.2) {
                self.tableView.frame = CGRect(x: 20, y: 170, width: self.view.frame.width - 40, height: self.view.frame.height - 170)
            }
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                self.tableView.frame = CGRect(x: 20, y: self.view.frame.height, width: self.view.frame.width - 40, height: self.view.frame.height - 170)
            }) { (done) in
                for subview in self.view.subviews {
                    if subview.tag == 18 {
                        subview.removeFromSuperview()
                    }
                }
            }
        }
    }
}

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "locationCell")
        let mapItem = matchingItems[indexPath.row]
        cell.textLabel?.text = mapItem.name
        cell.detailTextLabel?.text = mapItem.placemark.title
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.matchingItems.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        shouldPresentLoadingView(true)
        
        let passengerCoordinate = manager?.location?.coordinate
        let passengerAnnotation = PassengerAnnotation(coordinate: passengerCoordinate!, withKey: currentUserId!)
        mapView.addAnnotation(passengerAnnotation)
        
        self.destinationTextField.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
        
        let selectedMapItem = matchingItems[indexPath.row]
        DataService.instance.REF_USERS.child(currentUserId!).updateChildValues(["tripCoordinate": [selectedMapItem.placemark.coordinate.latitude, selectedMapItem.placemark.coordinate.longitude]])
        
        dropPinFor(placemark: selectedMapItem.placemark)
        
        searchMapKitForResultsWithPolyline(forOriginMapItem: nil, withDestinationMapItem: selectedMapItem)
        
        animateTableView(shouldShow: false)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if destinationTextField.text == "" {
            animateTableView(shouldShow: false)
        }
    }
}

extension HomeVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        UpdateSerice.instance.updateUserLocation(withCoordinate: userLocation.coordinate)
        UpdateSerice.instance.updateDriverLocation(withCoordinate: userLocation.coordinate)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let identifier = "driver"
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: "driverAnnotation")
            return view
        } else if let annotation = annotation as? PassengerAnnotation {
            let identifier = "passenger"
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: "currentLocationAnnotation")
            return view
        } else if let annotation = annotation as? MKPointAnnotation {
            let identifier = "destination"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                annotationView?.annotation = annotation
            }
            annotationView?.image = UIImage(named: "destinationAnnotation")
            return annotationView
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        centerMapBtn.fadeTo(alphaValue: 1.0, withDuration: 0.2)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let lineRenderer = MKPolylineRenderer(overlay: (self.route?.polyline)!)
        lineRenderer.strokeColor = UIColor(red: 216/255, green: 71/255, blue: 30/277, alpha: 0.75)
        lineRenderer.lineWidth = 3
        
        shouldPresentLoadingView(false)
        
        zoom(toFitAnnotationsFromMapview: self.mapView)
        
        return lineRenderer
    }
    
    func dropPinFor(placemark: MKPlacemark) {
        selectedItemPlacemark = placemark
        
        for annotation in mapView.annotations {
            if annotation.isKind(of: MKPointAnnotation.self) {
                mapView.removeAnnotation(annotation)
            }
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        mapView.addAnnotation(annotation)
    }
    
    func performSearch() {
        matchingItems.removeAll()
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = destinationTextField.text
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            if error != nil {
                self.showAlert((error?.localizedDescription)!)
                print("There was an error searching for items: \(error?.localizedDescription ?? "")")
            } else if response?.mapItems.count == 0 {
                self.showAlert("No results found! Please search again for a different location.")
            } else {
                for mapItem in response!.mapItems {
                    self.matchingItems.append(mapItem as MKMapItem)
                    self.tableView.reloadData()
                    self.shouldPresentLoadingView(false)
                }
            }
        }
    }
    
    func searchMapKitForResultsWithPolyline(forOriginMapItem originMapItem: MKMapItem?, withDestinationMapItem destinationMapItem: MKMapItem) {
        let request = MKDirectionsRequest()
        
        if originMapItem == nil {
            request.source = MKMapItem.forCurrentLocation()
        } else {
            request.source = originMapItem
        }
        
        request.destination = destinationMapItem
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            guard let response = response else {
                self.showAlert("An error occured please try again!")
                print("Destination error: \(error?.localizedDescription ?? "")")
                return
            }
            self.route = response.routes[0]
            
            self.mapView.add((self.route?.polyline)!)
            
            let delegate = AppDelegate.getAppDelegate()
            delegate.window?.rootViewController!.shouldPresentLoadingView(false)
        }
    }
    
    func zoom(toFitAnnotationsFromMapview mapView: MKMapView) {
        if mapView.annotations.count == 0 {
            return
        }
        
        var topLeftCoordinate = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bootomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        
        for annotation in mapView.annotations where !annotation.isKind(of: DriverAnnotation.self) {
            topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
            topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
            
            bootomRightCoordinate.longitude = fmax(bootomRightCoordinate.longitude, annotation.coordinate.longitude)
            bootomRightCoordinate.latitude = fmin(bootomRightCoordinate.latitude, annotation.coordinate.latitude)
        }
        
        var region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(topLeftCoordinate.latitude - (topLeftCoordinate.latitude - bootomRightCoordinate.latitude) * 0.5, topLeftCoordinate.longitude + (bootomRightCoordinate.longitude - topLeftCoordinate.longitude) * 0.5), span: MKCoordinateSpan(latitudeDelta: fabs(topLeftCoordinate.latitude - bootomRightCoordinate.latitude) * 2.0, longitudeDelta: fabs(bootomRightCoordinate.longitude - topLeftCoordinate.longitude) * 2.0))
        
        region = mapView.regionThatFits(region)
        mapView.setRegion(region, animated: true)
    }
    
    func removeOverlaysAndAnnotations(forDrivers: Bool?, forPassengers: Bool?) {
        for annotation in mapView.annotations {
            if let annotation = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(annotation)
            }
            
            if forPassengers! {
                if let annotation = annotation as? PassengerAnnotation {
                    mapView.removeAnnotation(annotation)
                }
            }
            
            if forDrivers! {
                if let annotation = annotation as? DriverAnnotation {
                    mapView.removeAnnotation(annotation)
                }
            }
        }
        
        for overlay in mapView.overlays {
            if overlay is MKPolyline {
                mapView.remove(overlay)
            }
        }
    }
}
