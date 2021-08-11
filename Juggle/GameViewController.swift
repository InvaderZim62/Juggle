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
    static let handRotationCenter = SCNVector3(x: 2, y: -6, z: 0)
    static let handRotationTilt = -60.rads  // zero along x-axis, positive ccw
    static let initialHandTheta = 90.rads  // zero along major-axis, positive ccw
}

class GameViewController: UIViewController {

    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    
    var ballNode: SCNNode!
    var handNode: SCNNode!
    
    var moveHandStartTime: TimeInterval = 0
    var isHandMoving = false
    var isBallInHand = false
    
    let ballNodePhysicsBody: SCNPhysicsBody = {  // set property with a closure
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        physicsBody.restitution = 0  // no bounce
        physicsBody.categoryBitMask = ContactCategory.ball
        physicsBody.contactTestBitMask = ContactCategory.hand
        return physicsBody
    }()

    struct ContactCategory {  // bit masks for contact detection
        static let hand = 1 << 0
        static let ball = 1 << 1
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        setupCamera()
        addHandNode()
        addBallNode()
    }
    
    private func addHandNode() {
        let hand = SCNBox(width: 1, height: 0.3, length: 1, chamferRadius: 0)
        hand.firstMaterial?.diffuse.contents = UIColor.white
        handNode = SCNNode(geometry: hand)
        handNode.position = Constants.handRotationCenter + ellipticalPosition(theta: Constants.initialHandTheta, tilt: Constants.handRotationTilt)
        handNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        handNode.physicsBody?.categoryBitMask = ContactCategory.hand
        handNode.physicsBody?.contactTestBitMask = ContactCategory.ball
        scnScene.rootNode.addChildNode(handNode)
    }

    private func addBallNode() {
        let ball = SCNSphere(radius: Constants.ballRadius)
        ball.firstMaterial?.diffuse.contents = UIColor.red
        ballNode = SCNNode(geometry: ball)
        ballNode.position = handNode.position + Constants.ballPositionRelativeToHand
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        ballNode.physicsBody?.restitution = 0  // no bounciness
        ballNode.physicsBody?.categoryBitMask = ContactCategory.ball
        ballNode.physicsBody?.contactTestBitMask = ContactCategory.hand
        scnScene.rootNode.addChildNode(ballNode)
    }
    
    private func moveHand(deltaTime: Double) {
        let rotationRate = -300.rads  // rads/sec
        let deltaTheta = deltaTime * rotationRate  // rads, angle of hand about center, zero along major-axis, positive ccw
        let theta = Constants.initialHandTheta + deltaTheta  // start along minor-axis
        if abs(deltaTheta) < 360.rads {  // full loop
            handNode.position = Constants.handRotationCenter + ellipticalPosition(theta: theta, tilt: Constants.handRotationTilt)
        } else {
            isHandMoving = false
            handNode.position = Constants.handRotationCenter + ellipticalPosition(theta: Constants.initialHandTheta, tilt: Constants.handRotationTilt)
        }
        if abs(deltaTheta) > 180.rads {  // 1/2 loop (negative minor axis)
            isBallInHand = false
        }
        print(deltaTime, deltaTheta.degs, theta.degs, isBallInHand)
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
        if !isHandMoving {
            moveHandStartTime = time  // keep updating until hand moving
        } else {
            moveHand(deltaTime: time - moveHandStartTime)
        }
        // if ball is in hand, turn off physics body and move with hand
        ballNode.physicsBody = isBallInHand ? nil : ballNodePhysicsBody
        if isBallInHand {
            ballNode.position = handNode.position + Constants.ballPositionRelativeToHand
        }
    }
}

// detect contact between dominos, to play click sound (requires scnScene.physicsWorld.contactDelegate = self)
extension GameViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let contactMask = contact.nodeA.physicsBody!.categoryBitMask | contact.nodeB.physicsBody!.categoryBitMask
        switch contactMask {
        case ContactCategory.hand | ContactCategory.ball:
            print(".", terminator: "")
            isHandMoving = true
            isBallInHand = true
        default:
            break
        }
    }
}
