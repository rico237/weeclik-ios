//
//  AdminMonProfilSettingsVC.swift
//  WeeClik
//
//  Created by Herrick Wolber on 02/05/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

import UIKit

class AdminMonProfilSettingsVC: UIViewController {

    var enabled1 = Bool(false), enabled2 = Bool(false), enabled3 = Bool(false), enabled4 = Bool(false)

    let enabledButtonColor: UIColor = UIColor.init(hexFromString: "#2561fe")
    let disabledButtonColor: UIColor = UIColor.init(hexFromString: "#aaaaaa")

    @IBOutlet weak var option1: UIButton!   // Option : Paiement pour création de nouveau commerce
    @IBOutlet weak var option2: UIButton!   // Option : Temps de validite d'un commerce (defaut 1 an)
    @IBOutlet weak var option3: UIButton!
    @IBOutlet weak var option4: UIButton!

    var buttons = [UIButton]()
    var enables = [Bool]()

    override func viewDidLoad() {
        super.viewDidLoad()
        buttons = [option1, option2, option3, option4]
        enables = [enabled1, enabled2, enabled3, enabled4]

        getUserDefaultsOptions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        uiInit()
    }

    func getUserDefaultsOptions() {
        enabled1 = HelperAndKeys.getUserDefaultsValue(forKey: HelperAndKeys.getPaymentKey(), withExpectedType: "bool") as? Bool ?? false
        enabled2 = HelperAndKeys.getUserDefaultsValue(forKey: HelperAndKeys.getScheduleKey(), withExpectedType: "bool") as? Bool ?? false

        enables[0] = !enabled1
        enables[1] = enabled2
        enables[2] = enabled3
        enables[3] = enabled4
        updateButtonUIs()
    }

    func updateButtonUIs() {
        for (index, button) in buttons.enumerated() {
            let enabled = enables[index]

            if !button.isHidden && enabled {
                button.backgroundColor = enabledButtonColor

                if index == 1 {
                    // Option 2
                    button.setTitle("Schedule :  30sec".localized(), for: .normal)
                }

            } else {
                button.backgroundColor = disabledButtonColor

                if index == 1 {
                    // Option 2
                    button.setTitle("Schedule :  1an".localized(), for: .normal)
                }
            }
        }
    }

    func uiInit() {
        view.backgroundColor = UIColor.init(hexFromString: "#040404")
        for button in buttons {
            button.setTitleColor(disabledButtonColor, for: .normal)
            button.setTitleColor(UIColor.white, for: .normal)
        }
    }

    @IBAction func payment_option_action(_ sender: Any) {
        HelperAndKeys.setUserDefaultsValue(value: !enabled1, forKey: HelperAndKeys.getPaymentKey())
        getUserDefaultsOptions()
    }

    @IBAction func schedule_option_action(_ sender: Any) {
        HelperAndKeys.setUserDefaultsValue(value: !enabled2, forKey: HelperAndKeys.getScheduleKey())
        getUserDefaultsOptions()
    }
    @IBAction func closeView(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
