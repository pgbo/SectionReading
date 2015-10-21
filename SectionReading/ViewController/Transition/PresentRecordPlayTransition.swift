//
//  PresentRecordPlayTransition.swift
//  SectionReading
//
//  Created by guangbo on 15/10/21.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

class PresentRecordPlayTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return Double(1)
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
    
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as! NewRecordVC
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as! PlayRecordVC
        let containerView = transitionContext.containerView()
        
        // 显示
        toVC.view.frame = transitionContext.finalFrameForViewController(toVC)
        toVC.view.alpha = 0
        
        containerView?.addSubview(toVC.view)
        
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            
            fromVC.fakeCDPlaySlider?.alpha = 1
            
            }) { (finished) -> Void in
                
                let fakeSliderSnapShotView = fromVC.fakeCDPlaySlider?.snapshotViewAfterScreenUpdates(false)
                fakeSliderSnapShotView?.frame = containerView!.convertRect(fromVC.fakeCDPlaySlider!.frame, fromView: fromVC.fakeCDPlaySlider?.superview)
                
                fromVC.fakeCDPlaySlider?.alpha = 0
                
                if fakeSliderSnapShotView != nil {
                    containerView?.addSubview(fakeSliderSnapShotView!)
                    
                    UIView.animateWithDuration(0.4, animations: { () -> Void in
                        
                        fakeSliderSnapShotView!.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.3, 1.3)
                        
                        }, completion: { (finished) -> Void in
                            
                            UIView.animateWithDuration(0.4, animations: { () -> Void in
                                
                                fakeSliderSnapShotView!.transform = CGAffineTransformIdentity
                                
                                }, completion: { (finished) -> Void in
                                    
                                    fakeSliderSnapShotView?.removeFromSuperview()
                                    
                                    toVC.view.alpha = 1
                                    
                                    //告诉系统动画结束
                                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                            })
                            
                    })
                }
        }
        
    }
}
