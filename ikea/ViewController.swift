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
    @IBOutlet weak var deleteButton: UIButton!
    let itemsArray: [String] = ["cup", "vase", "boxing", "table", "teapot", "super-camputer"]
    var selectedItem: String?
    let configuration  = ARWorldTrackingConfiguration()
    var selectedNode: SCNNode? {
        didSet {
            print("new object selected")
        }
    }
    let selectedAction: SCNAction = SCNAction.moveBy(x: 0, y: 0.05, z: 0, duration: 0.1)
    
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
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan))
        panGestureRecognizer.maximumNumberOfTouches = 1
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        sceneView.addGestureRecognizer(pinchGestureRecognizer)
        sceneView.addGestureRecognizer(longPressGestureRecognizer)
        sceneView.addGestureRecognizer(rotationGestureRecognizer)
        sceneView.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        guard selectedNode == nil else { return }
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        if !hitTest.isEmpty {
            addItem(hitTestResult: hitTest.first!)
        } else {
        }
    }
    
    @objc func pinch(sender: UIPinchGestureRecognizer) {
        guard let selectedNode = selectedNode else { return }
        let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
        selectedNode.runAction(pinchAction)
        sender.scale = 1
    }
    
    @objc func rotate(sender: UIRotationGestureRecognizer) {
        guard let selectedNode = selectedNode else { return }
        if sender.state == .changed {
            if sender.rotation < 0 { // clockwise
                let rotationAcrion = SCNAction.rotate(by: sender.rotation * 0.15, around: SCNVector3(0, selectedNode.position.y, 0), duration: 0)
                selectedNode.runAction(rotationAcrion)
            } else { // counterclockwise
                let rotationAcrion = SCNAction.rotate(by: sender.rotation * 0.15, around: SCNVector3(0, selectedNode.position.y, 0), duration: 0)
                selectedNode.runAction(rotationAcrion)
            }
        }
    }
    
    @objc func pan(sender: UIPanGestureRecognizer) {
        if sender.state == .changed {
            guard let selectedNode = selectedNode else { return }
            let sceneView = sender.view as! ARSCNView
            let panLocation = sender.location(in: sceneView)
            let hitTest = sceneView.hitTest(panLocation, types: .existingPlaneUsingGeometry)
            
            if !hitTest.isEmpty {
                let result = hitTest.first!
                let thirdColumn = result.worldTransform.columns.3
                let position = SCNVector3(thirdColumn.x, thirdColumn.y + 0.05, thirdColumn.z)
                selectedNode.worldPosition = position
            }
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
                    deleteButton.isHidden = false
                } else {
                    deselectNode()
                }
            }
        } else {
            sender.isEnabled = true
        }
    }
    
    func addItem(hitTestResult: ARHitTestResult) {
        guard let selectedItem = selectedItem else { return }
        
        if selectedItem == "super-camputer" {
            let scene = SCNScene(named: "Models.scnassets/\(selectedItem).usdz")
            let node  = scene?.rootNode
            let transform = hitTestResult.worldTransform
            // the position of a detected surface is stored in the third column
            let thirdColumn = transform.columns.3
            node?.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
            sceneView.scene.rootNode.addChildNode(node!)
        } else {
            let scene = SCNScene(named: "Models.scnassets/\(selectedItem).scn")
            let node  = scene?.rootNode.childNode(withName: selectedItem, recursively: false)
            let transform = hitTestResult.worldTransform
            // the position of a detected surface is stored in the third column
            let thirdColumn = transform.columns.3
            node?.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
            sceneView.scene.rootNode.addChildNode(node!)
        }
    }
    
    @IBAction func deleteTapped(_ sender: Any) {
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            if node == self.selectedNode {
                node.removeFromParentNode()
            }
        }
        selectedNode = nil
        deleteButton.isHidden = true
    }
    
    
    func deselectNode() {
        selectedNode?.runAction(selectedAction.reversed())
        selectedNode = nil
        deleteButton.isHidden = true
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
