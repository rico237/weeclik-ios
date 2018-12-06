//: A UIKit based Playground for presenting user interface
  
import UIKit
import CoreLocation
import PlaygroundSupport


class MyViewController : UIViewController {
    let label = UILabel()
    var loca : Location? = nil
    var geoCoder = CLGeocoder()
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white

        
        label.frame = CGRect(x: 0, y: 200, width: 320, height: 20)
        label.text = "Hello World!"
        label.textColor = .black
        
        geoCoder.geocodeAddressString("56 boulevard rené cassin, nice") { (placemarks, error) in
            
            if let error = error {
                print(error.localizedDescription)
            } else {
                if let placemarks = placemarks, placemarks.count > 0 {
                    if let location = placemarks.first?.location {
                        print("location : \(location.debugDescription)")
                        self.label.text = "Lat : \(location.coordinate.latitude)     Long :  \( location.coordinate.longitude)"
                    }
                }
            }
        }
        
        view.addSubview(label)
        self.view = view
    }
}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()
