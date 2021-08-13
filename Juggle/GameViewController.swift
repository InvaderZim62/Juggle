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
    static let radius: CGFloat = 0.8
}

struct Hands {
    static let distanceBetween: Float = 5.4
    static let rotationCenterVerticalOffset: Float = -6.0  // from screen center
    static let rotationRate = 300.rads  // rotation rate around center of ellipse
    static let initialAngle = 90.rads  // initial angle of hand about center of ellipse, zero along ellipse major-axis, positive ccw
}

struct ContactCategory {  // bit masks for contact detection
    static let hand = 1 << 0
    static let ball = 1 << 1
}

class GameViewController: UIViewController {
    
    var ballCount = 3
    var ballReleaseInterval = 1.1  // seconds between releasing the initial balls (alternating right-left hands)
    var ballReleaseAngle = 220.rads  // angle of hand about center of ellipse at ball release, zero along ellipse major-axis, positive ccw
    var ellipseMajorAxis = 3.0
    var ellipseMinorAxis = 1.0
    var ellipseTilt = 60.rads  // rotation of ellipse major axis from screen x-axis, positive ccw
    
    private var scnView: SCNView!
    private var scnScene: SCNScene!
    private var cameraNode: SCNNode!
    
    private var leftHandNode: HandNode!
    private var rightHandNode: HandNode!
    private var ballNodes = [BallNode]()
    private var leftHandRotationCenter = SCNVector3()
    private var rightHandRotationCenter = SCNVector3()
    private var ballSpawnTime: TimeInterval = 0
    
    private var ballPositionRelativeToHand: SCNVector3 {
        return SCNVector3(x: 0, y: Float(Ball.radius), z: 0)
    }
    
    // MARK: - Start of Code

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        setupCamera()
        addHandNodes()
    }
    
    private func addHandNodes() {
        leftHandRotationCenter = SCNVector3(x: -Hands.distanceBetween / 2, y: Hands.rotationCenterVerticalOffset, z: 0)
        leftHandNode = HandNode(isLeft: true)
        leftHandNode.position = leftHandRotationCenter + ellipticalPosition(angle: Hands.initialAngle, tilt: ellipseTilt)
        scnScene.rootNode.addChildNode(leftHandNode)
        
        rightHandRotationCenter = SCNVector3(x: Hands.distanceBetween / 2, y: Hands.rotationCenterVerticalOffset, z: 0)
        rightHandNode = HandNode(isLeft: false)
        rightHandNode.position = rightHandRotationCenter + ellipticalPosition(angle: Hands.initialAngle, tilt: -ellipseTilt)
        scnScene.rootNode.addChildNode(rightHandNode)
    }

    private func addBallNode() {
        let ballNode = BallNode()
        ballNode.position = (ballNodes.count.isEven ? rightHandNode.position : leftHandNode.position) + ballPositionRelativeToHand
//        if ballNodes.count == 0 { ballNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow }
        ballNodes.append(ballNode)
        scnScene.rootNode.addChildNode(ballNode)
    }
    
    private func moveHandNode(_ handNode: HandNode, deltaTime: Double) {
        let ellipseTilt = handNode.isLeft ? ellipseTilt : -ellipseTilt
        let rotationRate = handNode.isLeft ? Hands.rotationRate : -Hands.rotationRate  // left hand ccw, right hand cw
        let rotationCenter = handNode.isLeft ? leftHandRotationCenter : rightHandRotationCenter

        let deltaAngle = deltaTime * rotationRate  // radians
        let angle = Hands.initialAngle + deltaAngle  // start hand along ellipse minor-axis
        if abs(deltaAngle) < 360.rads {  // move hand around complete loop
            handNode.position = rotationCenter + ellipticalPosition(angle: angle, tilt: ellipseTilt)
        } else {
            handNode.isMoving = false
            handNode.position = rotationCenter + ellipticalPosition(angle: Hands.initialAngle, tilt: ellipseTilt)  // return to start (should be there)
        }
        if abs(deltaAngle) > ballReleaseAngle {  // release ball just past negative minor axis
            handNode.ballNode.location = .inAir
        }
    }
    
    // return position relative to center of ellipse
    // angle is angle about ellipse center (ccw from major-axis)
    // tilt is angle of ellipse major-axis (ccw from screen x-axis)
    private func ellipticalPosition(angle: Double, tilt: Double) -> SCNVector3 {
        let x = ellipseMajorAxis * cos(angle) * cos(tilt) - ellipseMinorAxis * sin(angle) * sin(tilt)
        let y = ellipseMajorAxis * cos(angle) * sin(tilt) + ellipseMinorAxis * sin(angle) * cos(tilt)
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

// detect contact between dominos, to play click sound (requires scnScene.physicsWorld.contactDelegate = self)
extension GameViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let contactMask = contact.nodeA.physicsBody!.categoryBitMask | contact.nodeB.physicsBody!.categoryBitMask
        switch contactMask {
        case ContactCategory.hand | ContactCategory.ball:
            if let handNode = contact.nodeA as? HandNode, let ballNode = contact.nodeB as? BallNode {
                handNode.isMoving = true
                handNode.ballNode = ballNode
                ballNode.location = handNode.isLeft ? .leftHand : .rightHand
            } else if let handNode = contact.nodeB as? HandNode, let ballNode = contact.nodeA as? BallNode {
                handNode.isMoving = true
                handNode.ballNode = ballNode
                ballNode.location = handNode.isLeft ? .leftHand : .rightHand
            }
        default:
            break
        }
    }
}

var first = false  // skip first release interval

extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if time > ballSpawnTime && ballNodes.count < ballCount {
            if first { addBallNode() }
            first = true
            ballSpawnTime = time + TimeInterval(ballReleaseInterval)
        }
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
        // if ball is in hand, move with hand
        for ballNode in ballNodes {
            switch ballNode.location {
            case .leftHand:
                ballNode.position = leftHandNode.position + ballPositionRelativeToHand
            case .rightHand:
                ballNode.position = rightHandNode.position + ballPositionRelativeToHand
            default:
                break
            }
        }
    }
}
