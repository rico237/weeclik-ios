//  Created by Herrick Wolber on 18/03/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//  Can be seen in Payment storyboard (Payment.storyboard)

import UIKit
import Lottie

class AfterPaymentVC: UIViewController {
    
    @IBOutlet weak var lot: LOTAnimatedControl!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        let animationView = lot.animationView
        animationView.setAnimation(named: "loader-success-failed")
        animationView.play()
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
