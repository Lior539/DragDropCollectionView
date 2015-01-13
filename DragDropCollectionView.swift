//
//  DragDropCollectionView.swift
//  DragDrop
//
//  Created by Lior Neu-ner on 2014/12/30.
//  Copyright (c) 2014 LiorN. All rights reserved.
//

import UIKit

@objc protocol DrapDropCollectionViewDelegate: UICollectionViewDelegate {
    func dragDropCollectionViewDidMoveCellFromInitialIndexPath(initialIndexPath: NSIndexPath, toNewIndexPath newIndexPath: NSIndexPath)
    optional func dragDropCollectionViewDraggingDidBeginWithCellAtIndexPath(indexPath: NSIndexPath)
    optional func dragDropCollectionViewDraggingDidEndForCellAtIndexPath(indexPath: NSIndexPath)
}

class DragDropCollectionView: UICollectionView, UIGestureRecognizerDelegate {
    var draggingDelegate: DrapDropCollectionViewDelegate?
    private var longPressRecognizer: UILongPressGestureRecognizer!
    private var draggedCellIndexPath: NSIndexPath?
    private var draggingView: UIView?
    private var touchOffsetFromCenterOfCell: CGPoint?
    private let pingInterval = 0.3
    
    override init() {
        super.init()
        commonInit()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        commonInit()
    }
    
    private func commonInit() {
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: Selector("handleLongPress:"))
        longPressRecognizer.delaysTouchesBegan = true
        longPressRecognizer.cancelsTouchesInView = false
        longPressRecognizer.numberOfTouchesRequired = 1
        longPressRecognizer.delegate = self
        longPressRecognizer.minimumPressDuration = 0.1
        longPressRecognizer.allowableMovement = 10.0
        longPressRecognizer.enabled = false
        self.addGestureRecognizer(longPressRecognizer)
    }
    
    func handleLongPress(longPressRecognizer: UILongPressGestureRecognizer) {
        let touchLocation = longPressRecognizer.locationInView(self)
        if (longPressRecognizer.state == UIGestureRecognizerState.Began) {
            draggedCellIndexPath = self.indexPathForItemAtPoint(touchLocation)
            if (draggedCellIndexPath? != nil) {
                draggingDelegate?.dragDropCollectionViewDraggingDidBeginWithCellAtIndexPath?(draggedCellIndexPath!)
                let draggedCell = self.cellForItemAtIndexPath(draggedCellIndexPath!) as UICollectionViewCell!
                draggingView = UIImageView(image: getRasterizedImageCopyOfCell(draggedCell))
                draggingView!.center = draggedCell.center
                self.addSubview(draggingView!)
                draggedCell.alpha = 0.0
                touchOffsetFromCenterOfCell = CGPoint(x: draggedCell.center.x - touchLocation.x, y: draggedCell.center.y - touchLocation.y)
                UIView.animateWithDuration(0.4, animations: { () -> Void in
                    self.draggingView!.transform = CGAffineTransformMakeScale(1.3, 1.3)
                    self.draggingView!.alpha = 0.8
                })
            }
        }
        
        if (longPressRecognizer.state == UIGestureRecognizerState.Changed) {
            if draggedCellIndexPath != nil {
                draggingView!.center = CGPoint(x: touchLocation.x + touchOffsetFromCenterOfCell!.x, y: touchLocation.y + touchOffsetFromCenterOfCell!.y)
                let previousTouchLocation = longPressRecognizer.locationInView(self)
                dispatchOnMainQueueAfterDelay(pingInterval, { () -> () in
                    let currentTouchLocation = self.longPressRecognizer.locationInView(self)
                    if currentTouchLocation.x != NSDecimalNumber.notANumber() && currentTouchLocation.y != NSDecimalNumber.notANumber() {
                        if distanceBetweenPoints(previousTouchLocation, currentTouchLocation) < CGFloat(20.0) {
                            if let newIndexPathForCell = self.indexPathForItemAtPoint(currentTouchLocation) {
                                if newIndexPathForCell != self.draggedCellIndexPath! {
                                    self.draggingDelegate?.dragDropCollectionViewDidMoveCellFromInitialIndexPath(self.draggedCellIndexPath!, toNewIndexPath: newIndexPathForCell)
                                    self.moveItemAtIndexPath(self.draggedCellIndexPath!, toIndexPath: newIndexPathForCell)
                                    let draggedCell = self.cellForItemAtIndexPath(newIndexPathForCell)!
                                    draggedCell.alpha = 0
                                    self.draggedCellIndexPath = newIndexPathForCell
                                }
                            }
                        }
                    }
                })
            }
        }
        
        if (longPressRecognizer.state == UIGestureRecognizerState.Ended) {
            if draggedCellIndexPath != nil {
                draggingDelegate?.dragDropCollectionViewDraggingDidEndForCellAtIndexPath?(draggedCellIndexPath!)
                let draggedCell = self.cellForItemAtIndexPath(draggedCellIndexPath!)!
                UIView.animateWithDuration(0.4, animations: { () -> Void in
                    self.draggingView!.transform = CGAffineTransformIdentity
                    self.draggingView!.alpha = 1.0
                    self.draggingView!.center = draggedCell.center
                }, completion: { (finished) -> Void in
                    self.draggingView!.removeFromSuperview()
                    self.draggingView = nil
                    draggedCell.alpha = 1.0
                    self.draggedCellIndexPath = nil
                })
            }
        }
    }
    
    func enableDragging(enable: Bool) {
        if enable {
            longPressRecognizer.enabled = true
        } else {
            longPressRecognizer.enabled = false
        }
    }
}

//Wiggle Animation
extension DragDropCollectionView {
    func startWiggle() {
        CATransaction.begin()
        for cell in visibleCells() {
            cell.layer.addAnimation(rotationAnimation(), forKey: "rotation")
            cell.layer.addAnimation(bounceAnimation(), forKey: "bounce")
        }
        CATransaction.commit()
    }
    
    func stopWiggle() {
        CATransaction.begin()
        for cell in visibleCells() {
            cell.layer.removeAllAnimations()
        }
        CATransaction.commit()
    }
    
    private func rotationAnimation() -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        let angle = CGFloat(0.06)
        let duration = NSTimeInterval(0.1)
        let variance = Double(0.025)
        animation.values = [angle, -angle]
        animation.autoreverses = true
        animation.duration = self.randomizeInterval(duration, withVariance: variance)
        animation.repeatCount = Float.infinity
        return animation
    }
    
    private func bounceAnimation() -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        let bounce = CGFloat(2.0)
        let duration = NSTimeInterval(0.12)
        let variance = Double(0.025)
        animation.values = [bounce, -bounce]
        animation.autoreverses = true
        animation.duration = self.randomizeInterval(duration, withVariance: variance)
        animation.repeatCount = Float.infinity
        return animation
    }
    
    private func randomizeInterval(interval: NSTimeInterval, withVariance variance:Double) -> NSTimeInterval {
        let random = (Double(arc4random_uniform(1000)) - 500.0) / 500.0
        return interval + variance * random;
    }
}

//Assisting Functions
extension DragDropCollectionView {
    private func getRasterizedImageCopyOfCell(cell: UICollectionViewCell) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(cell.bounds.size, cell.opaque, 0.0)
        cell.layer.renderInContext(UIGraphicsGetCurrentContext())
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

}

public func dispatchOnMainQueueAfterDelay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

public func distanceBetweenPoints(firstPoint: CGPoint, secondPoint: CGPoint) -> CGFloat {
    let xDistance = firstPoint.x - secondPoint.x
    let yDistance = firstPoint.y - secondPoint.y
    return sqrt(xDistance * xDistance + yDistance * yDistance)
}






