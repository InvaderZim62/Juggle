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

struct Constants {
    static let ballRadius: CGFloat = 1
    static let ballPositionRelativeToHand = SCNVector3(x: 0, y: Float(Constants.ballRadius), z: 0)
    static let leftHandRotationCenter = SCNVector3(x: -2.4, y: -6, z: 0)
    static let leftHandRotationTilt = -120.rads  // zero along x-axis, positive ccw
    static let leftHandInitialTheta = -90.rads  // zero along major-axis, positive ccw
    static let rightHandRotationCenter = SCNVector3(x: 2.4, y: -6, z: 0)
    static let rightHandRotationTilt = -60.rads  // zero along x-axis, positive ccw
    static let rightHandInitialTheta = 90.rads  // zero along major-axis, positive ccw
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
    
    let ballNodePhysicsBody: SCNPhysicsBody = {  // set property with a closure
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        physicsBody.restitution = 0  // no bounce
        physicsBody.categoryBitMask = ContactCategory.ball
        physicsBody.contactTestBitMask = ContactCategory.hand
        return physicsBody
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        setupCamera()
        addHandNodes()
        addBallNode()
    }
    
    private func addHandNodes() {
        leftHandNode = HandNode(isLeft: true)
        leftHandNode.position = Constants.leftHandRotationCenter +
            ellipticalPosition(theta: Constants.leftHandInitialTheta, tilt: Constants.leftHandRotationTilt)
        scnScene.rootNode.addChildNode(leftHandNode)
        
        rightHandNode = HandNode(isLeft: false)
        rightHandNode.position = Constants.rightHandRotationCenter +
            ellipticalPosition(theta: Constants.rightHandInitialTheta, tilt: Constants.rightHandRotationTilt)
        scnScene.rootNode.addChildNode(rightHandNode)
    }

    private func addBallNode() {
        ballNode = BallNode()
        ballNode.position = rightHandNode.position + Constants.ballPositionRelativeToHand
        scnScene.rootNode.addChildNode(ballNode)
    }
    
    private func moveHandNode(_ handNode: HandNode, deltaTime: Double) {
        let rotationRate = handNode.isLeft ? 300.rads : -300.rads  // radians/second
        let deltaTheta = deltaTime * rotationRate  // rads, angle of hand about center, zero along major-axis, positive ccw
        let initialTheta = handNode.isLeft ? Constants.leftHandInitialTheta : Constants.rightHandInitialTheta
        let theta = initialTheta + deltaTheta  // start along minor-axis
        let rotationCenter = handNode.isLeft ? Constants.leftHandRotationCenter : Constants.rightHandRotationCenter
        let rotationTilt = handNode.isLeft ? Constants.leftHandRotationTilt : Constants.rightHandRotationTilt
        if abs(deltaTheta) < 360.rads {  // full loop
            handNode.position = rotationCenter + ellipticalPosition(theta: theta, tilt: rotationTilt)
        } else {
            handNode.isMoving = false
            handNode.position = rotationCenter + ellipticalPosition(theta: initialTheta, tilt: rotationTilt)
        }
        if abs(deltaTheta) > 180.rads {  // 1/2 loop (to negative minor axis)
            ballNode.location = .inAir
        }
    }
    
    private func ellipticalPosition(theta: Double, tilt: Double) -> SCNVector3 {
        let majorAxis = 3.0
        let minorAxis = 1.0
        let x = majorAxis * cos(theta) * cos(tilt) - minorAxis * sin(theta) * sin(tilt)
        let y = majorAxis * cos(theta) * sin(tilt) + minorAxis * sin(theta) * cos(tilt)
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

extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if !leftHandNode.isMoving {
            leftHandNode.moveStartTime = time  // keep updating until hand moving
        } else {
            moveHandNode(leftHandNode, deltaTime: time - leftHandNode.moveStartTime)
        }
        if !rightHandNode.isMoving {
            rightHandNode.moveStartTime = time  // keep updating until hand moving
        } else {
            moveHandNode(rightHandNode, deltaTime: time - rightHandNode.moveStartTime)
        }
        // if ball is in hand, turn off physics body and move with hand
        switch ballNode.location {
        case .leftHand:
            ballNode.physicsBody = nil
            ballNode.position = leftHandNode.position + Constants.ballPositionRelativeToHand
        case .rightHand:
            ballNode.physicsBody = nil
            ballNode.position = rightHandNode.position + Constants.ballPositionRelativeToHand
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
