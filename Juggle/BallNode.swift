//
//  BallNode.swift
//  Juggle
//
//  Created by Phil Stern on 8/10/21.
//

import UIKit
import SceneKit

enum BallLocation {
    case leftHand
    case rightHand
    case inAir
}

class BallNode: SCNNode {
    
    var location: BallLocation = .inAir
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init() {
        super.init()
        let ball = SCNSphere(radius: Ball.radius)
        ball.firstMaterial?.diffuse.contents = UIColor.red
        geometry = ball
        physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        physicsBody?.restitution = 0  // no bounciness
        physicsBody?.categoryBitMask = ContactCategory.ball
        physicsBody?.contactTestBitMask = ContactCategory.hand
    }
}
