//
//  SliderCell.swift
//  GymRabbit
//
//  Created by Appiskey's iOS Dev on 7/19/19.
//  Copyright © 2019 Appiskey. All rights reserved.
//

import UIKit

public struct ImageCellData{
    public var imageURL: URL?
    public var imageInstance: UIImage?
    
    public init(imageURL: URL?, imageInstance: UIImage?) {
        if imageURL == nil && imageInstance == nil{
            fatalError("Both Image URL and image are not able to become nil at same time.")
        }
        self.imageURL = imageURL
        self.imageInstance = imageInstance
    }
}

class SliderView: UIView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var pageControl: UIPageControl!
    var view: UIView!

    var images : [ImageCellData] = []
    var currentIndex: Int = 0
    
    override init(frame: CGRect) {
        // 1. setup any properties here
        // 2. call super.init(frame:)
        super.init(frame: frame)
        // 3. Setup view from .xib file
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        // 1. setup any properties here
        // 2. call super.init(coder:)
        super.init(coder: aDecoder)
        // 3. Setup view from .xib file
        xibSetup()
    }
    
    func xibSetup() {
        
        view = loadViewFromNib()
        // use bounds not frame or it'll be offset
        view.frame = bounds
        // Make the view stretch with containing view
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        // Adding custom subview on top of our view (over any custom drawing > see note below)
        
        addSubview(view)
    }
    
    // Function for load Nib on TextBox
    func loadViewFromNib() -> UIView {
        
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "SliderView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view
    }
    
    func setupView(withImageObjects obj : [ImageCellData],
                   indicatorSelectedColor: UIColor,
                   indicatorUnSelectedColor: UIColor) {

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        pageControl.hidesForSinglePage = true
        self.images = obj
        self.pageControl.numberOfPages = obj.count
        self.pageControl.currentPageIndicatorTintColor = indicatorSelectedColor
        self.pageControl.pageIndicatorTintColor = indicatorUnSelectedColor
        if self.images.count != 0{
            self.setImage(obj: self.images[0])
        }
    }
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
       if gesture.direction == .right {
            self.movePrevious()
       }
       else if gesture.direction == .left {
            self.moveNext()
       }
    }
    
    func moveNext(){
        if self.currentIndex == images.count - 1 {
            return
        }
        self.currentIndex += 1
        self.imageView.image = nil
        let transition: CATransition = CATransition.init()
        transition.duration = 0.2
        transition.timingFunction = CAMediaTimingFunction.init(name: .linear)
        transition.type = .push
        transition.subtype = .fromRight
        imageView.layer.add(transition, forKey: nil)
        self.pageControl.currentPage = self.currentIndex
        self.setImage(obj: self.images[self.currentIndex])
    }
    
    func movePrevious(){
        if self.currentIndex == 0 {
            return
        }
        self.currentIndex -= 1
        self.imageView.image = nil
        let transition: CATransition = CATransition.init()
        transition.duration = 0.2
        transition.timingFunction = CAMediaTimingFunction.init(name: .linear)
        transition.type = .push
        transition.subtype = .fromLeft
        imageView.layer.add(transition, forKey: nil)
        self.pageControl.currentPage = self.currentIndex
        self.setImage(obj: self.images[self.currentIndex])
    }
    
    func setImage(obj: ImageCellData) {
        if obj.imageInstance != nil{
            self.imageView.image = obj.imageInstance!
        }
        
        if obj.imageURL != nil{
            self.imageView.downloadImage(fromURL: obj.imageURL!,
                                               placeholder: obj.imageInstance,
                                               showIndicator: true)
        }
    }
    
}
   

