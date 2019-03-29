//  Created by Herrick Wolber on 18/03/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//  Can be seen in Payment storyboard (Payment.storyboard)

import UIKit
import Lottie

class AfterPaymentVC: UIViewController {
    
    @IBOutlet weak var lot: LOTAnimatedControl!
    var successPurchase = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let animationView = lot.animationView
        animationView.setAnimation(named: "loader-success-failed")
        
        if successPurchase {
            animationView.play(fromFrame: 0, toFrame: 380) { (finished) in
                animationView.pause()
            }
        } else {
            animationView.play(fromFrame: 400, toFrame: 800) { (finished) in
                animationView.pause()
            }
        }
    }
}
