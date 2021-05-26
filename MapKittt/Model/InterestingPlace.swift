//
//  InterestingPlace.swift
//  MapKit
//
//  Created by Жанадил on 3/26/21.
//  Copyright © 2021 Жанадил. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

class InterestingPlace: NSObject{
    let location: CLLocation
    let name: String
    let imageName: String
    let sponsored: Bool
    
    init(latitude: Double, longitude: Double, name: String, imageName: String, sponsored: Bool){
        self.location = CLLocation(latitude: latitude, longitude: longitude)
        self.name = name
        self.imageName = imageName
        self.sponsored = sponsored
    }
}


//Мы сделали extension и сделали так чтобы наш класс наследовался от NSObject - для того чтобы
//использовать все это когда будем ставить отметки на карте

//Наша отметка пока может содержать только title and subtitle (для того чтобы добавить туда что-то свое)
//мы выделяем MKAnnotation и нажав на правую кнопку мыши выбираем Jump to Definition и там можно
//добавлять что-то
extension InterestingPlace: MKAnnotation{
    var coordinate: CLLocationCoordinate2D{
        get{
            return location.coordinate
        }
    }
    
    var title: String?{
        get{
            return name
        }
    }
}
