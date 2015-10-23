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
        let toNVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as! UINavigationController
        let toVC = toNVC.topViewController as! NewRecordVC
        
        let containerView = transitionContext.containerView()
        
        // 显示
//        toVC.view.frame = transitionContext.finalFrameForViewController(toVC)
        
//        containerView?.insertSubview(toVC.view, belowSubview: fromVC.view)
        
//        containerView?.bringSubviewToFront(toVC.view)
        
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            
            // 变大
            fromVC.playSlider?.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.3, 1.3)
            
            }) { (finished) -> Void in
                
                UIView.animateWithDuration(0.4, animations: { () -> Void in
                    
                    fromVC.playSlider?.transform = CGAffineTransformIdentity
                    
                    }, completion: { (finished) -> Void in
                        
                        UIView.animateWithDuration(0.4, animations: { () -> Void in
                            
                            fromVC.playSlider?.alpha = 0
                            toVC.recordButtonView?.alpha = 1
                            
                            }, completion: { (finished) -> Void in
                                
                                //告诉系统动画结束
                                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                                
                                UIView.transitionWithView(toNVC.view, duration: 3, options: UIViewAnimationOptions.TransitionFlipFromTop, animations: { () -> Void in
                                    
                                    }, completion: { (finshed) -> Void in
                                        
                                })
                        })
                })
        }
    }
}
