import Testing
@testable import BlockFitCore

private func fillRow(_ b: inout Board, _ r: Int, except: Set<Int> = []) {
    for c in 0..<b.size where !except.contains(c) { b[r, c] = .brick(.red) }
}
private func fillCol(_ b: inout Board, _ c: Int, except: Set<Int> = []) {
    for r in 0..<b.size where !except.contains(r) { b[r, c] = .brick(.red) }
}

struct BoardTests {
    @Test func placementBounds() {
        let b = Board()
        let i3 = PieceCatalog.piece(id: "i3h")!
        #expect(b.canPlace(i3, at: GridPoint(row: 0, col: 5)))
        #expect(!b.canPlace(i3, at: GridPoint(row: 0, col: 6)))
        #expect(!b.canPlace(i3, at: GridPoint(row: -1, col: 0)))
        #expect(!b.canPlace(i3, at: GridPoint(row: 8, col: 0)))
    }

    @Test func overlapRejectedAndBoardUnchanged() {
        var b = Board()
        let sq = PieceCatalog.piece(id: "square2")!
        #expect(b.place(sq, at: GridPoint(row: 0, col: 0)))
        let before = b
        #expect(!b.place(sq, at: GridPoint(row: 1, col: 1)))
        #expect(b == before)
    }

    @Test func singleRowClear() {
        var b = Board()
        fillRow(&b, 3, except: [2, 3, 4])
        b.place(PieceCatalog.piece(id: "i3h")!, at: GridPoint(row: 3, col: 2))
        let r = b.clear()
        #expect(r.rows == [3] && r.cols.isEmpty)
        #expect(r.clearedCells.count == 8)
        #expect(b.isEmpty)
    }

    @Test func rowAndColumnSimultaneousIntersectionCountedOnce() {
        var b = Board()
        fillRow(&b, 2, except: [5]); fillCol(&b, 5, except: [2])
        b.place(PieceCatalog.piece(id: "dot")!, at: GridPoint(row: 2, col: 5))
        let r = b.clear()
        #expect(r.rows == [2] && r.cols == [5])
        #expect(r.clearedCells.count == 15)
        #expect(Set(r.clearedCells).count == 15)
        #expect(b.isEmpty)
    }

    @Test func steelNeedsTwoClears() {
        var b = Board()
        fillRow(&b, 0, except: [0])
        b[0, 0] = .steel(hits: 2)
        let first = b.clear()
        #expect(first.steelCracked == [GridPoint(row: 0, col: 0)])
        #expect(b[0, 0] == .steel(hits: 1))
        #expect(first.clearedCells.count == 7)
        fillRow(&b, 0, except: [0])
        let second = b.clear()
        #expect(second.steelBroken == [GridPoint(row: 0, col: 0)])
        #expect(b.isEmpty)
    }

    @Test func goldCollected() {
        var b = Board()
        fillRow(&b, 7, except: [1, 6])
        b[7, 1] = .gold; b[7, 6] = .gold
        let r = b.clear()
        #expect(r.goldCollected == 2)
        #expect(b.isEmpty)
    }

    @Test func steelAtIntersectionHitOnce() {
        var b = Board()
        fillRow(&b, 1, except: [1]); fillCol(&b, 1, except: [1])
        b[1, 1] = .steel(hits: 2)
        let r = b.clear()
        #expect(r.steelCracked.count == 1)
        #expect(b[1, 1] == .steel(hits: 1))
    }
}
