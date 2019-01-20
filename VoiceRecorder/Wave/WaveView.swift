import Reusable
import UIKit

protocol WaveViewDelegate {
    func timeChanged(time: CGFloat)
}

final class WaveView: UIView, NibOwnerLoadable {
    var lineWidth: CGFloat = 2
    var linePadding: CGFloat = 1

    var delegate: WaveViewDelegate?

    @IBOutlet var collectionView: UICollectionView! {
        didSet {
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.register(cellType: WaveCollectionViewCell.self)
            collectionView.backgroundColor = .clear
            collectionView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        }
    }

    private var waves: [CGFloat] = []

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNibContent()
        backgroundColor = .clear
    }

    func addWave(wave: CGFloat) {
        let newIndexPath = IndexPath(item: 0, section: 0)
        waves.insert(wave, at: 0)
        collectionView.insertItems(at: [newIndexPath])
    }

    func reset() {
        waves.removeAll()
        collectionView.reloadData()
    }
    
    func remove(from: Int, complet: (() -> Void)?) {
        if !waves.isEmpty && from != (waves.count - 1) {
            waves = Array(waves[(waves.count - from)..<waves.count])
            collectionView.reloadData()
            collectionView.contentOffset = CGPoint(x: 0, y: waves.count * 2 + waves.count - 1)
            self.layoutIfNeeded()
            complet?()
        }
    }
}

extension WaveView: UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return waves.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as WaveCollectionViewCell
        cell.value = waves[indexPath.row]
        cell.waveState = .Recording
        cell.line.layer.cornerRadius = 1
        cell.line.clipsToBounds = true
        return cell
    }
}

extension WaveView: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var time = (scrollView.contentSize.width - scrollView.frame.width - scrollView.contentOffset.x)
        time = time.isNaN ? 0 : time
        let insideAll = (scrollView.contentSize.width - scrollView.frame.width)
        var realTime = floor(time * CGFloat(waves.count) / insideAll) * 0.1
        realTime = realTime.isNaN ? 0 : realTime
        print("realTime", realTime)
        delegate?.timeChanged(time: realTime)
    }
}

extension WaveView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        return CGSize(width: lineWidth, height: collectionView.frame.height)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        return linePadding
    }

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, insetForSectionAt _: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: collectionView.frame.width / 2, bottom: 0, right: collectionView.frame.width / 2)
    }
}
