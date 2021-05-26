//
//  InterestingPlaceView.swift
//  MapKittt
//
//  Created by Жанадил on 3/28/21.
//  Copyright © 2021 Жанадил. All rights reserved.
//

import UIKit
import MapKit

class InterestingPlaceView: MKMarkerAnnotationView {

    override var annotation: MKAnnotation? {
        willSet{
            if let placeAnnotation = newValue as? InterestingPlace {
                //Указали содержание и цвет отметки
                glyphText = "👀"
                markerTintColor = UIColor(displayP3Red: 0.082, green: 0.518, blue: 0.263, alpha: 1.0)
                //Настроили так чтобы те обьекты у которых свойство sponsored указано как true
                //имели приоритет повыше (когда будем делать кластеризацию)
                if placeAnnotation.sponsored{
                    displayPriority = .defaultHigh
                }
                
                //Нужен чтобы показать img при нажатии на отметку
                canShowCallout = true
                
                //Нужен для настройки кластеризации
                clusteringIdentifier = MKMapViewDefaultClusterAnnotationViewReuseIdentifier
                
                //Настроили так чтобы при нажатии на отметку был виден img
                let image = UIImage(named: placeAnnotation.imageName)!
                let size = CGSize(width: 150, height: 150)
                let image2 = imageResize(image: image, sizeChange: size)
                let imageView = UIImageView(image: image2)
                detailCalloutAccessoryView = imageView
            }
        }
    }
    
    //Функция для уменьшения размера image
    func imageResize (image: UIImage, sizeChange:CGSize)-> UIImage{
          let hasAlpha = true
          let scale: CGFloat = 0.0
          UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
          image.draw(in: CGRect(origin: .zero, size: sizeChange))
          let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
          UIGraphicsEndImageContext()
          return scaledImage!
    }
}
