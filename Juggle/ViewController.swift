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
                gvc.ballReleaseAngle = 180.rads  // angle of hand about center of ellipse at ball release, zero along ellipse major-axis, positive ccw
                gvc.ellipseMajorAxis = 3.0
                gvc.ellipseMinorAxis = 1.2
                gvc.ellipseTilt = 60.rads  // rotation of ellipse major axis from screen x-axis, positive ccw for left ellipse (pos cw for right ellipse)
            case "5 Ball Cascade":
                gvc.ballCount = 5
                gvc.ballReleaseInterval = 0.69
                gvc.ballReleaseAngle = 180.rads
                gvc.ellipseMajorAxis = 3.0
                gvc.ellipseMinorAxis = 1.2
                gvc.ellipseTilt = 60.rads
            case "4 Ball Fountain":
                gvc.ballCount = 4
                gvc.ballReleaseInterval = 0.83
                gvc.ballReleaseAngle = 215.rads
                gvc.ellipseMajorAxis = 3.0
                gvc.ellipseMinorAxis = 1.8
                gvc.ellipseTilt = 90.rads
            default:
                break
            }
        }
    }
}
