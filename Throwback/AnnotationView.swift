//
//  AnnotationView.swift
//  Throwback
//
//  Created by Cameron Jackson on 8/8/16.
//  Copyright © 2016 Hot Fire. All rights reserved.
//

import Foundation
import UIKit
import HDAugmentedReality

public class AnnotationView: ARAnnotationView, UIGestureRecognizerDelegate
{
  
  public var titleLabel: UILabel?
//  public var previewImage: UIImageView?
  public var infoButton: UIButton?
  
  
  override public func didMoveToSuperview()
  {
    super.didMoveToSuperview()
    if self.titleLabel == nil
    {
      self.loadUi()
    }
  }
  
  func loadUi()
  {
    // Title label
    self.titleLabel?.removeFromSuperview()
    let label = UILabel()
    label.font = UIFont.systemFontOfSize(10)
    label.numberOfLines = 0
    label.backgroundColor = UIColor.clearColor()
    label.textColor = UIColor.whiteColor()
    self.addSubview(label)
    self.titleLabel = label
    
    
    // Image View
//    if let annotation = annotation as? HFAnnotation {
//      self.previewImage?.removeFromSuperview()
//      let imageView = UIImageView()
//      imageView.kf_setImageWithURL(NSURL(string: annotation.imageLink ?? "")!)
//      self.addSubview(imageView)
//      previewImage = imageView
//    }
    
    // Info button
    self.infoButton?.removeFromSuperview()
    let button = UIButton(type: UIButtonType.DetailDisclosure)
    button.userInteractionEnabled = false   // Whole view will be tappable, using it for appearance
    self.addSubview(button)
    self.infoButton = button
    
    // Gesture
    let tapGesture = UITapGestureRecognizer(target: self, action: Selector("tapGesture"))
    self.addGestureRecognizer(tapGesture)
    
    // Other
    self.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
    self.layer.cornerRadius = 5
    
    if self.annotation != nil
    {
      self.bindUi()
    }
  }
  
  func layoutUi()
  {
    let buttonWidth: CGFloat = 40
    let buttonHeight: CGFloat = 40
    
    self.titleLabel?.frame = CGRectMake(10, 0, self.frame.size.width - buttonWidth - 5, self.frame.size.height);
    self.infoButton?.frame = CGRectMake(self.frame.size.width - buttonWidth, self.frame.size.height/2 - buttonHeight/2, buttonWidth, buttonHeight);
  }
  
  // This method is called whenever distance/azimuth is set
  override public func bindUi()
  {
    if let annotation = self.annotation, let title = annotation.title
    {
      let distance = annotation.distanceFromUser > 1000 ? String(format: "%.1fkm", annotation.distanceFromUser / 1000) : String(format:"%.0fm", annotation.distanceFromUser)
      
      let text = String(format: "%@\nAZ: %.0f°\nDST: %@", title, annotation.azimuth, distance)
      self.titleLabel?.text = text
    }
  }
  
  public override func layoutSubviews()
  {
    super.layoutSubviews()
    self.layoutUi()
  }
  
  public func tapGesture()
  {
    if let annotation = self.annotation as? HFAnnotation
    {
//      let imageUrl = NSURL(string: annotation.imageLink!)!
//      mediaFocusController.shouldDismissOnImageTap = true
//      mediaFocusController.shouldDismissOnTap = true
//      mediaFocusController.showImageFromURL(imageUrl, fromView: window!.rootViewController!.view)
      
    }
  }
}