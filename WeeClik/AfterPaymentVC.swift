//  Created by Herrick Wolber on 18/03/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//  Can be seen in Payment storyboard (Payment.storyboard)

import UIKit
import Lottie

class AfterPaymentVC: UIViewController {

    @IBOutlet weak var animationView: AnimationView!
    var successPurchase = true

    override func viewDidLoad() {
        super.viewDidLoad()

        let animation = Animation.named("loader-success-failed")
        animationView.animation = animation

        if successPurchase {
            animationView.play(fromFrame: 0, toFrame: 380) { (_) in
                self.animationView.pause()
            }
        } else {
            animationView.play(fromFrame: 400, toFrame: 800) { (_) in
                self.animationView.pause()
            }
        }
    }
}
