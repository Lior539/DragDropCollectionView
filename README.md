# DragDropCollectionView
A UICollectionView which allows for easy drag and drop to reorder cells. Mimicks the drag and drop on the iOS Springboard when reordering apps (wiggle animation included!)

![Alt text](/demo.gif)

Installation
--------------

To use the DragDropCollectionView class in an app, just drag the DragDropCollectionView.swift file into your project.

Protocols and Delegates
--------------
DragDropCollectionView has the following protocol:  

````
@objc protocol DrapDropCollectionViewDelegate: UICollectionViewDelegate
````

This inherits from UICollectionViewDelegate and is to be used in place of the '.delegate' property found in UICollectionView

DragDropCollectionView has the following delegate:  

````
var draggingDelegate: DrapDropCollectionViewDelegate?
````

The DragDropCollectionViewDelegate has the following required methods:

````
func dragDropCollectionViewDidMoveCellFromInitialIndexPath(initialIndexPath: NSIndexPath, toNewIndexPath newIndexPath: NSIndexPath)
````

This method should be used in your to 'swap' items in your datasource

The DragDropCollectionViewDelegate has the following optional methods:

````
optional func dragDropCollectionViewDraggingDidBeginWithCellAtIndexPath(indexPath: NSIndexPath)
optional func dragDropCollectionViewDraggingDidEndForCellAtIndexPath(indexPath: NSIndexPath)
````
    

Methods
--------------
Dragging can be easily enabled and disabled using the follwing method:
func enableDragging(enable: Bool)

To start the wiggle animation, use:

````
func startWiggle()
````

To stop the wiggle animation, use:

````
func stopWiggle()
````
