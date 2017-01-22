//
//  NowPlayingViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 1/14/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class NowPlayingViewController: UIViewController {
    
    var pageViewController: UIPageViewController?
    var currentIndex = 0
    
    private(set) lazy var orderedViewControllers: [NowPlayingGameViewController] = {
        return [NowPlayingGameViewController(),
                NowPlayingGameViewController(),
                NowPlayingGameViewController(),
                NowPlayingGameViewController()]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPageViewController" {
            pageViewController = segue.destination as? UIPageViewController
            pageViewController?.dataSource = self
            pageViewController?.delegate = self
            
            let pageControl = UIPageControl.appearance(whenContainedInInstancesOf: [UIPageViewController.self])
            pageControl.pageIndicatorTintColor = UIColor.lightGray
            pageControl.currentPageIndicatorTintColor = UIColor.darkGray
            pageControl.backgroundColor = UIColor.clear
            
            self.view.backgroundColor = UIColor(colorLiteralRed: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
            self.navigationController?.view.backgroundColor = UIColor.white
            self.automaticallyAdjustsScrollViewInsets = false
            
            if let firstViewController = orderedViewControllers.first {
                pageViewController?.setViewControllers([firstViewController],
                                   direction: .forward,
                                   animated: true,
                                   completion: nil)
            }
        }
    }
}

extension NowPlayingViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: (viewController as? NowPlayingGameViewController)!) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: (viewController as? NowPlayingGameViewController)!) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return orderedViewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstViewController = orderedViewControllers.first, let firstViewControllerIndex = orderedViewControllers.index(of: firstViewController) else {
                return 0
        }
        
        return firstViewControllerIndex
    }
}

extension NowPlayingViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {

    }
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        
    }
}
