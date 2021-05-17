//
//  ViewController.swift
//  A1_iOS_ Satnam_C0798066
//
//  Created by SatnamSingh on 16/05/21.
//
//following are some references to create this application
//https://developer.apple.com/documentation/corelocation/cllocation/1423689-distance
//https://stackoverflow.com/questions/47959193/swift-4-to-remove-only-one-annotation-not-all
//https://stackoverflow.com/questions/28643554/where-is-mapkit-step-polyline


import UIKit
import MapKit

class Places {
    var title:String?
    var subtitle:String?
    var coordinate: CLLocationCoordinate2D
    init(_ title:String,_ coordinate : CLLocationCoordinate2D) {
        self.title = title
        self.coordinate = coordinate
    }
}

class ViewController: UIViewController,CLLocationManagerDelegate,MKMapViewDelegate {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var zoomButton: UIButton!
    
    //initial value of places
    var places = [Places("A", CLLocationCoordinate2DMake(0, 0)),
                  Places("B", CLLocationCoordinate2DMake(0, 0)),
                  Places("C", CLLocationCoordinate2DMake(0, 0))]
    
    var numberOfLocationsMarked = 0
    
    //core location manager to get location
    var locationManager = CLLocationManager()
    
    var isRemovalLocation = false
    var removalPosition = -1
    
    //global user location
    var userLocation : CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //to round the location button
        locationButton.layer.cornerRadius = locationButton.bounds.height/2
        locationButton.isHidden = true
        
        //to round the zoom button
        zoomButton.layer.cornerRadius = zoomButton.bounds.height/2
        zoomButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        //adding map delegate to show polyline,polygon
        //and manymore things on map
        map.delegate = self
        map.isZoomEnabled = false
        //assigning location delegate
        locationManager.delegate = self
        
        //for accuracy
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        //requesting location
        locationManager.requestWhenInUseAuthorization()
        
        //start location update
        locationManager.startUpdatingLocation()
        
        // tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addingLocationsWithGesture))
        tapGesture.numberOfTapsRequired = 2
        map.addGestureRecognizer(tapGesture)
    }
    //view did load ends
    
    // for functionality of gesture
    @objc func addingLocationsWithGesture(_ gestureRecognizer : UIGestureRecognizer){
        let location = gestureRecognizer.location(in: map)
        let coordinate = map.convert(location, toCoordinateFrom: map)
        
        //following code is to check if last gesture removed the marker
        //then replace that with new one
        if isRemovalLocation {
            isRemovalLocation = false
            if numberOfLocationsMarked  == 3{
                locationButton.isHidden = false
                addingLocationToArray(position: removalPosition, coordinate: coordinate)
                
                //to draw polygon between places
                let coordinates = places.map{$0.coordinate}
                let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
                polygon.accessibilityLabel = "this is polygon"
                map.addOverlay(polygon)
            }else{
                addingLocationToArray(position: removalPosition, coordinate: coordinate)
            }
            removalPosition = -1
            return
        }
        
        //following code is to remove marker if user taps on the same location or near by
        if numberOfLocationsMarked > 0 {
            for i in 0..<numberOfLocationsMarked{
                let firstLocation = CLLocation(latitude: places[i].coordinate.latitude, longitude: places[i].coordinate.longitude)
                let secondLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                if firstLocation.distance(from: secondLocation) < 500{
                    isRemovalLocation = true
                    locationButton.isHidden = true
                    map.removeOverlays(map.overlays)
                    removalPosition = i+1
                    for annotation in self.map.annotations{
                        if annotation.title == places[i].title{
                            map.removeAnnotation(annotation)
                        }
                    }
                    return
                }
            }
        }
        //removal of marker code ends
        
        //following code is to check the number of maked position and then draw polygon accordingly
        if numberOfLocationsMarked < 2{
            numberOfLocationsMarked += 1
            
            addingLocationToArray(position: numberOfLocationsMarked, coordinate: coordinate)
            
        }else if numberOfLocationsMarked == 2 {
            locationButton.isHidden = false
            numberOfLocationsMarked += 1
            
            addingLocationToArray(position: numberOfLocationsMarked, coordinate: coordinate)
            
            //to draw polygon between places
            let coordinates = places.map{$0.coordinate}
            let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
            polygon.accessibilityLabel = "this is polygon"
            map.addOverlay(polygon)
            let rect = polygon.boundingMapRect
            map.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top:10,left:40,bottom:10,right:40), animated: true)
            
        }else{
            locationButton.isHidden = true
            numberOfLocationsMarked = 0
            map.removeAnnotations(map.annotations)
            map.removeOverlays(map.overlays)
            addingLocationsWithGesture(gestureRecognizer)
        }
    }
    //gesture code ends
    
    func addingLocationToArray(position:Int,coordinate:CLLocationCoordinate2D)  {
        //adding location to place array
        places[position-1].coordinate = coordinate
        
        //adding distance from userlocation to marker in Subtitle
        let userLocation = MKPlacemark(coordinate: self.userLocation!.coordinate)
        let makerLocation = MKPlacemark(coordinate: coordinate)
        
        //request direction
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: userLocation)
        directionRequest.destination = MKMapItem(placemark: makerLocation)
        
        //transport type
        directionRequest.transportType = .automobile
        //calculating the direction
        let directions =  MKDirections(request: directionRequest)
        directions.calculate{ response,error in
            guard let directionResponse = response else {return}
            
            //create route
            let route = directionResponse.routes[0]
            
            //distance is calculated by route
            var distance = route.distance
            distance = (round(distance))/1000.0     //because distance is in metres
            self.places[position-1].subtitle = "Distance = \(distance) km"
            
            //adding annotation
            let annotation = MKPointAnnotation()
            annotation.title = self.places[position-1].title
            annotation.subtitle = self.places[position-1].subtitle
            annotation.coordinate = coordinate
            self.map.addAnnotation(annotation)
        }
    }
    
    // this button draw polyline between locations
    @IBAction func trackingButton(_ sender: Any) {
        //this will remove all the overlays
        map.removeOverlays(map.overlays)
        
        var firstMarker: MKPlacemark
        var secondMarker: MKPlacemark
        
        for i in 0...2{
            var startName: String?
            var destinationName : String?
            if i == 2 {
                startName = places[0].title!
                destinationName = places[i].title!
                firstMarker = MKPlacemark(coordinate: places[0].coordinate)
                secondMarker = MKPlacemark(coordinate: places[i].coordinate)
            }else{
                startName = places[i].title!
                destinationName = places[i+1].title!
                firstMarker = MKPlacemark(coordinate: places[i].coordinate)
                secondMarker = MKPlacemark(coordinate: places[i+1].coordinate)
            }
            //request direction
            let directionRequest = MKDirections.Request()
            directionRequest.source = MKMapItem(placemark: firstMarker)
            directionRequest.destination = MKMapItem(placemark: secondMarker)
            
            //transport type
            directionRequest.transportType = .automobile
            
            //calculating the direction
            let directions =  MKDirections(request: directionRequest)
            directions.calculate{ response,error in
                guard let directionResponse = response else {return}
                
                //create route
                let route = directionResponse.routes[0]
                //draw polyline
                self.map.addOverlay(route.polyline, level: .aboveRoads)
                //define map boundary for screen
                let rect = route.polyline.boundingMapRect
                self.map.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top:100,left:100,bottom:100,right:100), animated: true)
                
                // following to adding polyline distance annotation between two points
                let annotation = MKPointAnnotation()
                annotation.title = "\(startName!) to \(destinationName!)"
                annotation.subtitle = "Direction :\(round(route.distance)/1000.0) km"
                let pointCounts = route.polyline.pointCount
                let coordinateArray = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: pointCounts)
                route.polyline.getCoordinates(coordinateArray, range: NSMakeRange(0, pointCounts))
                annotation.coordinate = coordinateArray[pointCounts/2]
                self.map.addAnnotation(annotation)
               
            }
        }
    }
    //drawing polyline function ends
    
    //this function is called whenever user location is changed
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation  = locations[0]
        
        //define span
        let latDelta:CLLocationDegrees = 0.1
        let longDelta:CLLocationDegrees = 0.1
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
        
        //get location
        let location = CLLocationCoordinate2D(latitude: userLocation!.coordinate.latitude, longitude: userLocation!.coordinate.longitude)
        
        //define region where we want to display marker
        let region = MKCoordinateRegion(center: location, span: span)
        
        //set region and for smooth animation.
        map.setRegion(region, animated: true)
        
    }
   
    //this is function for enable and disable map zooming
    @IBAction func enableMapZoom(_ sender: UIButton) {
        if map.isZoomEnabled {
            sender.setTitle("Enable zoom", for: .normal)
            sender.backgroundColor = .systemBlue
            map.isZoomEnabled = false
        }else{
            sender.setTitle("Disable zoom", for: .normal)
            sender.backgroundColor = .systemGray2
            map.isZoomEnabled = true
        }
    }
    
    
    //for rendering the polyline and polygon
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline{
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 5
            return renderer
        } else if overlay is MKPolygon{
            let render = MKPolygonRenderer(overlay: overlay)
            render.strokeColor = .green
            render.fillColor = UIColor.red.withAlphaComponent(0.5)
            render.lineWidth = 2
            return render
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotationTitle = view.annotation?.title{
            print("User select \(annotationTitle!)")
        }
    }
    
    // to change annotation color for polyline label
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.subtitle??.contains("Direction") == true{
            let annotaionView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "polyline_distance")
            annotaionView.markerTintColor = UIColor.systemTeal
            return annotaionView
        }else {
            return nil
        }
    }
    
}

