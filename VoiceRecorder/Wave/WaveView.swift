import Reusable
import UIKit

protocol WaveViewDelegate {
    func timeChanged(time: CGFloat)
}

final class WaveView: UIView, NibOwnerLoadable {
    
    var lineWidth: CGFloat = 2
    var linePadding: CGFloat = 1
    
    var delegate: WaveViewDelegate?
    
//    var collectionView: UICollectionView!
    @IBOutlet weak var collectionView: UICollectionView! {
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
        self.loadNibContent()
        self.backgroundColor = .clear
        
//        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
//            self.addWave(wave: CGFloat.random(in: 0...1))
//        }
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
    
}

extension WaveView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let time = (scrollView.contentSize.width - scrollView.frame.width - scrollView.contentOffset.x)
        let insideAll = (scrollView.contentSize.width - scrollView.frame.width)
        
        let realTime = time * CGFloat(waves.count) / insideAll * 0.1
        self.delegate?.timeChanged(time: realTime)
    }
    
}

extension WaveView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: lineWidth, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return linePadding
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: collectionView.frame.width / 2, bottom: 0, right: collectionView.frame.width / 2)
    }
    
}
