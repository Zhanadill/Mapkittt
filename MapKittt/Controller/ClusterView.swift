//
//  ClusterView.swift
//  MapKittt
//
//  Created by Жанадил on 3/28/21.
//  Copyright © 2021 Жанадил. All rights reserved.
//

import UIKit
import MapKit

class ClusterView: MKMarkerAnnotationView {
    override var annotation: MKAnnotation? {
        willSet{
            markerTintColor = UIColor.brown
        }
    }
}
