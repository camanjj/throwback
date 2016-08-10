//
//  ViewController.swift
//  Throwback
//
//  Created by Cameron Jackson on 8/7/16.
//  Copyright © 2016 Hot Fire. All rights reserved.
//

import UIKit
import MapKit

import HDAugmentedReality
import CoreLocation
import JAMSVGImage
import AVFoundation
import Spring
import Alamofire
import SwiftyJSON
import MRProgress
import Kingfisher
import URBMediaFocusViewController
import RealmSwift

let mediaFocusController = URBMediaFocusViewController()

class ViewController: ARViewController, ARDataSource, CLLocationManagerDelegate {

  @IBOutlet weak var button: UIButton!
  let stillImageOutput = AVCaptureStillImageOutput()
  var error: NSError?
  var holderImageView: UIImageView?
  
  var currentLocation: CLLocation?
  
  let locManager = CLLocationManager()
  
  var realm: Realm? = nil
  
  var mapView: MKMapView?
  
  var currentAnnotations = [HFAnnotation]()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    configAR()
    
    
    setUpSession()
    
    // get the location mananger up and running
    locManager.requestWhenInUseAuthorization()
    if CLLocationManager.locationServicesEnabled() {
      locManager.delegate = self
      locManager.distanceFilter = 1
      locManager.desiredAccuracy = kCLLocationAccuracyBest
      locManager.startUpdatingLocation()
    }
    
    
    // add Camera button
    let circle = SpringButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    circle.layer.cornerRadius = 50
    circle.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.50)
    view.addSubview(circle)
    circle.center.x = view.center.x
    circle.center.y = view.frame.height - 60
    circle.addTarget(self, action: #selector(cameraClick(_:)), forControlEvents: .TouchUpInside)
    
    // add settings button
    let settingsImage = JAMSVGImage(named: "wrench").imageAtSize(CGSize(width: 30, height: 30)).imageWithRenderingMode(.AlwaysTemplate)
    button.setImage(settingsImage, forState: .Normal)
    
    
   
    
    
    // check if we have a cached location, if yes then fetch locations, else wait for location update
    let userDefaults = NSUserDefaults.standardUserDefaults()
    if let _ = userDefaults.objectForKey("lat"), _ = userDefaults.objectForKey("lng") {
      
      let lat = userDefaults.doubleForKey("lat")
      let lng = userDefaults.doubleForKey("lng")
      
      // send request
      fetchCloseMoments(lat, lng: lng)
      
    }
    
//    setAnnotations(getDummyAnnotations(centerLatitude: 39.1321013, centerLongitude: -77.1911528, delta: 0.05, count: 10))

    
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    // hide the close button
    if let closeButton = closeButton {
      closeButton.hidden = true
    }
    
    // Add a blank UIImageView above to show the current image
    let imageView = UIImageView(frame: view.frame)
    imageView.backgroundColor = UIColor.clearColor()
//    imageView.contentMode = .ScaleAspectFit
    view.addSubview(imageView)
    holderImageView = imageView
    
    
  }

  
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
    let recent = locations.last
    
    
    if currentLocation == nil {
//      print("update current location")
      currentLocation = recent
//      // send the location to the backend to fetch the POI
      fetchCloseMoments(recent!.coordinate.latitude, lng: recent!.coordinate.longitude, elevation: recent!.altitude)
      
//      setAnnotations(getDummyAnnotations(centerLatitude: 39.1321013, centerLongitude: -77.1911528, delta: 5, count: 10))
    }
    
    
    print("update current location")
    
    currentLocation = recent
    // send the location to the backend to fetch the POI
//    fetchCloseMoments(recent!.coordinate.latitude, lng: recent!.coordinate.longitude, elevation: recent!.altitude)
    
    
  }
  
  func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    print(error.localizedDescription)
  }
  

  
  func fetchCloseMoments(lat: Double, lng: Double, elevation: Double = 0) {
    
    // create the realm if it does not exists
    if realm == nil {
      realm = try! Realm()
    }
    
    
    let moments = realm!.objects(Moment.self)
    var annoations = [HFAnnotation]()
    
    for moment in moments {
      let annotation = HFAnnotation()
      annotation.title = moment.caption
      let coord = CLLocationCoordinate2D(latitude: moment.latitude, longitude: moment.longitude)
      let loc = CLLocation(coordinate: coord, altitude: moment.elevation, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: NSDate())
      annotation.location = loc
      annoations.append(annotation)
    }
    
    currentAnnotations = annoations
    setAnnotations(annoations)
    
    
//    Alamofire.request(.GET, "http://54.88.118.223:3000/images".stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!, parameters: ["lat": lat, "lon": lng, "elevation": elevation], encoding: ParameterEncoding.URL, headers: nil)
//      .responseString(completionHandler: { (response) in
//        print(response)
//      })
//      .validate()
//      .responseJSON { (response) in
//        
//        
//        switch response.result {
//        case .Success(let value):
//          let json = JSON(value)
//          let arr = json.arrayValue
//          
//          var annotations = [HFAnnotation]()
//          
//          for item in arr {
//            if let moment = item["doc"].dictionary {
//              let annotation = HFAnnotation()
//              annotation.imageLink = moment["image"]!.string
//              annotation.title = moment["caption"]?.string ?? ""
//              let lat = moment["lat"]!.double
//              let lng = moment["lon"]!.double
//              let loc = CLLocation(latitude: lat!, longitude: lng!)
//              annotation.location = loc
//              annotations.append(annotation)
//            }
//          }
//          
//          self.setAnnotations(annotations)
//          
//        case .Failure(let error): break
//          
//        }
//        
//        
//    }
    
  }
  
  func postMoment(encodedString encodedString: String, caption: String, location: CLLocation ) {
    
    // Show overlay
    MRProgressOverlayView.showOverlayAddedTo(view.window, animated: true)
    
    
    let movedLocation = locationWithBearing(currentHeading, distanceMeters: 1, origin: location.coordinate)
    
    //NOTE: Temp - Keep all of the locations locally
    let moment = Moment()
    moment.caption = caption
    moment.latitude = movedLocation.latitude
    moment.longitude = movedLocation.longitude
    moment.elevation = location.altitude
    
    // create the realm if it does not exists
    if realm == nil {
      realm = try! Realm()
    }
    
    try! realm!.write {
      realm!.add(moment)
    }
    
    
    self.holderImageView?.image = nil
    MRProgressOverlayView.dismissOverlayForView(self.view.window, animated: true)
    fetchCloseMoments(currentLocation!.coordinate.latitude, lng: currentLocation!.coordinate.longitude)

    
    return
//    Alamofire.request(.POST, "https://api.imgur.com/3/image", parameters: ["image": encodedString], encoding: .JSON, headers: ["Authorization": "Client-ID 9a6d35bad662467"])
//      .validate()
//      .responseJSON { (response) in
//        
//        switch response.result {
//        case .Success(let value):
//          let json = JSON(value)
//          let data = json["data"]
//          let url = data["link"].string!
//          
//          Alamofire.request(.POST, "http://54.88.118.223:3000/images", parameters: ["image": url, "lat": lat, "lon": lng, "elevation": elevation, "caption": caption], encoding: .JSON, headers: nil)
//            .responseString(completionHandler: { (response) in
//              print(response)
//            })
//            .validate()
//            .responseJSON { (response) in
//              
//              switch response.result {
//              case .Success(_):
//                self.fetchCloseMoments(self.currentLocation!.coordinate.latitude, lng: self.currentLocation!.coordinate.longitude)
//              case .Failure(let error):
//                print(error.localizedDescription)
//                print(response.request?.URL)
//              }
//              
//              self.holderImageView?.image = nil
//              MRProgressOverlayView.dismissOverlayForView(self.view.window, animated: true)
//              
//          }
//          
//        case .Failure(let error):
//          print(error.localizedDescription)
//          print(response.request?.URL)
//          MRProgressOverlayView.dismissOverlayForView(self.view.window, animated: true)
//        }
//        
//        
//    }
  }
  
  func configAR() {
    // basic config
    debugEnabled = true
    dataSource = self
    maxDistance = 0
    maxVisibleAnnotations = 100
    maxVerticalLevel = 5
    headingSmoothingFactor = 0.05
    trackingManager.userDistanceFilter = 25
    trackingManager.reloadDistanceFilter = 75

  }
  
  func ar(arViewController: ARViewController, viewForAnnotation: ARAnnotation) -> ARAnnotationView
  {
    // Annotation views should be lightweight views, try to avoid xibs and autolayout all together.
    let annotationView = AnnotationView()
    annotationView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
    annotationView.frame = CGRect(x: 0,y: 0,width: 150,height: 50)
    return annotationView;
  }
  
  private func getDummyAnnotations(centerLatitude centerLatitude: Double, centerLongitude: Double, delta: Double, count: Int) -> Array<ARAnnotation>
  {
    var annotations: [ARAnnotation] = []
    
    srand48(3)
    for i in 0.stride(to: count, by: 1)
    {
      let annotation = ARAnnotation()
      annotation.location = self.getRandomLocation(centerLatitude: centerLatitude, centerLongitude: centerLongitude, delta: delta)
      annotation.title = "POI \(i)"
      annotations.append(annotation)
    }
    return annotations
  }
  
  private func getRandomLocation(centerLatitude centerLatitude: Double, centerLongitude: Double, delta: Double) -> CLLocation
  {
    var lat = centerLatitude
    var lon = centerLongitude
    
    let latDelta = -(delta / 2) + drand48() * delta
    let lonDelta = -(delta / 2) + drand48() * delta
    lat = lat + latDelta
    lon = lon + lonDelta
    return CLLocation(latitude: lat, longitude: lon)
  }
  
  
  func cameraClick(cameraButton: SpringButton) {
    
    cameraButton.animation = "pop"
    cameraButton.animate()
    
    if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
      stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {
        (imageDataSampleBuffer, error) -> Void in
        let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
        let image = UIImage(data: imageData)!
        self.holderImageView?.image = image
        UIImageWriteToSavedPhotosAlbum(UIImage(data: imageData)!, nil, nil, nil)

        
        let alertController = UIAlertController(title: "Caption", message: nil, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action) in
          
          self.holderImageView?.image = nil
          
        })
        let createAction = UIAlertAction(title: "Create", style: .Default, handler: { (action) in
          
          let imageData:NSData = UIImageJPEGRepresentation(image, 0.3)!
          let encodinedImage = imageData.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
          // send the moment
          self.postMoment(encodedString: encodinedImage, caption: alertController.textFields?.first?.text ?? "", location: self.currentLocation!)
          
        })
        
        alertController.addTextFieldWithConfigurationHandler({ (textField) in
          textField.placeholder = "Caption here!"
        })
        
        alertController.addAction(cancelAction)
        alertController.addAction(createAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
      }
    }
    
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  
  override func setUpSession() {
    let devices = AVCaptureDevice.devices().filter{ $0.hasMediaType(AVMediaTypeVideo) && $0.position == AVCaptureDevicePosition.Back }
    if let _ = devices.first as? AVCaptureDevice  {
      
      cameraSession.sessionPreset = AVCaptureSessionPresetPhoto
      stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
      if cameraSession.canAddOutput(stillImageOutput) {
        cameraSession.addOutput(stillImageOutput)
      }
    }
  }
  
  @IBAction func buttonClick(sender: AnyObject) {
    
    
    if mapView == nil {
      mapView = MKMapView(frame: view.frame)
    }
    
    if mapView?.superview == nil {
      mapView?.addAnnotations(currentAnnotations)
      view.insertSubview(mapView!, aboveSubview: button)
    } else {
      mapView?.removeFromSuperview()
    }
    
    
    
  }
  
  func locationWithBearing(bearing:Double, distanceMeters:Double, origin:CLLocationCoordinate2D) -> CLLocationCoordinate2D {
    let distRadians = distanceMeters / (6372797.6)
    
    var rbearing = bearing * M_PI / 180.0
    
    let lat1 = origin.latitude * M_PI / 180
    let lon1 = origin.longitude * M_PI / 180
    
    let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(rbearing))
    let lon2 = lon1 + atan2(sin(rbearing) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))
    
    return CLLocationCoordinate2D(latitude: lat2 * 180 / M_PI, longitude: lon2 * 180 / M_PI)
  }

  

}




