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
    static let handInitialYPosition: Float = -6
}

class GameViewController: UIViewController {

    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    
    var ballNode: SCNNode!
    var handNode: SCNNode!
    
    var isBallInHand = false
    var isBallInHandPast = false
    var moveHandStartTime: TimeInterval = 0

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
        handNode.position = SCNVector3(x: 0, y: Constants.handInitialYPosition, z: 0)
        handNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        handNode.physicsBody?.categoryBitMask = ContactCategory.hand
        handNode.physicsBody?.contactTestBitMask = ContactCategory.ball
        scnScene.rootNode.addChildNode(handNode)
    }

    private func addBallNode() {
        let ball = SCNSphere(radius: Constants.ballRadius)
        ball.firstMaterial?.diffuse.contents = UIColor.red
        ballNode = SCNNode(geometry: ball)
        ballNode.position = SCNVector3(x: 0, y: 10, z: 0)
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        ballNode.physicsBody?.restitution = 0  // no bounciness
        ballNode.physicsBody?.categoryBitMask = ContactCategory.ball
        ballNode.physicsBody?.contactTestBitMask = ContactCategory.hand
        scnScene.rootNode.addChildNode(ballNode)
    }
    
    private func moveHand(deltaTime: Double) {
        let frequency = 1 + 2 * deltaTime  // speeds up with time
        let amplitude = 3.0
        if deltaTime < 2 * Double.pi / frequency {  // one cycle
            let deltaPosition = Float(amplitude * sin(-frequency * deltaTime))
            handNode.position.y = Constants.handInitialYPosition + deltaPosition
        } else {
            isBallInHand = false
            handNode.position.y = Constants.handInitialYPosition
        }
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
        if isBallInHand {
            if !isBallInHandPast {
                moveHandStartTime = time  // save time on transistion to isBallInHand
            }
            moveHand(deltaTime: time - moveHandStartTime)
        }
        isBallInHandPast = isBallInHand
    }
}

// detect contact between dominos, to play click sound (requires scnScene.physicsWorld.contactDelegate = self)
extension GameViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let contactMask = contact.nodeA.physicsBody!.categoryBitMask | contact.nodeB.physicsBody!.categoryBitMask
        switch contactMask {
        case ContactCategory.hand | ContactCategory.ball:
            print(".", terminator: "")
            isBallInHand = true
        default:
            break
        }
    }
}
