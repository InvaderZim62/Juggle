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
}

class GameViewController: UIViewController {

    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    
    var ballNode: SCNNode!
    var handNode: SCNNode!

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
        let handNode = SCNNode(geometry: hand)
        handNode.position = SCNVector3(x: 0, y: -6, z: 0)
        handNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        scnScene.rootNode.addChildNode(handNode)
    }

    private func addBallNode() {
        let ball = SCNSphere(radius: Constants.ballRadius)
        ball.firstMaterial?.diffuse.contents = UIColor.red
        let ballNode = SCNNode(geometry: ball)
        ballNode.position = SCNVector3(x: 0, y: 10, z: 0)
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        scnScene.rootNode.addChildNode(ballNode)
    }

    // MARK: - Setup
    
    private func setupView() {
        scnView = self.view as? SCNView
        scnView.showsStatistics = true
        scnView.allowsCameraControl = true  // use standard camera controls with swiping
        scnView.showsStatistics = false
        scnView.autoenablesDefaultLighting = true
        scnView.isPlaying = true  // prevent SceneKit from entering a "paused" state, if there isn't anything to animate
    }
    
    private func setupScene() {
        scnScene = SCNScene()
        scnScene.background.contents = "Background_Diffuse.png"
        scnView.scene = scnScene
    }
    
    private func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 30)
        scnScene.rootNode.addChildNode(cameraNode)
    }
}
