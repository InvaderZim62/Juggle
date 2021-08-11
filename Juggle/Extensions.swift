//
//  Extensions.swift
//  Juggle
//
//  Created by Phil Stern on 8/10/21.
//

import SceneKit

extension Double {
    var rads: Double {
        return self * .pi / 180
    }
    
    var degs: Double {
        return self * 180 / .pi
    }
}

extension SCNVector3 {
    static func +(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }
    
    static func -(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }
    
    func distance(from: SCNVector3) -> Float {
        return sqrt(pow(from.x - self.x, 2) + pow(from.y - self.y, 2) + pow(from.z - self.z, 2))
    }
    
    func bearing(from: SCNVector3) -> Double {
        let deltaLat = self.z - from.z
        let deltaLon = self.x - from.x
        return Double(atan2(-deltaLat, deltaLon))
    }
}
