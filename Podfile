# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

def projectPods
    
    ################################
    ################################
    #                              #
    #            USED              #
    #                              #
    ################################
    ################################
    
    # Librairie Parse (Back-end, Login, Notifications)
    pod 'Bolts', '~> 1.9'
    pod 'Parse', '~> 1.17.2'
    pod 'Parse/UI'
    
    # Firebase + Fabric integration
    pod 'Firebase/Core'
    pod 'Firebase/Performance'
    
    pod 'Fabric', '~> 1.9.0'
    pod 'Crashlytics', '~> 3.12.0'
    
    # Facebook integration
    pod 'FBSDKCoreKit'
    pod 'FBSDKShareKit'
    pod 'FBSDKLoginKit'
    
    pod 'Parse/FacebookUtils'
    
    # Chergement des images depuis internet
    pod 'SDWebImage', '~> 4.0'
    # UIAlert with progress utilities
    pod 'SVProgressHUD', '~> 2.1'
    
    # Add promises like in javascript
    pod 'PromiseKit', '~> 6.0'
    # async functions
    pod 'AsyncSwift'                # Surement à supprimer & utiliser AwaitKit -v
    pod 'AwaitKit', '~> 5.1.0'
    
    
    # HTTP requests (CRUD) (GET POST PUT DEL)
    pod 'Alamofire', '~> 4.7'
    
    # Animation RBnB Lottie
    pod 'lottie-ios', '~> 2.5.3'
    # Selection des photos et videos pour la création de commerce
    pod 'Gallery', :git => 'https://github.com/hyperoslo/Gallery.git', :branch => 'master'
    # Demande de permissions
    pod 'Sparrow/Modules/RequestPermission', :git => 'https://github.com/IvanVorobei/Sparrow.git'
    # Carrousel de démo à la connexion
    pod 'ZKCarousel', '~> 0.1'
    # Notification pour le partage de nouveau activé
    pod 'CRNotifications'
    # Carte pour les filtres
    pod 'BulletinBoard', '~> 1.3.0'
    # Scroll automatique pour faciliter l'utilisation du clavier
    pod 'TPKeyboardAvoiding', :git => 'https://github.com/michaeltyson/TPKeyboardAvoiding.git'
    # Choisir une photo dans la bibliothèque du téléphone
    pod 'TLPhotoPicker', '~> 1.3.4'
    # Actions et Alerts
    # ou pod 'RLBAlertsPickers', '~> 1.0'
    pod 'HWAlertsPickers', :git => 'https://github.com/rico237/Alerts-Pickers.git'
    # Acid buttons
    pod 'LGButton', '~> 1.0'
    # Palette de couleures
    pod 'Hue', '~> 3.0'
    # Boutton flottant
    pod 'Floaty', '~> 4.0.0'
    # Message sous la barre de navigation
    pod 'Zingle', :git => 'https://github.com/hemangshah/Zingle.git'
    # Tableview quand il n'ya pas de donnés
    pod 'DZNEmptyDataSet'
    # Selection Multiple de contacts
    pod 'SwiftMultiSelect', :git => 'https://github.com/rico237/SwiftMultiSelect.git'
    # Pour la page recherche
    pod 'Compose', '~> 1.2'
    # Pour de bonnes grille en fonction de l'écran
    pod 'KRLCollectionViewGridLayout', '~> 1.0'
    # Routing management
    pod 'Compass'
    # Permet de remonter le header au scroll  (Accueil)
    pod 'KJNavigationViewAnimation', :git => 'https://github.com/KiranJasvanee/KJNavigationViewAnimation.git'
    # Savoir si il y a internet
    pod 'ReachabilitySwift'
    # Détail & zoom des images
    pod 'AppImageViewer', :git => 'https://github.com/weeclik/AppImageViewer.git'
    # Many Usefull UI/UX Elements
    pod 'Material', '~> 2.0'
    # Video Player
    pod 'MobilePlayer', :git => 'https://github.com/weeclik/mobileplayer-ios.git'
    
    # In App Purchase (IAP) Libs
    pod 'SwiftyStoreKit', '~> 0.14.2'
    #Manipulation de dates
    pod 'SwiftDate', '~> 5.0'
    
    # Settings panel
    pod 'SPLarkController', :git => 'https://github.com/weeclik/SPLarkController.git'
    # Observable data & nsnotificationcenrter
    pod 'Hanson'
    
    
    ################################
    ################################
    #                              #
    #  UNUSED OR IN NEXT FEATURE   #
    #                              #
    ################################
    ################################
    
    ###------------GENERALE---------------##
    
    
    
    # BEST ALERTS & MESSAGES UIs
    #pod 'SwiftMessages'
    #pod 'SwiftEntryKit', '1.0.1'                     # Use this    <--------
    
    
    # Mailgun Librairie (envoi de mails)
    #pod 'SwiftMailgun', '~> 1.0'
    
    # UserDefaults with AES-256 encryption
    #pod 'SecureDefaults', '1.0.3' # Swift 5.0
    #pod 'SecureDefaults', '1.0.0' # Swift 4.2
    
    ###-------------MESSAGERIE--------------##
    
    # Ajout de notification InApp pour le chat instantané
    #https://github.com/lucabecchetti/InAppNotify
    # Composition de message
    #pod 'FormSheetTextView', '~> 1.0'
    # UITextView agrandit avec le text + Placeholder
    #pod 'ASJExpandableTextView', '~> 0.4'
    
    
    
    ###-------------PROFIL--------------##
    
    # Positionner les photos de profil en fonction du visage (detection du visage)
    #pod 'FaceAware', :git => 'https://github.com/BeauNouvelle/FaceAware.git'
    
    
    
    ###------------COMMERCES---------------##
    
    # pour reordoner les photos des commercants
    #pod 'RAReorderableLayout', '~> 0.6'
    # Bouttons de chargement (avec progres)
    #pod 'CRNetworkButton', '~> 1.0'
    
    
    
    ###-----------?????????----------------##
    
    # Gradient
    #pod 'RMGradientView', :git => 'https://github.com/sleepwalkerfx/RMGradientView.git'
end

target 'WeeClik' do
    use_frameworks!
    projectPods
end
