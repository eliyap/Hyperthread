//
//  ModalAlbumDataSource.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/3/22.
//

import UIKit

enum AlbumSection: Hashable {
    case all
}

final class ModalAlbumDataSource: UICollectionViewDiffableDataSource<AlbumSection, Int> {
    public typealias Snapshot = NSDiffableDataSourceSnapshot<AlbumSection, Int>
}
