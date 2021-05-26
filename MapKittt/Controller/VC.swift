//
//  ViewController.swift
//  MapKit
//
//  Created by Жанадил on 3/26/21.
//  Copyright © 2021 Жанадил. All rights reserved.
//

import UIKit
import CoreLocation

class VC: UIViewController {

    @IBOutlet weak var placeName: UILabel!
    @IBOutlet weak var locationDistance: UILabel!
    @IBOutlet weak var placeImage: UIImageView!
    @IBOutlet weak var address: UILabel!
    
    
    var placesViewController: PlaceScrollViewController?
    var locationManager: CLLocationManager?
    var currentLocation: CLLocation?
    var places: [InterestingPlace] = []
    var selectedPlace: InterestingPlace? = nil
    //Нужен нам для того чтобы определять адрес по longitude and latitude (тоесть у нас есть база откуда можно извлекать адрес по координатам)
    lazy var geocoder = CLGeocoder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Обьявили наш placesViewController как childViewController
        if let childViewController = children.first as? PlaceScrollViewController {
            placesViewController = childViewController
        }
        
        loadPlaces()
        //Настроили делегаты CoreLocation
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        //Чтобы местоположение отслеживалось когда мы нажав на Home button временно закроем приложение
        locationManager?.allowsBackgroundLocationUpdates = true
        
        //Поначалу у нас выбранное место будет равно первому элементу массива, затем будет меняться в зависимости от скроллинга
        selectedPlace = places.first
        updateUI()
        
        //Передали в child VC наш массив чтобы исп. их в ScrollView
        placesViewController?.addPlaces(places: places)
        
        placesViewController?.delegate = self
    }
    
    
    //Присваиваем UI-элементам значения в зависимости об выбранного места
    private func updateUI(){
        placeName.text = selectedPlace?.name
        guard let imageName = selectedPlace?.imageName,
            let image = UIImage(named: imageName) else{ return }
        placeImage.image = image
        
        //UI-элемент показывает сколько метров до нужного нам места
        guard let currentLocation = currentLocation,
            let distanceInMeters = selectedPlace?.location.distance(from:
                currentLocation) else { return }
        let distance = Measurement(value: distanceInMeters, unit: UnitLength.meters)
        let miles = distance.converted(to: .miles)
        locationDistance.text = "\(miles)"
        printAddress()
    }
    
    
    //С помощью segue мы будем передавать текущее место и массив местностей чтобы выводить
    //их всех на карте с отметкой
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "MapSegue" {
            guard let mapController = segue.destination as? MapVC,
                  let selectedPlace = selectedPlace else { return }
            mapController.place = selectedPlace
            mapController.places = places
            //Передали нашу текущую локацию чтобы там строить маршрут между нашей локацией и нужной местностью
            mapController.sourcelocation = currentLocation
        }
    }
    
    
    //Получили адрес по координатам и присвоили UI-элементу адрес, которого получили
    //Чтобы получить адрес наш девайс должен быть подключен к интернету
    private func printAddress(){
        guard let selectedPlace = selectedPlace else { return }
        geocoder.reverseGeocodeLocation(selectedPlace.location) { [weak self] (placemarks, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let placemark = placemarks?.first else{ return }
            if let streetNumber = placemark.subThoroughfare,
               let street = placemark.thoroughfare,
               let city = placemark.locality,
               let state = placemark.administrativeArea{
                   self?.address.text = "\(streetNumber) \(street) \(city), \(state)"
            }
        }
    }
    //Также можно получать по адресу координаты (Это мы рассматривать не будем)
    //Об этом можно найти инфу в raywenderlich (Mapkit and Core Data) lesson 1-07(converting addresses into coordinates)

    
    func selectPlace(){
        print("place selected")
    }
    
    
    //Здесь мы запрашиваем разрешение на использование геолокации
    @IBAction func startLocationService(_ sender: UIButton) {
        if CLLocationManager.authorizationStatus() == .authorizedAlways ||
            CLLocationManager.authorizationStatus() == .authorizedWhenInUse{
              activateLocationServices()
        }else{
              locationManager?.requestAlwaysAuthorization()
        }
    }
    
    
    //Создаем регионы для каждой местности (В каждом приложении мы можем создать максимум 20 регионов)
    private func activateLocationServices() {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            for place in places {
                let region = CLCircularRegion(center: place.location.coordinate, radius: 500,
                                              identifier: place.name)
                region.notifyOnEntry = true
                locationManager?.startMonitoring(for: region)
            }
        }
        locationManager?.startUpdatingLocation()
    }
    
    
    // Для того чтобы считать данные нашего Property list и вывести значения
    func loadPlaces(){
        guard let entries = loadPlist() else{ fatalError("Unable to load data") }
        
        for property in entries {
            guard let name = property["Name"] as? String,
                let latitude = property["Latitude"] as? NSNumber,
                let longitude = property["Longitude"] as? NSNumber,
                let image = property["Image"] as? String else{ fatalError("Error reading data")}
            
            var sponsored = false
            if property["Sponsored"] != nil{
                sponsored = property["Sponsored"] as? Bool ?? false
            }
            
            //Создали обьект и добавили его в наш массив
            let place = InterestingPlace(latitude: latitude.doubleValue, longitude: longitude.doubleValue, name: name, imageName: image, sponsored: sponsored)
            places.append(place)
        }
    }
    
    
    //Обрабытываем наш plist
    private func loadPlist() -> [[String: Any]]? {
        guard let plistUrl = Bundle.main.url(forResource: "Places", withExtension: "plist"),
            let plistData = try? Data(contentsOf: plistUrl) else{ return nil}
        var placedEntries: [[String: Any]]? = nil
        
        do{
            placedEntries = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [[String: Any]]
        } catch{
            print("error reading plist")
        }
        return placedEntries
    }
}




extension VC: CLLocationManagerDelegate {
    //Если мы получили у пользователя разрешение на его геолокацию то запускаем функцию activateLocationServices()
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus){
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            activateLocationServices()
        }
    }
    
    
    //На случай если не удастся выявить геолокацию юзера
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    
    //Когда входим в какой-то регион у нас выводится аlert где говорится о том что это место находится близко
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if presentedViewController == nil {
            let alertController = UIAlertController(title: "Interesting Location Nearby", message: "You are near \(region.identifier). Check it out!", preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "OK", style: .default) { [weak self] (action) in
                self?.dismiss(animated: true, completion: nil)
            }
            alertController.addAction(alertAction)
            present(alertController, animated: false, completion: nil)
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print(error.localizedDescription)
    }
    
    
    //Пошагово выводим сколько метров осталось до нужного нам места
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        currentLocation = locations.first
        /*if currentLocation == nil {
            currentLocation = locations.first
        }else{
            guard let latest = locations.first else{ return }
            let distanceInMeters = currentLocation?.distance(from: latest) ?? 0
            print("distance in meters: \(distanceInMeters)")
            currentLocation = latest
        }*/
    }
}



//Получаем  selected img из scrollView и присваем нашим UI-элементам новые значения
extension VC: PlaceScrollViewControllerDelegate {
    func selectedPlaceViewController(controller: PlaceScrollViewController, didSelectPlace place: InterestingPlace) {
        selectedPlace = place
        updateUI()
    }
}


//BasketLoop.gpx
//сделали так чтобы местоположение телефона все время менялся между этими местностями
//это нужно для того чтобы проверить будет ли выводиться алерт когда будем входить в определенные регионы
