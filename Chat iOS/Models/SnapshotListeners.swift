//
//  SnapshotListeners.swift
//  Chat iOS
//
//  Created by Sebastian Morado on 10/13/21.
//  Copyright © 2021 Sebastian Morado. All rights reserved.
//

import Foundation
import Firebase

class SnapshotListeners {
    static let shared = SnapshotListeners()
    var snapshotList: [ListenerRegistration] = []
}
