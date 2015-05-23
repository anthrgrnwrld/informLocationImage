//
//  ViewController.swift
//  InformLocatationImage
//
//  Created by Masaki Horimoto on 2015/05/11.
//  Copyright (c) 2015年 Masaki Horimoto. All rights reserved.
//

import UIKit

//自分がいるlocation#を記憶できるクラス (UIImageViewを継承)
class LocationImageView: UIImageView {
    var location: Int! = 0
    
    convenience init() {
        self.init()
        self.location = 0       //初期はlocation# = 0
    }
    
}

//二つのCGPointを持つクラス (イメージ移動の座標管理)
class TwoCGPoint {
    var imagePoint: CGPoint!    //イメージの座標保存用
    var touchPoint: CGPoint!    //タッチ位置の座標保存用
}

//タッチスタート時と移動後の座標情報を持つクラス (イメージ移動の座標管理)
class ControlImageClass {
    var start: TwoCGPoint = TwoCGPoint()            //スタート時の画像座標とタッチ座標
    var destination: TwoCGPoint = TwoCGPoint()      //移動後(または移動途中の)画像座標とタッチ座標
    var draggingView: UIView?                       //どの画像を移動しているかを保存
    
    //startとdestinationからタッチ中の移動量を計算
    var delta: CGPoint {
        get {
            let deltaX: CGFloat = destination.touchPoint.x - start.touchPoint.x
            let deltaY: CGFloat = destination.touchPoint.y - start.touchPoint.y
            return CGPointMake(deltaX, deltaY)
        }
    }
    
    //移動後(または移動中の)画像の座標取得用のメソッド
    func setMovedImagePoint() -> CGPoint {
        let imagePointX: CGFloat = start.imagePoint.x + delta.x
        let imagePointY: CGFloat = start.imagePoint.y + delta.y
        destination.imagePoint = CGPointMake(imagePointX, imagePointY)
        return destination.imagePoint
    }
}

class ViewController: UIViewController {
    
    @IBOutlet weak var imageBeHereNow: LocationImageView!
    @IBOutlet weak var outputLocatedInfo: UILabel!
    @IBOutlet var locationLabelArray: [UILabel]!
    var pointBeHereNow: ControlImageClass! = ControlImageClass()    //移動座標管理用変数を宣言
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageBeHereNow.image = UIImage(named: "BeHereNow.jpg")
        imageBeHereNow.userInteractionEnabled = true
        
        outputLocatedInfo.text = "imageBeHereNow's location is #\(self.imageBeHereNow.location)"    //現在のlocation#をLabelに表示する
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //画像の表示位置の決定
        for (index, val) in enumerate(locationLabelArray) {
            let tag = locationLabelArray[index].tag
            let centerPoint = locationLabelArray[index].center
            if self.imageBeHereNow.location == index {
                self.imageBeHereNow.center = centerPoint
            } else {
                //Do nothing
            }
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touch = touches.first as! UITouch
        
        //タッチスタート時の座標情報を保存する
        if touch.view is UIImageView {
            pointBeHereNow.start.imagePoint = imageBeHereNow.center
            pointBeHereNow.start.touchPoint = touch.locationInView(self.view)
            pointBeHereNow.draggingView = touch.view
        } else {
            //Do nothing
        }
        
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touch = touches.first as! UITouch
        
        //移動後(または移動中)の座標情報を保存し、それらの情報から画像の表示位置を変更する
        //タッチされたviewと保存されたviewが等しい時のみ画像を動かす
        if touch.view == pointBeHereNow.draggingView {
            pointBeHereNow.destination.touchPoint = touch.locationInView(self.view)
            imageBeHereNow.center = pointBeHereNow.setMovedImagePoint()     //移動後の座標を取得するメソッドを使って画像の表示位置を変更
            
        } else {
            //Do nothing
        }
        
    }
    
    //各locationとの距離を管理するクラス
    class distanceClass {
        var distanceArray: [CGFloat] = []
        var minIndex: Int!
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        let touch = touches.first as! UITouch
        
        //タッチ完了時に最も近いlocation位置へアニメーションで吸着する処理
        //タッチsaretaviewのtagとpointBeHereNowに保存されたtagと等しい時のみ画像を動かす
        if touch.view == pointBeHereNow.draggingView {
            
            var distance: distanceClass = distanceClass()   //locationとの距離を管理する変数
            distance = getDistance()                        //各locationの距離と最小値のindexを保存
            
            animateToLocationWithDistance(distance)         //最も近いlocationへ or 元の位置へアニメーション
            
        } else {
            //Do nothing
        }
        
        outputLocatedInfo.text = "imageBeHereNow's location is #\(self.imageBeHereNow.location)"    //Labelの更新
        
    }
    
    
    //各locationとの距離とその最小値のIndexを保存するメソッド
    func getDistance() -> distanceClass {
        let distance: distanceClass = distanceClass()
        
        distance.distanceArray = locationLabelArray.map({self.getDistanceWithPoint1(self.imageBeHereNow.center, point2: $0.center)})
        let (index, _) = reduce(enumerate(distance.distanceArray), (-1, CGFloat(FLT_MAX))) {
            $0.1 < $1.1 ? $0 : $1
        }
        distance.minIndex = index

        return distance
    }
    
    
    //2点の座標間の距離を取得するメソッド
    func getDistanceWithPoint1(point1: CGPoint, point2: CGPoint) -> CGFloat {
        let distanceX = point1.x - point2.x
        let distanceY = point1.y - point2.y
        let distance = sqrt(distanceX * distanceX + distanceY * distanceY)
        return distance
    }
    
    
    //最も近いlocationへ or 元の位置へアニメーションするメソッド
    func animateToLocationWithDistance(distance: distanceClass) {
        let point: CGPoint!
        
        if distance.distanceArray[distance.minIndex] < 50 {
            //最小値の距離が50未満の時は、そのlocationへアニメーションする
            point = locationLabelArray[distance.minIndex].center
            imageBeHereNow.location = distance.minIndex
        } else {
            //最小値の距離が50以上の時は、元のlocationへアニメーションする
            point = locationLabelArray[imageBeHereNow.location].center
        }
        
        animationWithImageView(imageBeHereNow, point: point)
    }
    
    
    //引数1のUIImageViewを引数2の座標へアニメーションするメソッド
    func animationWithImageView(ImageView: UIImageView, point: CGPoint) {
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.imageBeHereNow.center = point
        })
        
    }
    
    
}

