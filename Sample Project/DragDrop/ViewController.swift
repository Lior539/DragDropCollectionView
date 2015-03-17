//
//  ViewController.swift
//  DragDrop
//
//  Created by Lior Neu-ner on 2014/12/30.
//  Copyright (c) 2014 LiorN. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, DrapDropCollectionViewDelegate {
    @IBOutlet var dragDropCollectionView: DragDropCollectionView!
    var colors: [UIColor] = {
        var randomColors = [UIColor]()
        for i in 1...500 {
            let randomRed = CGFloat(arc4random() % 255) / 255.0
            let randomGreen = CGFloat(arc4random() % 255) / 255.0
            let randomBlue = CGFloat(arc4random() % 255) / 255.0
            randomColors.append(UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0))
        }
        return randomColors
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dragDropCollectionView.draggingDelegate = self
        dragDropCollectionView.enableDragging(true)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionViewCell", forIndexPath: indexPath) as UICollectionViewCell
        cell.backgroundColor = colors[indexPath.row]
        return cell
    }
    
    func dragDropCollectionViewDidMoveCellFromInitialIndexPath(initialIndexPath: NSIndexPath, toNewIndexPath newIndexPath: NSIndexPath) {
        let colorToMove = colors[initialIndexPath.row]
        colors.removeAtIndex(initialIndexPath.row)
        colors.insert(colorToMove, atIndex: newIndexPath.row)
    }
    
    @IBAction func toggleWiggle(sender: UISwitch) {
        if sender.on {
            dragDropCollectionView.startWiggle()
        } else {
            dragDropCollectionView.stopWiggle()
        }
    }
}













