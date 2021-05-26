//
//  MapViewController.swift
//  MapKit
//
//  Created by Жанадил on 3/27/21.
//  Copyright © 2021 Жанадил. All rights reserved.
//

import UIKit
import MapKit
import AVFoundation

class MapVC: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var myTableView: UITableView!
    //когда будем переходить в этот VC мы будем передавать местность(place) и для этой
    //местности будем определять регион и выводить ее на карте
    var place: InterestingPlace?
    //получили массив чтобы поставить отметки
    var places: [InterestingPlace] = []
    //эти свойства нам нужны для того чтобы создать маршрут от нашего расположения до нужного места
    //travelDirections будет содержать наших строк-путеводителей
    var sourcelocation: CLLocation?
    var travelDirections: [String] = []
    //Нужно чтобы озвучивало маршрут
    var voice: AVSpeechSynthesizer?
    
    
    //настройка UISegmentedControl (тоесть мы можем переключаться между стандартной картой и спутником)
    //Также при переключении на трети1 сегмент у нас открывается tableView
    @IBAction func changeMapType(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 || sender.selectedSegmentIndex == 1 ||
            sender.selectedSegmentIndex == 3 {
            mapView.isHidden = false
            myTableView.isHidden = true
            mapView.isRotateEnabled = false
            if sender.selectedSegmentIndex == 0{
                mapView.mapType = .standard
            }else if sender.selectedSegmentIndex == 1{
                mapView.mapType = .satellite
            //Сделали так чтобы в свободном плавании можно было рассматривать местность сблизи
            //Настроили камеру. Это можно протестировать только на реальном девайсе (на симуляторе нельзя).
            //Мы можем смотреть вблизи лишь те места которые есть в базе. А отдаленные места леса или пустыни всякие представляются нам вблизи как img в формате 3d.
            }else if sender.selectedSegmentIndex == 3{
                mapView.mapType = .satelliteFlyover
                if let coordinate = place?.coordinate{
                    let camera = MKMapCamera(lookingAtCenter: coordinate, fromDistance: 300, pitch: 40, heading: 0)
                    mapView.camera = camera
                    mapView.isRotateEnabled = true
                }
            }
        }else{
            mapView.isHidden = true
            myTableView.isHidden = false
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        //Определили регион и сделали так чтобы на карте выводилась это местность
        guard let place = place else{ return }
        //указали радиус региона (чем он меньше тем масштаб карты будет меньше)
        let regionRadius: CLLocationDistance = 1000.0
        let region = MKCoordinateRegion(center: place.location.coordinate,
                                        latitudinalMeters: regionRadius,
                                        longitudinalMeters: regionRadius)
        
        //настроили звук и вызвали функцию которая отвечает за создание маршрута
        voice = AVSpeechSynthesizer()
        loadDirections()
        
        mapView.setRegion(region, animated: true)
        
        //Добавили отметки всем местностям которые содержатся в массиве
        mapView.addAnnotations(places)
        //Создали отметки и сделали так чтобы при нажатии на него высвечивался картинка
        mapView.register(InterestingPlaceView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        //Настроили кластеризацию
        mapView.register(ClusterView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        
        myTableView.delegate = self
        myTableView.dataSource = self
        myTableView.register(UITableViewCell.self, forCellReuseIdentifier: "directionCell")
        myTableView.reloadData()
        
        //Вызвали эту функцию чтобы рисовать путь
        //produceOverlay()
    }
    
    
    //С помощью overlay мы указываем где нужно рисовать и в какую сторону
    //То есть в данном случае мы передали координаты чтобы по ним нарисовать шестиугольник
    //В данном случае нам не нужно рисовать шестиугольник мы это просто рассмотрели как пример
    //Есть еще MKPolyline-обычный вектор, MKPolygon(с помощью него также можно рисовать треугольник
    //четырехугольник и т.д), MKCircle(здесь мы указываем координаты центра и радиус)
    /*private func produceOverlay(){
        var points: [CLLocationCoordinate2D] = []
        points.append(CLLocationCoordinate2DMake(40.063965, -82.346642))
        points.append(CLLocationCoordinate2DMake(40.063921, -82.346185))
        points.append(CLLocationCoordinate2DMake(40.063557, -82.346185))
        points.append(CLLocationCoordinate2DMake(40.063561, -82.347200))
        points.append(CLLocationCoordinate2DMake(40.063961, -82.347150))
        points.append(CLLocationCoordinate2DMake(40.063965, -82.346800))
        let polygon = MKPolygon(coordinates: &points, count: points.count)
        mapView.addOverlay(polygon)
    }*/
    
    
    //Если мы сделали слишком много запросов и сервер все медленнее будет отвечать на наш запрос
    //Геокодер Apple не отвечает на все запросы одинаково. Вместо этого на первые запросы от определенного устройства отвечают быстро, но если устройство отправило, скажем, 100 запросов или более, ответы поступают все медленнее и медленнее или запросы не принимаются вообще.
    //Когда мы перезагружаем контроллер представления, это просто требует времени, и сервер геокодирования с большей готовностью отвечает снова. По сути, мы ничего не можем с этим поделать, поскольку сервер геокодера хочет защитить себя от перегрузки запросами с одного устройства. Нам просто нужно было ограничить количество запросов, которые мы отправляем туда.
    //Кстати: в документации сказано: «Вы не должны отправлять более одного запроса на геокодирование в минуту».
    private func loadDirections(){
        guard let start = sourcelocation, let end = place else { return }
        let request = MKDirections.Request()
        let startMapItem = MKMapItem(placemark: MKPlacemark(coordinate: start.coordinate))
        let endMapItem = MKMapItem(placemark: MKPlacemark(coordinate: end.coordinate))
        request.source = startMapItem
        request.destination = endMapItem
        request.requestsAlternateRoutes = false
        request.transportType = .automobile
        let directions = MKDirections(request: request)
        directions.calculate() {
            [weak self] (response, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let route = response?.routes.first {
                let formatter = MKDistanceFormatter()
                //когда будем определять маршрут за одно будем его и рисовать на карте
                self?.mapView.addOverlay(route.polyline)
                formatter.unitStyle = .full
                for step in route.steps{
                    let distance = formatter.string(fromDistance: step.distance)
                    self?.travelDirections.append(step.instructions + " (\(distance))")
                }
                self?.myTableView.reloadData()
            }
        }
    }
}




//MARK: TableView DataSource Methods
//Показывает весь наш маршрут (типа где куда нужно поворачивать и т.д) в tableView
extension MapVC: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(travelDirections.count)
        return travelDirections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "directionCell", for: indexPath)
        //print(travelDirections[indexPath.row])
        cell.textLabel?.text = travelDirections[indexPath.row]
        return cell
    }
}


//MARK: TableView Delegate Methods
//При нажатии на cell будет озвучиваться его содержание
extension MapVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let text = travelDirections[indexPath.row]
        let utterance = AVSpeechUtterance(string: text)
        voice?.speak(utterance)
    }
}




//MARK: MKMapView Delegate Methods
extension MapVC: MKMapViewDelegate {
    
    //В renderer мы указываем как и что будем рисовать
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer{
        
        //сказали что нужно нарисовать фигуру по переданному overlay (в данном это у нас шестиугольник)
        //Мы это не вызвали (убрали из viewDidLoad) и поэтому оно не будет срабатывать
        if overlay is MKPolygon {
            let polyRenderer = MKPolygonRenderer(overlay: overlay)
            polyRenderer.strokeColor = UIColor.blue
            polyRenderer.lineWidth = 8.0
            return polyRenderer
        }else{ //Прокладываем путь с начальной точки до определенного места
            let polyLine = MKPolylineRenderer(overlay: overlay)
            polyLine.strokeColor = UIColor.blue
            polyLine.lineWidth = 8.0
            return polyLine
        }
    }
    
    
    //Каждый раз когда будем увеличивать карту у нас будет выполняться функция mapViewWillStartRenderingMap()
    /*func mapViewWillStartRenderingMap(_ mapView: MKMapView){
        print("rendering ...")
    }
    
    //Настройка mapView
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            return nil
        }*/
        
        
        //Настроили кластеризацию (то есть когда будет уменьшать карту обьекты которые находятся
        //близко друг другу будут представлять собой один кластер)
        //Мы добавили свойство sponsored в наш object class
        //Те обьекты у которых свойстсво sponsored указано как true при кластеризации
        //будут рассматриваться как title кластера
        /*if let cluster = annotation as? MKClusterAnnotation {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "cluster") as? MKMarkerAnnotationView
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: nil, reuseIdentifier: "cluster")
            }
            annotationView?.markerTintColor = UIColor.brown
            for clusterAnnotation in cluster.memberAnnotations{
                if let placeAnnotation = clusterAnnotation as? InterestingPlace{
                    if placeAnnotation.sponsored{
                        cluster.title = placeAnnotation.name
                        break
                    }
                }
            }
            annotationView?.annotation = cluster
            return annotationView
        }
        
        
        //Настройки отметок на карте
        if let placeAnnotation = annotation as? InterestingPlace {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "InterestingPlace") as? MKMarkerAnnotationView
            if annotationView == nil{
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "InterestingPlace")
               
                
                //Добавили кластер нашему обьекту
                annotationView?.clusteringIdentifier = "cluster"
            }else{
                annotationView?.annotation = annotation
            }
            
            
            return annotationView
        }
        
        return nil
      }*/
}



//Также на карту можно вставлять img то есть если у нас имеется план определенной местности,
//мы можем постваить его (Например на видеоуроке вставляли план Фэнтэзи-парка)
//Подробную информацию об этом можно найти в разделе Overlaying Images



//Мы можем кастомизировать карту под свои нужды (для этого нашу карту разбиваем на tiles и в определенном tile
//будем вести работу)
//Тile поначалу будет 0.0 и будет охватывать всю карту
//Затем Тile можно разбить на 4 части (0.0-левый верхний угол, 1.0-правый верхний угол, 0.1-нижний левый угол,
//1.1-нижний правый угол)
//В данном случае на видеоуроке делали кастомизацию для Центрального парка Нью-Йорк
//Подробную информацию можно найти в Using Third-Party Map Tiles and Creating Custom Map Tiles


//Есть отдельный курс в RW который полностью посвящен MapKit называется он
//Advanced Mapkit Tutorial: Custom Tiles


//Также можно использовать Google Maps в приложении, это альтернатива Apple Maps
