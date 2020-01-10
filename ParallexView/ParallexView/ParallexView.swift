//
//  ParallexView.swift
//  Parallex
//
//  Created by Appiskey's iOS Dev on 27/12/2019.
//  Copyright © 2019 Appiskey. All rights reserved.
//

import UIKit

public struct ParallexNavBarItem{
    var image : UIImage
    var action: (() -> Void)?
}

public struct ParallexNavConfig{
    var leftBarItem : ParallexNavBarItem
    var rightBarItem : ParallexNavBarItem
    var title: String
    var itemsColor: UIColor
    var barColor: UIColor
    var titleFont: UIFont = UIFont.boldSystemFont(ofSize: 17.0)
}

public struct ParallexConfiguration{
    var navConfig: ParallexNavConfig
    var viewController: UIViewController
    var parallexTVDelegate: ParallexTableViewDelegate
    var parallexTVDataSource: ParallexTableViewDataSource
    var headerSlider: [ImageCellData]
    var pagerSelectedColor: UIColor
    var pagerUnSelectedColor: UIColor
}

@objc public protocol ParallexTableViewDataSource: class{
    func parallexTableViewNumberOfSections(in tableView: UITableView) -> Int
    func parallexTableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    func parallexTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    @objc optional func parallexTableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
}

@objc public protocol ParallexTableViewDelegate: class{
    func parallexTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    @objc optional func parallexTableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    @objc optional func parallexTableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    @objc optional func parallexTableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    @objc optional func parallexTableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    @objc optional func parallexTableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat
    @objc optional func parallexTableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat
    @objc optional func parallexTableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat
    @objc optional func parallexTableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    @objc optional func parallexTableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?

}

open class ImageDownloader{
    static public func downloadImage(fromURL url: URL, completion: @escaping ((Bool, URL, UIImage?) -> Void)){
        if let image = self.getSpecificImage(fromURL: url){
            completion(true, url, image)
            return
        }
        DispatchQueue.global(qos: .background).async {
            if let data = try? Data.init(contentsOf: url){
                DispatchQueue.main.async {
                    if let image = UIImage.init(data: data){
                        self.saveImageAgainstURL(url: url.absoluteString, image: image)
                        completion(true, url, image)
                    }else{
                        completion(false, url, nil)
                    }
                }
            }else{
                completion(false, url, nil)
            }
        }
    }
    
    
    
    private static func saveImageAgainstURL(url: String, image: UIImage){
        //save dict to userDefaults
        var dicToSave = [String: UIImage]()
        if let savedDic = getImageFromURL(){
            dicToSave = savedDic
        }
        dicToSave[url] = image
        let data = try? NSKeyedArchiver.archivedData(withRootObject: dicToSave, requiringSecureCoding: false)
        UserDefaults.standard.set(data, forKey: "cachedImages")
    }
    
    private static func getImageFromURL() -> [String: UIImage]?{
        //load
        if let data = UserDefaults.standard.object(forKey: "cachedImages") as? NSData{
//            do {
                return try! (NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data as Data) as? [String: UIImage])
//            } catch{
//                return nil
//            }
        }
        return nil
    }
    
    private static func getSpecificImage(fromURL url: URL) -> UIImage?{
        let images = getImageFromURL()
        return images?[url.absoluteString]
    }
}

extension UIScrollView {

    var isAtTop: Bool {
        return contentOffset.y <= verticalOffsetForTop
    }

    var isAtBottom: Bool {
        return contentOffset.y >= verticalOffsetForBottom
    }

    var verticalOffsetForTop: CGFloat {
        let topInset = contentInset.top
        return -topInset
    }

    var verticalOffsetForBottom: CGFloat {
        let scrollViewHeight = bounds.height
        let scrollContentSizeHeight = contentSize.height
        let bottomInset = contentInset.bottom
        let scrollViewBottomOffset = scrollContentSizeHeight + bottomInset - scrollViewHeight
        return scrollViewBottomOffset
    }

}

extension UIImageView{
    
    private func makeIndicatorOnView(){
        let backView = UIView.init(frame: self.bounds)
        let indicator = UIActivityIndicatorView.init()
        indicator.color = .white
        indicator.hidesWhenStopped = true
        backView.tag = 1000
        indicator.center = backView.center
        indicator.startAnimating()
        backView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        backView.addSubview(indicator)
        self.addSubview(backView)
    }
    
    private func hideIndicatorOnView(){
        var backView : UIView?
        for subView in self.subviews{
            if subView.tag == 1000{
                backView = subView
                break
            }
        }
        
        if backView == nil{
            return
        }
        
        var indicatorView : UIActivityIndicatorView?
        for subView in backView!.subviews{
            if subView.isKind(of: UIActivityIndicatorView.self){
                indicatorView = (subView as! UIActivityIndicatorView)
                break
            }
        }
        
        if indicatorView == nil{
            return
        }
        
        indicatorView!.stopAnimating()
        backView!.removeFromSuperview()
    }
    
    public func downloadImage(fromURL url: URL, placeholder: UIImage?=nil, showIndicator: Bool=true){
        if placeholder != nil{
            DispatchQueue.main.async {
                self.image = placeholder
            }
        }
        if showIndicator {
            self.makeIndicatorOnView()
        }
        ImageDownloader.downloadImage(fromURL: url) { (isSuccess, url, image) in
            if showIndicator {
                self.hideIndicatorOnView()
            }
            if isSuccess{
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
    }
}

class MyTableView: UITableView{
    var reloadDataCompletionBlock: (() -> Void)?
    var contentHeightUpdated: ((CGFloat) -> Void)?
    override func reloadData() {
        super.reloadData()
        if self.reloadDataCompletionBlock != nil{
            self.reloadDataCompletionBlock?()
        }
    }
    
    override var contentSize: CGSize{
        didSet{
            if self.contentHeightUpdated != nil{
                self.contentHeightUpdated?(contentSize.height)
            }
        }
    }
}


class ParallexView: UIView {
    
    // Outlets and Variables
    var view: UIView!
    
    @IBOutlet weak var rightBarItem: UIButton!
    @IBOutlet weak var leftBarItem: UIButton!
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var heightOfSliderView: NSLayoutConstraint!
    @IBOutlet weak var heightOfTopBar: NSLayoutConstraint!
    @IBOutlet weak var topImgView: SliderView!
    @IBOutlet weak var tableView: MyTableView!
    @IBOutlet weak var parallexHeader: UIView!
    // variable to save the last position visited, default to zero
    private var lastContentOffset: CGFloat = 0
    private var initialScrollInsect: CGFloat = 0
    private var contentHeight: CGFloat = 0
    
    private var thresholdScrollHeightForHeader : CGFloat = 0.0
    private var headerHeight : CGFloat = 0.0
    private var parentViewController : UIViewController!
    private var navConfig: ParallexNavConfig!
    
    public var configuration: ParallexConfiguration!
    var alphaValue : CGFloat = 0.0
    
    weak var delegate: ParallexTableViewDelegate!
    weak var dataSource: ParallexTableViewDataSource!
    
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
        let nib = UINib(nibName: "ParallexView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view
    }
    
    private func setupConfiguration(config: ParallexConfiguration){
        self.configuration = config
        self.delegate = config.parallexTVDelegate
        self.dataSource = config.parallexTVDataSource
        self.setupNavigation(config: self.configuration.navConfig)
    }
    
    private func setupNavigation(config: ParallexNavConfig){
        self.navConfig = config
        
        self.leftBarItem.setImage(self.navConfig.leftBarItem.image.withRenderingMode(.alwaysTemplate),
                                  for: .normal)
        self.rightBarItem.setImage(self.navConfig.rightBarItem.image.withRenderingMode(.alwaysTemplate),
                                   for: .normal)
        
        self.leftBarItem.imageView?.contentMode = .scaleAspectFit
        self.rightBarItem.imageView?.contentMode = .scaleAspectFit
        
        self.leftBarItem.imageView?.tintColor = self.navConfig.itemsColor
        self.rightBarItem.imageView?.tintColor = self.navConfig.itemsColor
        
        self.leftBarItem.tintColor = self.navConfig.itemsColor
        self.rightBarItem.tintColor = self.navConfig.itemsColor
        
        self.navTitle.text = self.navConfig.title
        self.navTitle.font = self.navConfig.titleFont
        self.navTitle.textColor = self.navConfig.itemsColor
        
        let topSafeAreaHeight = UIApplication.shared.windows.filter{$0.isKeyWindow}.first?.safeAreaInsets.top ?? 0
        headerHeight = 44 + ((topSafeAreaHeight == 0) ? 20 : topSafeAreaHeight)
        self.heightOfTopBar.constant = headerHeight
    }
    
    private func setupUI(){
        self.topImgView.backgroundColor = self.navConfig.barColor.withAlphaComponent(0.5)
        self.topImgView.setupView(withImageObjects: self.configuration!.headerSlider,
                                  indicatorSelectedColor: self.configuration.pagerSelectedColor,
                                  indicatorUnSelectedColor: self.configuration.pagerUnSelectedColor)
    }
    
    func initialize(configuration: ParallexConfiguration){
        // Do any additional setup after loading the view.
        
        self.setupConfiguration(config: configuration)
        parentViewController = configuration.viewController
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.parallexHeader.backgroundColor = self.navConfig.barColor.withAlphaComponent(0.0)

        self.initialScrollInsect = self.tableView.contentOffset.y
        (self.tableView.superview as? UIScrollView)?.delegate = self as UIScrollViewDelegate
        
        self.setupUI()
        tableView.reloadDataCompletionBlock = {}
        tableView.contentHeightUpdated = { (height) in
            self.contentHeight = height
            self.thresholdScrollHeightForHeader = (height * 0.35)
            if self.thresholdScrollHeightForHeader < self.tableView.frame.height{
                self.thresholdScrollHeightForHeader = (height * 0.35) - self.tableView.frame.height
            }
        }
    }
    
    func registerNibForTableView(nib: UINib, identifier: String){
        self.tableView.register(nib, forCellReuseIdentifier: identifier)
    }
    
    func reloadTVData(){
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    @IBAction func leftBarItemTapped(_ sender: Any) {
        self.navConfig.leftBarItem.action?()
    }

    @IBAction func rightBarItemTapped(_ sender: Any) {
        self.navConfig.rightBarItem.action?()
    }
    
}

extension ParallexView: UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.dataSource!.parallexTableViewNumberOfSections(in: tableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource!.parallexTableView(tableView, numberOfRowsInSection: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.dataSource!.parallexTableView(tableView, cellForRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?{
        return self.dataSource!.parallexTableView?(tableView, titleForHeaderInSection: section)
    }
}

extension ParallexView : UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        return self.delegate!.parallexTableView(tableView, didSelectRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath){
        self.delegate!.parallexTableView?(tableView, willDisplay: cell, forRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat{
        return self.delegate!.parallexTableView?(tableView, heightForRowAt: indexPath) ?? 44.0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat{
        return self.delegate!.parallexTableView?(tableView, heightForHeaderInSection: section) ?? 0.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat{
        return self.delegate!.parallexTableView?(tableView, heightForFooterInSection: section) ?? 0.0
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat{
        return self.delegate!.parallexTableView?(tableView, estimatedHeightForRowAt: indexPath) ?? 44.0
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat{
        return self.delegate!.parallexTableView?(tableView, estimatedHeightForHeaderInSection: section) ?? 0.0
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat{
        return self.delegate!.parallexTableView?(tableView, estimatedHeightForFooterInSection: section) ?? 0.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?{
        return self.delegate!.parallexTableView?(tableView, viewForHeaderInSection: section)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?{
        return self.delegate!.parallexTableView?(tableView, viewForFooterInSection: section)
    }
}

extension ParallexView: UIScrollViewDelegate{
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
//        print("scrool to top")
        return true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        print("scrolling")
        if self.thresholdScrollHeightForHeader != scrollView.contentSize.height{
            self.thresholdScrollHeightForHeader = (scrollView.contentSize.height * 0.35)
        }
        if (scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.size.height) {
            scrollView.setContentOffset(CGPoint.init(x: scrollView.contentOffset.x, y: scrollView.contentSize.height - scrollView.frame.size.height),
                                        animated: false)
        }
        if (scrollView.contentOffset.y < self.initialScrollInsect && self.heightOfSliderView.constant < 400) {
            self.heightOfSliderView.constant = self.heightOfSliderView.constant - scrollView.contentOffset.y
            self.parentViewController.view.layoutIfNeeded()
        }else if (scrollView.contentOffset.y > self.initialScrollInsect && self.heightOfSliderView.constant > 250) {
            self.heightOfSliderView.constant = self.heightOfSliderView.constant - scrollView.contentOffset.y
            self.view.layoutIfNeeded()
        }
        if (self.lastContentOffset > scrollView.contentOffset.y) {
//            print("move up")
            if !scrollView.isAtTop && !scrollView.isAtBottom{
                if self.alphaValue > 0{
                    self.alphaValue = (scrollView.contentOffset.y - (self.parallexHeader.alpha * self.thresholdScrollHeightForHeader)) / self.thresholdScrollHeightForHeader
                    self.parallexHeader.backgroundColor = self.navConfig.barColor.withAlphaComponent(self.alphaValue)
//                    print("hide color ", self.alphaValue)
                }else{
                    self.parallexHeader.backgroundColor = self.navConfig.barColor.withAlphaComponent(0.0)
                }
                if scrollView.contentOffset.y <= self.thresholdScrollHeightForHeader{
                    let valueToMutliple = self.initialScrollInsect / scrollView.contentOffset.y
                    let calculatedHeight = (valueToMutliple) * 250//self.heightOfImgView.constant
                    if calculatedHeight > headerHeight{
                        self.heightOfSliderView.constant = calculatedHeight
                        self.parentViewController.view.layoutIfNeeded()
                    }
                }
            }else if scrollView.isAtBottom{
                scrollView.contentOffset = .zero
            }
        }
        
        else if (self.lastContentOffset < scrollView.contentOffset.y) {
//            print("move down")
            if !scrollView.isAtTop && !scrollView.isAtBottom{
                if self.alphaValue < 1{
                    self.alphaValue = (scrollView.contentOffset.y) / self.thresholdScrollHeightForHeader
                    self.parallexHeader.backgroundColor = self.navConfig.barColor.withAlphaComponent(self.alphaValue)
//                    print("show color ", self.alphaValue)
                    if self.heightOfSliderView.constant > headerHeight{
                        if (1.0 - self.alphaValue) * self.heightOfSliderView.constant < headerHeight{
                            self.heightOfSliderView.constant = headerHeight
                        }else{
                            self.heightOfSliderView.constant = (1.0 - self.alphaValue) * self.heightOfSliderView.constant
                        }
                        self.view.layoutIfNeeded()
                            
                    }
                }else{
                    self.parallexHeader.backgroundColor = self.navConfig.barColor.withAlphaComponent(1.0)
                }
            }else if scrollView.isAtTop{
                scrollView.contentOffset = .zero
            }
        }
        // update the new position acquired
        self.lastContentOffset = scrollView.contentOffset.y
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        print("end")
        self.endScrolling()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate{
            self.endScrolling()
        }
    }
    
    func endScrolling(){
        if self.heightOfSliderView.constant > 250{
            self.heightOfSliderView.constant = 250
            UIView.animate(withDuration: 0.6) {
                self.view.layoutIfNeeded()
            }
        }
    }
}


open class ParallexViewRenderer{
    public var parallexConfig : ParallexConfiguration
    public var parallexView: UIView
    var parallexV : ParallexView!

    public init(config: ParallexConfiguration,
                       parallexView: UIView) {
        self.parallexConfig = config
        self.parallexView = parallexView

        self.setupParallexView()
    }

    private func setupParallexView(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.parallexV = ParallexView.init(frame: self.parallexView.frame)
            self.parallexV.initialize(configuration: self.parallexConfig)
            self.parallexView.isUserInteractionEnabled = true
            self.parallexView.addSubview(self.parallexV)
            self.parallexView.bringSubviewToFront(self.parallexV)
        }
    }
    
    func registerNibForTableView(nib: UINib, identifier: String){
        self.parallexV.registerNibForTableView(nib: nib, identifier: identifier)
    }
    
    func reloadData(){
        self.parallexV.reloadTVData()
    }
}
