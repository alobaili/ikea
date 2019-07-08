//
//  ViewController.swift
//  ikea
//
//  Created by Abdulaziz AlObaili on 02/07/2019.
//  Copyright © 2019 Abdulaziz Alobaili. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    override var prefersStatusBarHidden: Bool { return true }
    @IBOutlet weak var planeDetectedLabel: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var itemsCollectionView: UICollectionView!
    let itemsArray: [String] = ["cup", "vase", "boxing", "table"]
    var selectedItem: String?
    let configuration  = ARWorldTrackingConfiguration()
    var selectedNode: SCNNode? {
        didSet {
            print("new object selected")
        }
    }
    let selectedAction: SCNAction = SCNAction.moveBy(x: 0, y: 0.1, z: 0, duration: 0.1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configuration.planeDetection = .horizontal
//        sceneView.debugOptions = [.showWorldOrigin, .showFeaturePoints]
        sceneView.session.run(configuration)
        sceneView.autoenablesDefaultLighting = true
        sceneView.delegate = self
        itemsCollectionView.dataSource = self
        itemsCollectionView.delegate = self
        registerGestureRecognizers()
    }
    
    func registerGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rotate))
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        sceneView.addGestureRecognizer(pinchGestureRecognizer)
        sceneView.addGestureRecognizer(longPressGestureRecognizer)
        sceneView.addGestureRecognizer(rotationGestureRecognizer)
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        if !hitTest.isEmpty {
            addItem(hitTestResult: hitTest.first!)
        } else {
        }
    }
    
    @objc func pinch(sender: UIPinchGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let pinchLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(pinchLocation)
        
        if !hitTest.isEmpty {
            let results = hitTest.first!
            let node = results.node
            let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
            node.runAction(pinchAction)
            sender.scale = 1
        }
    }
    
    @objc func rotate(sender: UIRotationGestureRecognizer) {
        guard (selectedNode != nil) else { return }
        if sender.state == .changed {
            if sender.rotation < 0 { // clockwise
                let rotationAcrion = SCNAction.rotate(by: sender.rotation * 0.15, around: SCNVector3(0, selectedNode!.position.y, 0), duration: 0)
                selectedNode!.runAction(rotationAcrion)
            } else { // counterclockwise
                let rotationAcrion = SCNAction.rotate(by: sender.rotation * 0.15, around: SCNVector3(0, selectedNode!.position.y, 0), duration: 0)
                selectedNode!.runAction(rotationAcrion)
            }
        }
        if sender.state == .ended {
            deselectNode()
        }
    }
    
    @objc func longPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let sceneView = sender.view as! ARSCNView
            let longPressLocation = sender.location(in: sceneView)
            let hitTest = sceneView.hitTest(longPressLocation)
            
            if !hitTest.isEmpty {
                let resultNode = hitTest.first!.node
                if resultNode != selectedNode {
                    deselectNode()
                    selectedNode = resultNode
                    sender.isEnabled = false
                    selectedNode?.runAction(selectedAction)
                } else {
                    print("node already selected")
                }
            }
        } else {
            sender.isEnabled = true
        }
    }
    
    func addItem(hitTestResult: ARHitTestResult) {
        guard let selectedItem = selectedItem else { return }
        
        let scene = SCNScene(named: "Models.scnassets/\(selectedItem).scn")
        let node  = scene?.rootNode.childNode(withName: selectedItem, recursively: false)
        let transform = hitTestResult.worldTransform
        // the position of a detected surface is stored in the third column
        let thirdColumn = transform.columns.3
        node?.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
        sceneView.scene.rootNode.addChildNode(node!)
    }
    
    func deselectNode() {
        selectedNode?.runAction(selectedAction.reversed())
        selectedNode = nil
    }

}

extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath) as! ItemCollectionViewCell
        cell.itemLabel.text = itemsArray[indexPath.row]
        return cell
    }
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        selectedItem = itemsArray[indexPath.row]
        cell?.backgroundColor = .green
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor(rgb: 0xFF9300)
    }
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
        DispatchQueue.main.async {
            self.planeDetectedLabel.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.planeDetectedLabel.isHidden = true
            }
        }
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}
