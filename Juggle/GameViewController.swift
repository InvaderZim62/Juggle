//
//  GameViewController.swift
//  Juggle
//
//  Created by Phil Stern on 8/9/21.
//
//  Initial setup: File | New | Project | Game (Game Technology: SceneKit)
//  Delete art.scnassets (move to Trash)
//

import UIKit
import QuartzCore
import SceneKit

struct Ball {
    static let radius: CGFloat = 1
    static let positionRelativeToHand = SCNVector3(x: 0, y: Float(radius), z: 0)
}

struct Hands {
    static let distanceBetween: Float = 4.4
    static let rotationCenterVerticalOffset: Float = -6.0  // from screen center
    static let rotationRate = 300.rads  // rotation rate around center of ellipse
    static let initialAngle = 90.rads  // initial angle of hand about center of ellipse, zero along ellipse major-axis, positive ccw
    static let ballReleaseAngle = 200.rads  // angle of hand about center of ellipse at ball release, zero along ellipse major-axis, positive ccw
}

struct Ellipse {  // for hand motion
    static let majorAxis = 3.0
    static let minorAxis = 1.0
    static let tilt = 60.rads  // zero along screen x-axis, positive ccw
}

struct ContactCategory {  // bit masks for contact detection
    static let hand = 1 << 0
    static let ball = 1 << 1
}

class GameViewController: UIViewController {

    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    
    var ballNode: BallNode!
    var leftHandNode: HandNode!
    var rightHandNode: HandNode!
    var leftHandRotationCenter = SCNVector3()
    var rightHandRotationCenter = SCNVector3()

    let ballNodePhysicsBody: SCNPhysicsBody = {  // set property with a closure
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        physicsBody.restitution = 0  // no bounce
        physicsBody.categoryBitMask = ContactCategory.ball
        physicsBody.contactTestBitMask = ContactCategory.hand
        return physicsBody
    }()
    
    // MARK: - Start of Code

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        setupCamera()
        addHandNodes()
        addBallNode()
    }
    
    private func addHandNodes() {
        leftHandRotationCenter = SCNVector3(x: -Hands.distanceBetween / 2, y: Hands.rotationCenterVerticalOffset, z: 0)
        leftHandNode = HandNode(isLeft: true)
        leftHandNode.position = leftHandRotationCenter +
            ellipticalPosition(angle: Hands.initialAngle, tilt: Ellipse.tilt)
        scnScene.rootNode.addChildNode(leftHandNode)
        
        rightHandRotationCenter = SCNVector3(x: Hands.distanceBetween / 2, y: Hands.rotationCenterVerticalOffset, z: 0)
        rightHandNode = HandNode(isLeft: false)
        rightHandNode.position = rightHandRotationCenter +
            ellipticalPosition(angle: Hands.initialAngle, tilt: -Ellipse.tilt)
        scnScene.rootNode.addChildNode(rightHandNode)
    }

    private func addBallNode() {
        ballNode = BallNode()
        ballNode.position = rightHandNode.position + Ball.positionRelativeToHand
        scnScene.rootNode.addChildNode(ballNode)
    }
    
    private func moveHandNode(_ handNode: HandNode, deltaTime: Double) {
        let rotationRate = handNode.isLeft ? Hands.rotationRate : -Hands.rotationRate  // left hand ccw, right hand cw
        let rotationCenter = handNode.isLeft ? leftHandRotationCenter : rightHandRotationCenter
        let ellipseTilt = handNode.isLeft ? Ellipse.tilt : -Ellipse.tilt

        let deltaAngle = deltaTime * rotationRate  // radians
        let angle = Hands.initialAngle + deltaAngle  // start hand along ellipse minor-axis
        if abs(deltaAngle) < 360.rads {  // move hand around complete loop
            handNode.position = rotationCenter + ellipticalPosition(angle: angle, tilt: ellipseTilt)
        } else {
            handNode.isMoving = false
            handNode.position = rotationCenter + ellipticalPosition(angle: Hands.initialAngle, tilt: ellipseTilt)  // return to start (should be there)
        }
        if abs(deltaAngle) > Hands.ballReleaseAngle {  // release ball just past negative minor axis
            ballNode.location = .inAir
        }
    }
    
    // return position relative to center of ellipse
    // angle is about ellipse center (ccw from major-axis)
    // tilt is rotation of ellipse major-axis (ccw from screen x-axis)
    private func ellipticalPosition(angle: Double, tilt: Double) -> SCNVector3 {
        let x = Ellipse.majorAxis * cos(angle) * cos(tilt) - Ellipse.minorAxis * sin(angle) * sin(tilt)
        let y = Ellipse.majorAxis * cos(angle) * sin(tilt) + Ellipse.minorAxis * sin(angle) * cos(tilt)
        return SCNVector3(x: Float(x), y: Float(y), z: 0)
    }

    // MARK: - Setup
    
    private func setupView() {
        scnView = self.view as? SCNView
        scnView.showsStatistics = true
        scnView.allowsCameraControl = true  // use standard camera controls with swiping
        scnView.showsStatistics = false
        scnView.autoenablesDefaultLighting = true
        scnView.isPlaying = true  // prevent SceneKit from entering a "paused" state, if there isn't anything to animate
        scnView.delegate = self  // needed for renderer, below
    }
    
    private func setupScene() {
        scnScene = SCNScene()
        scnScene.background.contents = "Background_Diffuse.png"
        scnScene.physicsWorld.contactDelegate = self  // requires SCNPhysicsContactDelegate (extension, below)
        scnView.scene = scnScene
    }
    
    private func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 30)
        scnScene.rootNode.addChildNode(cameraNode)
    }
}

// MARK: - Extensions

extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if leftHandNode.isMoving {
            moveHandNode(leftHandNode, deltaTime: time - leftHandNode.moveStartTime)
        } else {
            leftHandNode.moveStartTime = time  // keep updating until hand starts moving
        }
        if rightHandNode.isMoving {
            moveHandNode(rightHandNode, deltaTime: time - rightHandNode.moveStartTime)
        } else {
            rightHandNode.moveStartTime = time  // keep updating until hand starts moving
        }
        // if ball is in hand, turn off physics body and move with hand
        switch ballNode.location {
        case .leftHand:
            ballNode.physicsBody = nil
            ballNode.position = leftHandNode.position + Ball.positionRelativeToHand
        case .rightHand:
            ballNode.physicsBody = nil
            ballNode.position = rightHandNode.position + Ball.positionRelativeToHand
        case .inAir:
            ballNode.physicsBody = ballNodePhysicsBody
        }
    }
}

// detect contact between dominos, to play click sound (requires scnScene.physicsWorld.contactDelegate = self)
extension GameViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let contactMask = contact.nodeA.physicsBody!.categoryBitMask | contact.nodeB.physicsBody!.categoryBitMask
        switch contactMask {
        case ContactCategory.hand | ContactCategory.ball:
            if let handNode = contact.nodeA as? HandNode, let ballNode = contact.nodeB as? BallNode {
                handNode.isMoving = true
                ballNode.location = handNode.isLeft ? .leftHand : .rightHand
            } else if let handNode = contact.nodeB as? HandNode, let ballNode = contact.nodeA as? BallNode {
                handNode.isMoving = true
                ballNode.location = handNode.isLeft ? .leftHand : .rightHand
            }
        default:
            break
        }
    }
}
