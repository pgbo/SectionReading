//
//  DismissRecordPlayTransition.swift
//  SectionReading
//
//  Created by guangbo on 15/10/21.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

class DismissRecordPlayTransition: NSObject, UIViewControllerAnimatedTransitioning {

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return Double(1)
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as! PlayRecordVC
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as! NewRecordVC
        let containerView = transitionContext.containerView()
        
        // 显示
        toVC.view.frame = transitionContext.finalFrameForViewController(toVC)
        toVC.view.alpha = 0
        
        containerView?.insertSubview(toVC.view, belowSubview: fromVC.view)
        
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            
            // 变大
            fromVC.playSlider?.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.3, 1.3)
            
            }) { (finished) -> Void in
                
                UIView.animateWithDuration(0.6, animations: { () -> Void in
                    
                    fromVC.playSlider?.transform = CGAffineTransformIdentity
                    toVC.view.alpha = 1
                    fromVC.view.alpha = 0
                    
                    }, completion: { (finished) -> Void in
                        
                        //告诉系统动画结束
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                })
        }
    }
}
