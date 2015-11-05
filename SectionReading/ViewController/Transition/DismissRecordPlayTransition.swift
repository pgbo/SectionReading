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
        return Double(0.8)
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as! PlayRecordVC
        let toNVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as! UINavigationController
        let toVC = toNVC.topViewController as! NewRecordVC
        
        let containerView = transitionContext.containerView()
        
        // 创建一个截图
        let snapShotView = fromVC.playSlider!.snapshotViewAfterScreenUpdates(false)
        snapShotView.frame = containerView!.convertRect(fromVC.playSlider!.frame, fromView: fromVC.playSlider!.superview)
        
        containerView?.addSubview(snapShotView)
        
        fromVC.playSlider?.alpha = 0
        
        toVC.recordButtonView?.alpha = 0
        toVC.stopRecordButn?.alpha = 0
        toVC.playRecordButn?.alpha = 0
        
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            
            // 变大
            snapShotView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.3, 1.3)
            
            fromVC.playButn?.alpha = 0
            fromVC.backButn?.alpha = 0
            fromVC.cutButn?.alpha = 0
            
            }) { (finished) -> Void in
                
                // 显示
                toNVC.view.frame = transitionContext.finalFrameForViewController(toNVC)
                containerView?.insertSubview(toNVC.view, belowSubview: fromVC.view)
                fromVC.view.alpha = 0
                
                UIView.animateWithDuration(0.4, animations: { () -> Void in
                    
                    snapShotView.frame = toVC.view.convertRect(toVC.fakeCDPlaySlider!.frame, toView: toVC.fakeCDPlaySlider!.superview)
                    
                    }, completion: { (finished) -> Void in
                        
                        UIView.animateWithDuration(0.8, animations: { () -> Void in
                            
                            toVC.recordButtonView?.alpha = 1
                            toVC.stopRecordButn?.alpha = 1
                            toVC.playRecordButn?.alpha = 1
                            
                            snapShotView.alpha = 0
                            
                            }, completion: { (finished) -> Void in
                                
                                snapShotView.removeFromSuperview()
                                
                                //告诉系统动画结束
                                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())

                        })
                })
        }
    }
}
