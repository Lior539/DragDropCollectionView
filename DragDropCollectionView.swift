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
    
    private var longPressRecognizer: UILongPressGestureRecognizer = {
        let longPressRecognizer = UILongPressGestureRecognizer()
        longPressRecognizer.delaysTouchesBegan = false
        longPressRecognizer.cancelsTouchesInView = false
        longPressRecognizer.numberOfTouchesRequired = 1
        longPressRecognizer.minimumPressDuration = 0.1
        longPressRecognizer.allowableMovement = 10.0
        return longPressRecognizer
    }()
    
    private var draggedCellIndexPath: NSIndexPath?
    private var draggingView: UIView?
    private var touchOffsetFromCenterOfCell: CGPoint?
    private var isWiggling = false
    private let pingInterval = 0.3
    private var isAutoScrolling = false
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        commonInit()
    }
    
    private func commonInit() {
        longPressRecognizer.addTarget(self, action: "handleLongPress:")
        longPressRecognizer.enabled = false
        self.addGestureRecognizer(longPressRecognizer)
        
    }
    
    override func intrinsicContentSize() -> CGSize {
        self.layoutIfNeeded()
        return CGSize(width: UIViewNoIntrinsicMetric, height: self.contentSize.height)
    }
    
    override func reloadData() {
        super.reloadData()
        self.invalidateIntrinsicContentSize()
    }
    
    func handleLongPress(longPressRecognizer: UILongPressGestureRecognizer) {
        let touchLocation = longPressRecognizer.locationInView(self)
        
        switch (longPressRecognizer.state) {
        case UIGestureRecognizerState.Began:
            draggedCellIndexPath = self.indexPathForItemAtPoint(touchLocation)
            if (draggedCellIndexPath != nil) {
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
            
        case UIGestureRecognizerState.Changed:
            if draggedCellIndexPath != nil {
                draggingView!.center = CGPoint(x: touchLocation.x + touchOffsetFromCenterOfCell!.x, y: touchLocation.y + touchOffsetFromCenterOfCell!.y)

                if !isAutoScrolling {

                    dispatchOnMainQueueAfterDelay(pingInterval, { () -> () in
                        let scroller = self.shouldAutoScroll(previousTouchLocation: touchLocation)
                        if  (scroller.shouldScroll) {
                            self.autoScroll(scroller.direction)
                            self.isAutoScrolling = true
                        }
                    })
                }
                
                dispatchOnMainQueueAfterDelay(pingInterval, { () -> () in
                    let shouldSwapCellsTuple = self.shouldSwapCells(previousTouchLocation: touchLocation)
                    if shouldSwapCellsTuple.shouldSwap {
                        self.swapDraggedCellWithCellAtIndexPath(shouldSwapCellsTuple.newIndexPath!)
                    }
                })
            }
        case UIGestureRecognizerState.Ended:
            if draggedCellIndexPath != nil {
                draggingDelegate?.dragDropCollectionViewDraggingDidEndForCellAtIndexPath?(draggedCellIndexPath!)
                let draggedCell = self.cellForItemAtIndexPath(draggedCellIndexPath!)
                UIView.animateWithDuration(0.4, animations: { () -> Void in
                    self.draggingView!.transform = CGAffineTransformIdentity
                    self.draggingView!.alpha = 1.0
                    if (draggedCell != nil) {
                        self.draggingView!.center = draggedCell!.center
                    }
                }, completion: { (finished) -> Void in
                    self.draggingView!.removeFromSuperview()
                    self.draggingView = nil
                    draggedCell?.alpha = 1.0
                    self.draggedCellIndexPath = nil
                })
            }
        default: ()
        }
    }
    
    
    func enableDragging(enable: Bool) {
        if enable {
            longPressRecognizer.enabled = true
        } else {
            longPressRecognizer.enabled = false
        }
    }
    
    private func shouldSwapCells(#previousTouchLocation: CGPoint) -> (shouldSwap: Bool, newIndexPath: NSIndexPath?) {
        var shouldSwap = false
        var newIndexPath: NSIndexPath?
        let currentTouchLocation = self.longPressRecognizer.locationInView(self)
        if currentTouchLocation.x != NSDecimalNumber.notANumber() && currentTouchLocation.y != NSDecimalNumber.notANumber() {
            if distanceBetweenPoints(previousTouchLocation, currentTouchLocation) < CGFloat(20.0) {
                if let newIndexPathForCell = self.indexPathForItemAtPoint(currentTouchLocation) {
                    if newIndexPathForCell != self.draggedCellIndexPath! {
                        shouldSwap = true
                        newIndexPath = newIndexPathForCell
                    }
                }
            }
        }
        return (shouldSwap, newIndexPath)
    }
    
    private func swapDraggedCellWithCellAtIndexPath(newIndexPath: NSIndexPath) {
        self.moveItemAtIndexPath(self.draggedCellIndexPath!, toIndexPath: newIndexPath)
        let draggedCell = self.cellForItemAtIndexPath(newIndexPath)!
        draggedCell.alpha = 0
        self.draggingDelegate?.dragDropCollectionViewDidMoveCellFromInitialIndexPath(self.draggedCellIndexPath!, toNewIndexPath: newIndexPath)
        self.draggedCellIndexPath = newIndexPath
    }
    

}

//AutoScroll
extension DragDropCollectionView {
    enum AutoScrollDirection: Int {
        case Invalid = 0
        case TowardsOrigin = 1
        case AwayFromOrigin = 2
    }
    
    private func autoScroll(direction: AutoScrollDirection) {
        let currentLongPressTouchLocation = self.longPressRecognizer.locationInView(self)
        var increment: CGFloat
        var newContentOffset: CGPoint
        if (direction == AutoScrollDirection.TowardsOrigin) {
            increment = -50.0
        } else {
            increment = 50.0
        }
        newContentOffset = CGPoint(x: self.contentOffset.x, y: self.contentOffset.y + increment)
        if ((direction == AutoScrollDirection.TowardsOrigin && newContentOffset.y < 0) || (direction == AutoScrollDirection.AwayFromOrigin && newContentOffset.y > self.contentSize.height - self.frame.height)) {
            dispatchOnMainQueueAfterDelay(0.3, { () -> () in
                self.isAutoScrolling = false
            })
        } else {
            UIView.animateWithDuration(0.3
                , delay: 0.0
                , options: UIViewAnimationOptions.CurveLinear
                , animations: { () -> Void in
                    self.setContentOffset(newContentOffset, animated: false)
                    if (self.draggingView != nil) {
                        var draggingFrame = self.draggingView!.frame
                        draggingFrame.origin.y += increment
                        self.draggingView!.frame = draggingFrame
                    }
                }) { (finished) -> Void in
                    dispatchOnMainQueueAfterDelay(0.0, { () -> () in
                        let updatedTouchLocationWithNewOffset = CGPoint(x: currentLongPressTouchLocation.x, y: currentLongPressTouchLocation.y + increment)
                        let scroller = self.shouldAutoScroll(previousTouchLocation: updatedTouchLocationWithNewOffset)
                        if scroller.shouldScroll {
                            self.autoScroll(scroller.direction)
                        } else {
                            self.isAutoScrolling = false
                        }
                    })
            }
        }
    }
    
    private func shouldAutoScroll(#previousTouchLocation: CGPoint) -> (shouldScroll: Bool, direction: AutoScrollDirection) {
        let previousTouchLocation = self.convertPoint(previousTouchLocation, toView: self.superview)
        let currentTouchLocation = self.longPressRecognizer.locationInView(self.superview)

        if let flowLayout = self.collectionViewLayout as? UICollectionViewFlowLayout {
            if currentTouchLocation.x != NSDecimalNumber.notANumber() && currentTouchLocation.y != NSDecimalNumber.notANumber() {
                if distanceBetweenPoints(previousTouchLocation, currentTouchLocation) < CGFloat(20.0) {
                    let scrollDirection = flowLayout.scrollDirection
                    var scrollBoundsSize: CGSize
                    let scrollBoundsLength: CGFloat = 50.0
                    var scrollRectAtEnd: CGRect
                    switch scrollDirection {
                    case UICollectionViewScrollDirection.Horizontal:
                        scrollBoundsSize = CGSize(width: scrollBoundsLength, height: self.frame.height)
                        scrollRectAtEnd = CGRect(x: self.frame.origin.x + self.frame.width - scrollBoundsSize.width , y: self.frame.origin.y, width: scrollBoundsSize.width, height: self.frame.height)
                    case UICollectionViewScrollDirection.Vertical:
                        scrollBoundsSize = CGSize(width: self.frame.width, height: scrollBoundsLength)
                        scrollRectAtEnd = CGRect(x: self.frame.origin.x, y: self.frame.origin.y + self.frame.height - scrollBoundsSize.height, width: self.frame.width, height: scrollBoundsSize.height)
                    }
                    let scrollRectAtOrigin = CGRect(origin: self.frame.origin, size: scrollBoundsSize)
                    if scrollRectAtOrigin.contains(currentTouchLocation) {
                        return (true, AutoScrollDirection.TowardsOrigin)
                    } else if scrollRectAtEnd.contains(currentTouchLocation) {
                        return (true, AutoScrollDirection.AwayFromOrigin)
                    }
                }
            }
        }
        return (false, AutoScrollDirection.Invalid)
    }
}

//Wiggle Animation
extension DragDropCollectionView {
    func startWiggle() {
        for cell in visibleCells() {
            addWiggleAnimationToCell(cell as! UICollectionViewCell)
        }
        isWiggling = true
    }
    
    func stopWiggle() {
        for cell in visibleCells() {
            cell.layer.removeAllAnimations()
        }
        isWiggling = false
    }
    
    override func dequeueReusableCellWithReuseIdentifier(identifier: String, forIndexPath indexPath: NSIndexPath!) -> AnyObject {
        let cell: AnyObject = super.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath)
        if isWiggling {
            addWiggleAnimationToCell(cell as! UICollectionViewCell)
        }
        return cell
    }
    
    func addWiggleAnimationToCell(cell: UICollectionViewCell) {
        CATransaction.begin()
        CATransaction.setDisableActions(false)
        cell.layer.addAnimation(rotationAnimation(), forKey: "rotation")
        cell.layer.addAnimation(bounceAnimation(), forKey: "bounce")
        CATransaction.commit()
    }
    
    private func rotationAnimation() -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        let angle = CGFloat(0.04)
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
        let bounce = CGFloat(3.0)
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
        UIGraphicsBeginImageContextWithOptions(cell.bounds.size, false, 0.0)
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






