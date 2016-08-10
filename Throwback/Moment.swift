//
//  File.swift
//  Throwback
//
//  Created by Cameron Jackson on 8/9/16.
//  Copyright © 2016 Hot Fire. All rights reserved.
//

import Foundation
import RealmSwift

class Moment: Object {
  dynamic var caption = ""
  dynamic var latitude: Double = 0
  dynamic var longitude: Double = 0
  dynamic var elevation: Double = 0
}