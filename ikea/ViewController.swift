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
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var itemsCollectionView: UICollectionView!
    let itemsArray: [String] = ["cup", "vase", "boxing", "table"]
    
    let configuration  = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.debugOptions = [.showWorldOrigin, .showFeaturePoints]
        sceneView.session.run(configuration)
        itemsCollectionView.dataSource = self
        itemsCollectionView.delegate = self
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
        cell?.backgroundColor = .green
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor(rgb: 0xFF9300)
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
