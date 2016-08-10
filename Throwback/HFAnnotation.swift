//
//  HFAnnotation.swift
//  Throwback
//
//  Created by Cameron Jackson on 8/7/16.
//  Copyright © 2016 Hot Fire. All rights reserved.
//

import Foundation
import HDAugmentedReality
import MapKit


public class HFAnnotation: ARAnnotation, MKAnnotation {
  
//  public var imageLink: String?
  
  public var coordinate: CLLocationCoordinate2D {
    get {
      return self.location!.coordinate
    }
  }
}