//
//  PresentRecordPlayTransition.swift
//  SectionReading
//
//  Created by guangbo on 15/10/21.
//  Copyright © 2015年 pengguangbo. All rights reserved.
//

import UIKit

class PresentRecordPlayTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Double(1)
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    
        let fromNVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as! UINavigationController
        let fromVC = fromNVC.topViewController as! NewRecordVC
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as! PlayRecordVC
        let containerView = transitionContext.containerView
        
        // 显示
        toVC.view.frame = transitionContext.finalFrame(for: toVC)
        toVC.view.alpha = 0
        
        containerView.addSubview(toVC.view)
        
        UIView.animate(withDuration: 0.8, animations: { () -> Void in
            
            fromVC.fakeCDPlaySlider?.alpha = 1
            fromVC.recordButtonView?.alpha = 0
            fromVC.stopRecordButn?.alpha = 0
            fromVC.playRecordButn?.alpha = 0
            
            }, completion: { (finished) -> Void in
                
                let fakeSliderSnapShotView = fromVC.fakeCDPlaySlider?.snapshotView(afterScreenUpdates: false)
                
                fromVC.fakeCDPlaySlider?.alpha = 0
                
                if fakeSliderSnapShotView != nil {
                    
                    fakeSliderSnapShotView?.frame = containerView.convert(fromVC.fakeCDPlaySlider!.frame, from: fromVC.fakeCDPlaySlider!.superview)
                    containerView.addSubview(fakeSliderSnapShotView!)
                    
                    UIView.animate(withDuration: 0.4, animations: { () -> Void in
                        
                        fakeSliderSnapShotView!.transform = CGAffineTransform.identity.scaledBy(x: 1.3, y: 1.3)
                        
                        }, completion: { (finished) -> Void in
                            
                            UIView.animate(withDuration: 0.4, animations: { () -> Void in
                                
                                fakeSliderSnapShotView?.frame = containerView.convert(toVC.playSlider!.frame, from: toVC.playSlider!.superview)
                                
                                }, completion: { (finished) -> Void in
                                    
                                    UIView.animate(withDuration: 0.4, animations: { () -> Void in
                                        
                                        fakeSliderSnapShotView?.alpha = 0
                                        toVC.view.alpha = 1
                                        
                                        }, completion: { (finished) -> Void in
                                            
                                            fakeSliderSnapShotView?.removeFromSuperview()
                                            
                                            //告诉系统动画结束
                                            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                                    })
                            })
                    })
                }
        }) 
        
    }
}
