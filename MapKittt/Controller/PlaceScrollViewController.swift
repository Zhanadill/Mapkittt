//
//  PlaceScrollViewController.swift
//  MapKit
//
//  Created by Жанадил on 3/26/21.
//  Copyright © 2021 Жанадил. All rights reserved.
//

import UIKit

//We created that protocol
protocol PlaceScrollViewControllerDelegate {
    func selectedPlaceViewController( controller: PlaceScrollViewController,
                                      didSelectPlace place: InterestingPlace)
}


//Our child VC
class PlaceScrollViewController: UIViewController {
    var scrollView: UIScrollView!
    var stackView: UIStackView!
    var places: [InterestingPlace]?
    var delegate: PlaceScrollViewControllerDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // We set constraints for our ScrollView
        view.backgroundColor = .black
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrollView]|", options: .alignAllCenterX, metrics: nil, views: ["scrollView": scrollView]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[scrollView]|", options: .alignAllCenterX, metrics: nil, views: ["scrollView": scrollView]))
        
    
        // We set constraints for StackView that's inside our ScrollView
        stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 5
        scrollView.addSubview(stackView)
        
        scrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[stackView]|", options: .alignAllCenterX, metrics: nil, views: ["stackView": stackView]))
        scrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[stackView]|", options: .alignAllCenterX, metrics: nil, views: ["stackView": stackView]))
    }
    
    
    //С помощью этой функции мы получаем массив и присваиваем его значения нашим button-ам
    func addPlaces(places: [InterestingPlace]){
        self.places = places
        for (index, place) in places.enumerated(){
            let placeButton = UIButton(type: .custom)
            let widthConstraint = NSLayoutConstraint(item: placeButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 70)
            let heightConstraint = NSLayoutConstraint(item: placeButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 75)
            NSLayoutConstraint.activate([widthConstraint, heightConstraint])
            let image = UIImage(named: place.imageName)
            placeButton.setImage(image, for: .normal)
            placeButton.addTarget(self, action: #selector(selectedPlace(_:)), for: .touchUpInside)
            placeButton.tag = index
            stackView.addArrangedSubview(placeButton)
        }
    }
    
    
    // По нажатию на button определяем selected item, затем мы передаем его в ParentVC , там в зависимости от этого будем передавать новые значения UI-элементам
    @objc func selectedPlace(_ sender: UIButton) {
        guard let place = places?[sender.tag] else { return }
        delegate?.selectedPlaceViewController(controller: self, didSelectPlace: place)
        //delegate?.selectedPlaceViewController(self, didSelectPlace: place)
    }
    
    
    //Определили размеры ScrollView
    override func viewDidLayoutSubviews(){
        super.viewDidLayoutSubviews()
        scrollView.contentSize = CGSize(width: stackView.frame.width, height: stackView.frame.height)
    }
}
