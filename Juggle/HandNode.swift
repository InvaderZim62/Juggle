//
//  HandNode.swift
//  Juggle
//
//  Created by Phil Stern on 8/10/21.
//

import UIKit
import SceneKit

class HandNode: SCNNode {
    
    var isLeft = false
    var isMoving = false
    var ballNode: BallNode!  // if ball in hand
    var moveStartTime: TimeInterval = 0
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    init(isLeft: Bool) {
        super.init()
        self.isLeft = isLeft
        let hand = SCNBox(width: 0.8, height: 0.3, length: 0.8, chamferRadius: 0)
        hand.firstMaterial?.diffuse.contents = UIColor.white
        geometry = hand
        physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        physicsBody?.categoryBitMask = ContactCategory.hand
        physicsBody?.contactTestBitMask = ContactCategory.ball
    }
}
