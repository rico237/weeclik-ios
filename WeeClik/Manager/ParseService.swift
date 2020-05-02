//
//  ParseService.swift
//  WeeClik
//
//  Created by Herrick Wolber on 04/10/2019.
//  Copyright © 2019 Herrick Wolber. All rights reserved.
//

// TODO: Add a max. of methods for commerce manipulation
// TODO: Must write unit tests for the implemented methods

import UIKit
import Parse
import CoreLocation
import TLPhotoPicker
import Photos
import SPPermission

class ParseService: NSObject {
    public static let shared = ParseService()
    
    // TODO: remplacer par une lib de geocoding ?
    private lazy var geocoder = CLGeocoder()
    private let locationManager = CLLocationManager()
    private var latestLocationForQuery: CLLocation!
    private var isLoadingCommerces = false

    private override init() {
        super.init()
        locationManager.delegate = self
    }

    // create one commerce
    
    // update one commerce
    func updateExistingParseCommerce(fromCommerce commerce: Commerce, completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil) {

        let query = PFQuery(className: "Commerce")
        query.getObjectInBackground(withId: commerce.objectId) { (parseObject, error) in

            if let error = error {
                ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true)
                completion?(false, error)
            } else if let parseObject = parseObject {
                // TODO: update thumbnail principal (not implemented)
                parseObject["nomCommerce"]      = commerce.nom
                parseObject["typeCommerce"]     = commerce.type.rawValue
                parseObject["tel"]              = commerce.tel
                parseObject["mail"]             = commerce.mail
                parseObject["siteWeb"]          = commerce.siteWeb
                parseObject["adresse"]          = commerce.adresse
                parseObject["description"]      = commerce.descriptionO
                parseObject["promotions"]       = commerce.promotions
                parseObject["brouillon"]        = commerce.brouillon
                
                parseObject.saveInBackground { (success, error) in
                    if success {
                        completion?(true, nil)
                    } else if let error = error {
                        ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true)
                        completion?(false, error)
                    } else {
                        completion?(false, nil)
                    }
                }
            } else {
                // shd never happens
                completion?(false, nil)
            }
        }
    }
    // Update geolocation of a commerce based on its addresse
    func updateGeoLocation(forCommerce commerce: Commerce, completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil) {
        // Update location from adresse

        let query = PFQuery(className: "Commerce")
        query.getObjectInBackground(withId: commerce.objectId) { (parseObject, error) in
            if let parseObject = parseObject {
                self.geocoder.geocodeAddressString(commerce.adresse) { (placemarks, error) in
                    if let error = error {
                        ParseErrorCodeHandler.handleLocationError(error: error)
                        completion?(false, error)
                    } else {
                        if let placemarks = placemarks, !placemarks.isEmpty {
                            if let location = placemarks.first?.location {
                                let commerceToSave = parseObject
                                commerceToSave["position"] = PFGeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                                commerceToSave.saveInBackground { (success, error) in
                                    completion?(success, error)
                                }
                            } else {completion?(false, nil)}
                        } else {completion?(false, nil)}
                    }
                }
            } else if let error = error {
                ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: true)
                completion?(false, error)
            }
        }
    }

    // Save photos to commerce
    func savePhotosWithCommerce(commerce: Commerce?, photoArray: [UIImage], loadedPhotos: [PFObject], completion:((_ success: Bool, _ photos: [PFObject]?, _ error: Error?) -> Void)? = nil) {
        guard let commerce = commerce else {
            completion?(false, nil, nil)
            return
        }

        let commerceToSave = PFObject(withoutDataWithClassName: "Commerce", objectId: commerce.objectId)
        var photos = [PFObject]()

        for image in photoArray {
            if image != #imageLiteral(resourceName: "Plus_icon") {
                let photo = PFObject(className: "Commerce_Photos")
                photo.acl = ParseHelper.getUserACL(forUser: PFUser.current())
                let compressedImage = image.wxCompress()
                let file: PFFileObject!
                do {
                    file = try PFFileObject(name: "photo.jpg", data: compressedImage.jpegData(compressionQuality: 0.6)!, contentType: "image/jpeg")
                } catch {
                    print("Error while setting content type jpeg")
                    file = PFFileObject(name: "photo.jpg", data: compressedImage.jpegData(compressionQuality: 0.6)!)
                }

                photo["photo"] = file
                photo["commerce"] = commerceToSave
                photos.append(photo)
            }
        }

        // FIXME: Eviter de supprimer toutes les photos et faire une par une
        PFObject.deleteAll(inBackground: loadedPhotos) { (_, error) in
            if let error = error {
                completion?(false, nil, error)
            } else {
                if !photos.isEmpty {
                    PFObject.saveAll(inBackground: photos, block: { (_, error) in
                        if let error = error {
                            completion?(false, nil, error)
                        } else {
                            completion?(true, photos, error)
                        }
                    })
                }
            }
        }

    }

    // Update thumbnail picture
    func updateCommerceThumbnailPicture(fromCommerce commerce: Commerce?, andImages photos: [PFObject], completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        guard let commerce = commerce else {
            Log.all.error("Commerce is nil")
            completion(false, nil)
            return
        }

        if !photos.isEmpty {
            let query = PFQuery(className: "Commerce")
            query.whereKey("objectId", equalTo: commerce.objectId!)
            query.includeKeys(["thumbnailPrincipal"])
            query.getFirstObjectInBackground { (commerceToUpdate, error) in
                if let commerceToUpdate = commerceToUpdate {
                    commerceToUpdate["thumbnailPrincipal"] = photos[0]
                    commerceToUpdate.saveInBackground { (success, error) in
                        if let error =  error {
                            completion(false, error)
                        } else if success {
                            completion(true, nil)
                        }
                    }
                } else if let error = error {
                    completion(false, error)
                }
            }
        }
    }

    func saveVideoForCommerce(commerce: Commerce?, videoArray: [TLPHAsset], thumbnailArray: [UIImage], completion:((_ success: Bool, _ error: Error?) -> Void)? = nil) {
        guard let commerce = commerce else {
            completion?(false, nil)
            return
        }

        let commerceToSave = PFObject(withoutDataWithClassName: "Commerce", objectId: commerce.objectId)

        // Une video a été ajouté par l'utilisateur
        if !videoArray.isEmpty {
            // Parcours de toutes les vidéos ajoutés
            for i in 0..<videoArray.count {

                let video = videoArray[i]

                // Si on réussit a prendre les data de la vidéo
                // Dans ce cas on sauvegarde
                if let asset = video.phAsset {

                    let options = PHVideoRequestOptions()
                    options.version = .original
                    options.deliveryMode = .automatic
                    options.isNetworkAccessAllowed = true

                    video.exportVideoFile(options: options, progressBlock: { (progress) in
                        print("Progress \(progress)")
                    }) { (url, mimeType) in

                        print("Video export \(url) & \(mimeType)")

                        print("try")
                        var videoData: Data?
                        do {
                            videoData = try Data(contentsOf: url)
                        } catch {
                            print("exception catch at block - while uploading video")
                            videoData = nil
                            return
                        }

                        print("Done getting video data\n Now tries to save pffile object")

                        let pffile          = PFFileObject(data: videoData!, contentType: mimeType)
                        let video           = PFObject(className: "Commerce_Videos")
                        video.acl = ParseHelper.getUserACL(forUser: PFUser.current())
                        let thumbnail       = PFFileObject(data: thumbnailArray[i].jpegData(compressionQuality: 0.5)!, contentType: "image/jpeg")

                        video["thumbnail"]    = thumbnail
                        video["leCommerce"]   = commerceToSave
                        video["time"]         = asset.duration.stringFormatted()
                        video["nameVideo"]    = commerce.nom + " - Vidéo de présentation"
                        video["video"]        = pffile

                        video.acl = ParseHelper.getUserACL(forUser: PFUser.current())

                        pffile.saveInBackground({ (success, error) in
                            if let error = error {
                                print("Erreur while uploading \(error.localizedDescription)")
                                completion?(false, error)
                            } else {
                                // Pas d'erreur
                                if success {
                                    // OK
                                    print("Upload réussi")
                                    video.saveInBackground(block: { (success, error) in
                                        completion?(success, error)
                                    })
                                } else {
                                    print("Upload failed")
                                    completion?(false, nil)
                                }
                            }

                            completion?(true, nil)
                        }, progressBlock: { (progress32) in
                            print("Progress : \(progress32)%")
                        })
                    }
                }
            }
        } else {
            completion?(true, nil)
        }
    }

    // remove photo for commerce
    // remove all photos for commerce

    // retrieve one commerce
    // retrieve mutiliple commerces (sharing preference)
    // retrieve mutiliple commerces (location preference)

    // Add picture to existing commerce (IAP), must add checks for IAP receipt
    // Add multiple pictures to existiong commerce (IAP), must add checks for IAP receipt
}

// MARK: Fetch
extension ParseService {
    // retrieve mutiliple commerces (sharing preference)
    func sharingPrefsCommerces(withType typeCategorie: String, completion:((_ commerces: [Commerce]?, _ error: Error?) -> Void)? = nil) {
        self.queryObjectsFromDB(typeCategorie: typeCategorie, prefFiltreLocation: false, completion: completion)
    }
    // retrieve mutiliple commerces (location preference)
    func locationPrefsCommerces(withType typeCategorie: String, latestKnownPosition: CLLocation, completion:((_ commerces: [Commerce]?, _ error: Error?) -> Void)? = nil) {
        self.latestLocationForQuery = latestKnownPosition
        self.queryObjectsFromDB(typeCategorie: typeCategorie, prefFiltreLocation: true, completion: completion)
    }

    // Common Func
    private func queryObjectsFromDB(typeCategorie: String, prefFiltreLocation: Bool, completion:((_ commerces: [Commerce]?, _ error: Error?) -> Void)? = nil) {
        if (!isLoadingCommerces) {
            // FIXME: URGENT -> AMELIORER LA QUERY COMMERCES (mise à jour de la poisition est faite après le fetch des commerce, ce qui veut dire qu'il faut refresh deux fois pour avoir les bons commerces
            isLoadingCommerces = true
            var commerces = [Commerce]()
            let query = PFQuery(className: "Commerce")
            query.whereKey("typeCommerce", equalTo: typeCategorie)
            query.whereKey("statutCommerce", equalTo: 1)
            query.whereKey("brouillon", equalTo: false)
            query.includeKeys(["thumbnailPrincipal"])

            if prefFiltreLocation && ( SPPermission.isAllowed(.locationWhenInUse) || SPPermission.isAllowed(.locationAlwaysAndWhenInUse) ) {
                locationManager.startUpdatingLocation()
                let userPosition = PFGeoPoint(location: latestLocationForQuery)
                query.whereKey("position", nearGeoPoint: userPosition)
                query.order(byAscending: "position")
            } else {
                query.order(byDescending: "nombrePartages")
            }
            query.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
                if let error = error {
                    if error.code == PFErrorCode.errorInvalidSessionToken.rawValue {
                        PFUser.logOut()
                    }
                    ParseErrorCodeHandler.handleUnknownError(error: error, withFeedBack: false)
                    completion?(nil, error)

                } else if let objects = objects {
                    for parseObject in objects {
                        let commerce = Commerce(parseObject: parseObject)
                        commerces.append(commerce)
                    }

                    // tri du tableau par position
                    if prefFiltreLocation {
                        let sorteCommerce = commerces.sorted(by: {
                            PFGeoPoint(location: self.latestLocationForQuery).distanceInKilometers(to: $0.location) < PFGeoPoint(location: self.latestLocationForQuery).distanceInKilometers(to: $1.location)
                        })
                        commerces = sorteCommerce
                    }
                    completion?(commerces, nil)
                }

                self.isLoadingCommerces = false
            }
        }
    }
}

extension ParseService {
    func deleteCommerce(commerce: PFObject, completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil) {
        commerce.deleteInBackground { (success, error) in
            if let error = error {
                completion?(false, error)
            } else {
                if success {
                    completion?(true, nil)
                } else {
                    completion?(false, nil)
                }
            }
        }
    }
}

// MARK: Video manipulation
extension ParseService {
    func deleteAllVideosForCommerce(commerce: PFObject, completion: ((_ success: Bool, _ error: Error?) -> Void)? = nil) {
        let videoQuery = PFQuery(className: "Commerce_Videos")
        videoQuery.whereKey("leCommerce", equalTo: commerce)
        videoQuery.findObjectsInBackground { (videos, error) in
            if let error = error {
                completion?(false, error)
            } else {
                PFObject.deleteAll(inBackground: videos) { (_, error) in
                    if let error = error {
                        completion?(false, error)
                    } else {
                        completion?(true, nil)
                    }
                }
            }
        }
    }
}
// MARK: Location required
extension ParseService: CLLocationManagerDelegate {
    /// CLLocationManagerDelegate DidFailWithError Methods
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error. The Location couldn't be found. \(error)")
    }

    /// CLLocationManagerDelegate didUpdateLocations Methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        self.latestLocationForQuery = locations.last
//        print("Did update position : \(locations.last?.description ?? "No Location Provided")")
    }
    /// Fetch commerces collection based on user location
    /// params: UserLocation = Latest user location
    func fetchCommercesFromUserPosition(userLocation: CLLocation) {
        
    }
}
