//
//  ViewController.swift
//  Juggle
//
//  Created by Phil Stern on 8/12/21.
//

import UIKit

class ViewController: UIViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let gvc = segue.destination as? GameViewController {
            switch segue.identifier {
            case "3 Ball Cascade":
                gvc.ballCount = 3
                gvc.ballReleaseInterval = 1.1  // seconds between releasing the initial balls (alternating right-left hands)
                gvc.ballReleaseAngle = 220.rads  // angle of hand about center of ellipse at ball release, zero along ellipse major-axis, positive ccw
                gvc.ellipseMajorAxis = 3.0
                gvc.ellipseMinorAxis = 1.0
                gvc.ellipseTilt = 60.rads  // rotation of ellipse major axis from screen x-axis, positive ccw for left ellipse (pos cw for right ellipse)
            case "5 Ball Cascade":
                gvc.ballCount = 5
                gvc.ballReleaseInterval = 0.68
                gvc.ballReleaseAngle = 220.rads
                gvc.ellipseMajorAxis = 3.0
                gvc.ellipseMinorAxis = 1.0
                gvc.ellipseTilt = 60.rads
            case "4 Ball Fountain":
                gvc.ballCount = 4
                gvc.ballReleaseInterval = 0.83
                gvc.ballReleaseAngle = 120.rads
                gvc.ellipseMajorAxis = 3.0
                gvc.ellipseMinorAxis = 1.2
                gvc.ellipseTilt = 120.rads
            default:
                break
            }
        }
    }
}
