import SpriteKit
import UIKit
#if canImport(BlockFitCore)
import BlockFitCore
#endif

/// Greybox gameplay scene (BF-006…009). Reads `GameSession`; owns no rules.
@MainActor
final class BoardScene: SKScene {
    // MARK: State
    private(set) var session: GameSession
    private var cometEnabled = false
    private var cell: CGFloat = 40
    private var boardOrigin = CGPoint.zero            // bottom-left of the 8×8 grid
    private var cellNodes: [[SKSpriteNode]] = []
    private var traySlots: [SKNode] = []              // slot centres
    private var trayNodes: [SKNode?] = [nil, nil, nil]
    private let content = SKNode()
    private let overlay = SKNode()
    private let scoreLabel = SKLabelNode()
    private let bestLabel = SKLabelNode()
    private let comboLabel = SKLabelNode()
    private var paddle = SKSpriteNode()
    private var best = 0
    private var busy = false

    // Drag
    private var dragSlot: Int?
    private var dragNode: SKNode?
    private var ghost: SKNode?
    private var previewNodes: [SKNode] = []
    private let liftCells: CGFloat = 1.5
    private let traySlotScale: CGFloat = 0.6

    var onGameOver: ((Int) -> Void)?
    /// Levels mode callbacks: (moves) / ().
    var onLevelWon: ((Int) -> Void)?
    var onLevelLost: (() -> Void)?
    var onBoostersChanged: (() -> Void)?
    private let goalLabel = SKLabelNode()
    private var smashMode = false
    private var seed: UInt64

    // MARK: Init
    init(seed: UInt64, cometEnabled: Bool = false, comboSetup: Bool = false) {
        var cfg = GameConfig.defaults
        cfg.comet.enabled = cometEnabled
        self.cometEnabled = cometEnabled
        self.seed = seed
        self.session = BoardScene.makeSession(seed: seed, config: cfg, comboSetup: comboSetup)
        super.init(size: CGSize(width: 390, height: 844))
        scaleMode = .resizeFill
    }
    /// Levels / Daily: scene driven by a prepared session.
    init(session: GameSession, seed: UInt64) {
        self.session = session
        self.seed = seed
        super.init(size: CGSize(width: 390, height: 844))
        scaleMode = .resizeFill
    }
    required init?(coder: NSCoder) { fatalError("not used") }

    static func makeSession(seed: UInt64, config: GameConfig, comboSetup: Bool) -> GameSession {
        guard comboSetup else { return GameSession(seed: seed, config: config) }
        // Gate 0 capture: rows 2–4 full except column 0; a vertical 1×3 clears all three at once.
        var b = Board(size: config.boardSize)
        let colors: [BrickColor] = [.red, .orange, .yellow, .green, .blue, .violet, .pink]
        for r in 2...4 { for c in 1..<8 { b[r, c] = .brick(colors[(c + r) % colors.count]) } }
        b[6, 3] = .brick(.teal); b[7, 3] = .brick(.teal); b[7, 4] = .brick(.pink); b[0, 6] = .brick(.sky)
        // Anchors for Comet Clear to chew on: a diagonal up-left of the last cleared row's end.
        b[1, 6] = .brick(.lime); b[0, 5] = .brick(.cream); b[6, 6] = .brick(.steel)
        let i3v = PieceCatalog.piece(id: "i3v")!
        let tray = [i3v, PieceCatalog.piece(id: "square2")!, PieceCatalog.piece(id: "l3_0")!]
        return GameSession(seed: seed, config: config, board: b, initialTray: tray)
    }

    // MARK: Layout
    override func didMove(to view: SKView) {
        addChild(content); addChild(overlay)
        overlay.zPosition = 100
        layoutScene()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard parent != nil || view != nil else { return }
        layoutScene()
    }

    private func layoutScene() {
        guard size.width > 0, size.height > 0 else { return }
        content.removeAllChildren()
        let safeTop: CGFloat = view?.safeAreaInsets.top ?? 47
        let safeBottom: CGFloat = view?.safeAreaInsets.bottom ?? 34
        let margin: CGFloat = 20
        let boardW = min(size.width - margin * 2, 640) * 0.92
        let pitch = boardW / 8
        cell = pitch
        let boardH = pitch * 8
        let headerH: CGFloat = 64
        let headerY = size.height - safeTop - headerH / 2 - 8

        // Background
        let bg = SKSpriteNode(texture: TextureFactory.gradient(size: size))
        bg.size = size; bg.position = CGPoint(x: size.width / 2, y: size.height / 2); bg.zPosition = -10
        content.addChild(bg)

        // Header (cream panel)
        let header = SKShapeNode(rectOf: CGSize(width: size.width - margin * 2, height: headerH), cornerRadius: 12)
        header.fillColor = Theme.cream; header.strokeColor = Theme.ink; header.lineWidth = 4
        header.position = CGPoint(x: size.width / 2, y: headerY)
        content.addChild(header)
        styleLabel(scoreLabel, size: Theme.FontSize.l, color: Theme.ink)
        scoreLabel.position = CGPoint(x: size.width / 2, y: headerY - 12)
        content.addChild(scoreLabel)
        styleLabel(goalLabel, size: Theme.FontSize.s, color: Theme.yellow)
        goalLabel.position = CGPoint(x: size.width / 2, y: headerY - headerH / 2 - 16)
        content.addChild(goalLabel)
        styleLabel(bestLabel, size: Theme.FontSize.s, color: Theme.ink)
        bestLabel.horizontalAlignmentMode = .right
        bestLabel.position = CGPoint(x: size.width - margin - 14, y: headerY - 5)
        content.addChild(bestLabel)

        // Board
        let boardTop = headerY - headerH / 2 - 28
        boardOrigin = CGPoint(x: (size.width - boardH) / 2, y: boardTop - boardH)
        let frame = SKShapeNode(rectOf: CGSize(width: boardH + 16, height: boardH + 16), cornerRadius: 14)
        frame.fillColor = Theme.boardWell; frame.strokeColor = Theme.ink; frame.lineWidth = 4
        frame.position = CGPoint(x: size.width / 2, y: boardOrigin.y + boardH / 2)
        content.addChild(frame)
        cellNodes = (0..<8).map { r in
            (0..<8).map { c in
                let n = SKSpriteNode(texture: TextureFactory.well(size: pitch - 4))
                n.size = CGSize(width: pitch - 4, height: pitch - 4)
                n.position = cellCenter(GridPoint(row: r, col: c)); n.zPosition = 1
                content.addChild(n); return n
            }
        }

        // Paddle (decorative; the ball launches from here)
        paddle = SKSpriteNode(color: Theme.purple, size: CGSize(width: boardH * 0.4, height: 12))
        paddle.position = CGPoint(x: size.width / 2, y: boardOrigin.y - 22); paddle.zPosition = 1
        content.addChild(paddle)

        styleLabel(comboLabel, size: Theme.FontSize.m, color: Theme.ink)
        comboLabel.alpha = 0; comboLabel.zPosition = 50
        content.addChild(comboLabel)

        // Tray
        let trayH: CGFloat = 104
        let trayY = max(safeBottom + trayH / 2 + 12, boardOrigin.y - 50 - trayH / 2)
        let panel = SKShapeNode(rectOf: CGSize(width: size.width - margin * 2, height: trayH), cornerRadius: 14)
        panel.fillColor = Theme.cream; panel.strokeColor = Theme.ink; panel.lineWidth = 4
        panel.position = CGPoint(x: size.width / 2, y: trayY); content.addChild(panel)
        traySlots.forEach { $0.removeFromParent() }
        traySlots = (0..<3).map { i in
            let n = SKNode()
            let w = (size.width - margin * 2) / 3
            n.position = CGPoint(x: margin + w * (CGFloat(i) + 0.5), y: trayY)
            content.addChild(n); return n
        }
        trayNodes = [nil, nil, nil]
        syncBoard(); syncTray(); syncHUD()
        if session.isGameOver { showGameOver() }
    }

    private func styleLabel(_ l: SKLabelNode, size: CGFloat, color: UIColor) {
        l.fontName = Theme.fontName; l.fontSize = size; l.fontColor = color
        l.horizontalAlignmentMode = .center; l.verticalAlignmentMode = .baseline; l.zPosition = 5
    }

    private func cellCenter(_ p: GridPoint) -> CGPoint {
        CGPoint(x: boardOrigin.x + (CGFloat(p.col) + 0.5) * cell,
                y: boardOrigin.y + (CGFloat(7 - p.row) + 0.5) * cell)
    }

    // MARK: Sync from Core
    private func syncBoard() {
        let px = cell - 4
        for r in 0..<8 { for c in 0..<8 {
            let n = cellNodes[r][c]
            n.alpha = 1; n.setScale(1)
            switch session.board[r, c] {
            case .empty: n.texture = TextureFactory.well(size: px)
            case .brick(let col): n.texture = TextureFactory.brick(col, size: px)
            case .steel(let hits): n.texture = TextureFactory.brick(.steel, size: px, cracked: hits < 2)
            case .gold: n.texture = TextureFactory.brick(.yellow, size: px, gold: true)
            }
        } }
    }

    private func syncHUD() {
        scoreLabel.text = "\(session.score)"
        bestLabel.text = session.goal == nil ? "BEST \(max(best, session.score))" : ""
        if let g = session.goal {
            let p = g.progress(gold: session.goldCollected, score: session.score, lines: session.linesTotal)
            let name: String
            switch g { case .collectGold: name = "GOLD"; case .reachScore: name = "SCORE"; case .clearLines: name = "LINES" }
            goalLabel.text = "\(name) \(min(p, g.target))/\(g.target)"
        } else { goalLabel.text = "" }
    }

    private func pieceNode(_ piece: Piece, cell pitch: CGFloat) -> SKNode {
        let root = SKNode()
        let px = pitch - 4
        let w = CGFloat(piece.width) * pitch, h = CGFloat(piece.height) * pitch
        for o in piece.offsets {
            let s = SKSpriteNode(texture: TextureFactory.brick(piece.color, size: px))
            s.size = CGSize(width: px, height: px)
            s.position = CGPoint(x: (CGFloat(o.col) + 0.5) * pitch - w / 2, y: h / 2 - (CGFloat(o.row) + 0.5) * pitch)
            root.addChild(s)
        }
        return root
    }

    private func syncTray(animated: Bool = false) {
        for i in 0..<3 {
            trayNodes[i]?.removeFromParent(); trayNodes[i] = nil
            guard i < session.tray.count, let p = session.tray[i] else { continue }
            let n = pieceNode(p, cell: cell)
            n.setScale(traySlotScale)
            traySlots[i].addChild(n); trayNodes[i] = n
            if animated {
                n.setScale(0.01)
                n.run(.sequence([.wait(forDuration: 0.06 * Double(i)), .scale(to: traySlotScale, duration: 0.18)]))
            }
        }
    }

    // MARK: Touch / drag
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let p = t.location(in: self)
        if session.isGameOver { if session.goal == nil { restart(seed: seed &+ 1) }; return }   // deterministic seed chain (rule 2)
        guard !busy, dragSlot == nil else { return }
        if smashMode {
            smashMode = false
            let col = Int(((p.x - boardOrigin.x) / cell).rounded(.down))
            let row = 7 - Int(((p.y - boardOrigin.y) / cell).rounded(.down))
            let gp = GridPoint(row: row, col: col)
            guard session.board.contains(gp) else { return }
            let color = Theme.brick(.steel)
            if let r = session.smash(at: gp), !(r.clearedCells.isEmpty && r.steelCracked.isEmpty) {
                let ball = makeBall(); ball.position = paddle.position; addChild(ball)
                ball.run(.sequence([.move(to: cellCenter(gp), duration: 0.12), .removeFromParent()]))
                run(.sequence([.wait(forDuration: 0.12), .run { [weak self] in
                    self?.burst(at: self?.cellCenter(gp) ?? .zero, color: color)
                    self?.syncBoard(); self?.syncHUD()
                    self?.onBoostersChanged?()
                    if let s = self?.session, s.isWon { self?.onLevelWon?(s.moves) }
                    else if let s = self?.session, s.isGameOver { self?.showGameOver() }
                }]))
            }
            return
        }
        for i in 0..<3 where session.tray.indices.contains(i) {
            guard let piece = session.tray[i] else { continue }
            let slot = traySlots[i]
            let hit = CGRect(x: slot.position.x - 50, y: slot.position.y - 52, width: 100, height: 104)
            if hit.contains(p) {
                dragSlot = i
                trayNodes[i]?.alpha = 0.25
                let n = pieceNode(piece, cell: cell)
                n.zPosition = 60; n.setScale(traySlotScale)
                n.run(.scale(to: 1, duration: 0.08))
                addChild(n); dragNode = n
                moveDrag(to: p)
                return
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, dragSlot != nil else { return }
        moveDrag(to: t.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let slot = dragSlot, let t = touches.first else { return }
        let origin = snappedOrigin(for: t.location(in: self), slot: slot)
        clearPreview()
        if let origin, session.canPlace(slot: slot, at: origin) {
            dragNode?.removeFromParent(); dragNode = nil; dragSlot = nil
            commit(slot: slot, at: origin)
        } else {
            cancelDrag()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        clearPreview(); cancelDrag()
    }

    private func cancelDrag() {
        guard let slot = dragSlot, let n = dragNode else { return }
        let home = traySlots[slot].position
        n.run(.group([.move(to: home, duration: 0.14), .scale(to: traySlotScale, duration: 0.14)])) { [weak self, weak n] in
            n?.removeFromParent()
            self?.trayNodes[slot]?.alpha = 1
        }
        dragNode = nil; dragSlot = nil
    }

    /// Piece is lifted `liftCells` above the finger so it is never hidden (design.md / product.md §2).
    private func moveDrag(to touch: CGPoint) {
        guard let n = dragNode, let slot = dragSlot, let piece = session.tray[slot] else { return }
        n.position = CGPoint(x: touch.x, y: touch.y + liftCells * cell)
        updatePreview(for: piece, slot: slot, touch: touch)
    }

    private func snappedOrigin(for touch: CGPoint, slot: Int) -> GridPoint? {
        guard let piece = session.tray[slot] else { return nil }
        let cx = touch.x, cy = touch.y + liftCells * cell
        let left = cx - CGFloat(piece.width) * cell / 2
        let top = cy + CGFloat(piece.height) * cell / 2
        let col = Int(((left - boardOrigin.x) / cell).rounded())
        let row = Int(((boardOrigin.y + 8 * cell - top) / cell).rounded())
        let o = GridPoint(row: row, col: col)
        return (0...(8 - piece.height)).contains(row) && (0...(8 - piece.width)).contains(col) ? o : nil
    }

    private func updatePreview(for piece: Piece, slot: Int, touch: CGPoint) {
        let previousOrigin = ghostOrigin
        clearPreview()
        guard let o = snappedOrigin(for: touch, slot: slot) else { ghostOrigin = nil; return }
        ghostOrigin = o
        if previousOrigin != o { Haptics.selection() }
        let valid = session.canPlace(slot: slot, at: o)
        for off in piece.offsets {
            let p = GridPoint(row: o.row + off.row, col: o.col + off.col)
            let g = SKSpriteNode(texture: TextureFactory.brick(piece.color, size: cell - 4))
            g.size = CGSize(width: cell - 4, height: cell - 4)
            g.position = cellCenter(p); g.zPosition = 20
            g.alpha = 0.35
            if !valid { g.color = Theme.invalid; g.colorBlendFactor = 0.8 }
            addChild(g); previewNodes.append(g)
        }
        guard valid else { return }
        var copy = session
        guard let out = copy.place(slot: slot, at: o) else { return }
        for line in out.clear.lines {                       // lines that would clear glow
            for i in 0..<8 {
                let p = line.cell(i)
                let glow = SKShapeNode(rectOf: CGSize(width: cell - 2, height: cell - 2), cornerRadius: 3)
                glow.strokeColor = Theme.yellow; glow.lineWidth = 3; glow.fillColor = .clear
                glow.position = cellCenter(p); glow.zPosition = 21
                addChild(glow); previewNodes.append(glow)
            }
        }
        if cometEnabled, let _ = out.comet {                // Comet diagonal preview
            for p in out.cometPath {
                let d = SKShapeNode(circleOfRadius: cell * 0.12)
                d.fillColor = Theme.blue; d.strokeColor = Theme.ink
                d.position = cellCenter(p); d.zPosition = 22
                addChild(d); previewNodes.append(d)
            }
        }
    }
    private var ghostOrigin: GridPoint?

    private func clearPreview() {
        previewNodes.forEach { $0.removeFromParent() }; previewNodes.removeAll()
    }

    // MARK: Commit + clear animation
    private func commit(slot: Int, at origin: GridPoint) {
        guard let piece = session.tray[slot] else { return }
        shardColors.removeAll()
        for r in 0..<8 { for c in 0..<8 {
            if case .brick(let col) = session.board[r, c] { shardColors[GridPoint(row: r, col: c)] = Theme.brick(col) }
        } }
        for off in piece.offsets {
            shardColors[GridPoint(row: origin.row + off.row, col: origin.col + off.col)] = Theme.brick(piece.color)
        }
        guard let out = session.place(slot: slot, at: origin) else { return }
        // Show the placed piece immediately; line clears resolve over the next beats.
        let px = cell - 4
        for off in piece.offsets {
            let p = GridPoint(row: origin.row + off.row, col: origin.col + off.col)
            let n = cellNodes[p.row][p.col]
            n.texture = TextureFactory.brick(piece.color, size: px)
            n.run(.sequence([.scale(to: 0.9, duration: 0.04), .scale(to: 1.05, duration: 0.04), .scale(to: 1, duration: 0.04)]))
        }
        trayNodes[slot]?.removeFromParent(); trayNodes[slot] = nil
        Haptics.impact(.medium)

        var total: TimeInterval = 0.1
        if !out.clear.isEmpty { total = animateClear(out, placed: piece) }
        busy = true
        run(.sequence([.wait(forDuration: total), .run { [weak self] in
            guard let self else { return }
            self.syncBoard(); self.syncHUD()
            if out.trayRefilled { self.syncTray(animated: true) }
            self.busy = false
            if out.won { Haptics.impact(.heavy); self.onLevelWon?(self.session.moves); return }
            if out.gameOver { self.best = max(self.best, self.session.score); self.showGameOver() }
        }]))
        if !out.clear.isEmpty { syncHUDScoreLater(after: total * 0.5) }
    }

    private func syncHUDScoreLater(after t: TimeInterval) {
        run(.sequence([.wait(forDuration: t), .run { [weak self] in self?.syncHUD() }]))
    }

    /// Ball launches from the paddle and travels each cleared line in sequence (BF-007).
    private func animateClear(_ out: MoveOutcome, placed: Piece) -> TimeInterval {
        let lineTime = 0.18, gap = 0.08
        var t: TimeInterval = 0.12
        var burstAt: [GridPoint: TimeInterval] = [:]

        for (idx, line) in out.clear.lines.enumerated() {
            let startP = cellCenter(line.cell(0)), endP = cellCenter(line.cell(7))
            let ball = makeBall()
            ball.position = paddle.position
            addChild(ball)
            ball.run(.sequence([
                .wait(forDuration: t),
                .move(to: startP, duration: 0.08),
                .move(to: endP, duration: lineTime),
                .fadeOut(withDuration: 0.05), .removeFromParent(),
            ]))
            for i in 0..<8 {
                let p = line.cell(i)
                let when = t + 0.08 + lineTime * Double(i) / 7
                if burstAt[p] == nil { burstAt[p] = when }
            }
            Haptics.impactLater(after: t + 0.1, style: idx == 0 ? .rigid : .heavy)
            t += 0.08 + lineTime + gap
        }
        if out.clear.lineCount >= 2 { showCombo(out.clear.lineCount, at: 0.12) }

        for p in out.clear.clearedCells {
            let when = burstAt[p] ?? t
            let color = colorForShard(at: p, placed: placed)
            let node = cellNodes[p.row][p.col]
            run(.sequence([.wait(forDuration: when), .run { [weak self, weak node] in
                node?.texture = TextureFactory.well(size: (self?.cell ?? 40) - 4)
                self?.burst(at: self?.cellCenter(p) ?? .zero, color: color)
            }]))
        }

        if let comet = out.comet {
            let ball = makeBall(color: Theme.blue)
            ball.position = cellCenter(out.cometPath.first ?? GridPoint(row: 0, col: 0))
            ball.alpha = 0
            var actions: [SKAction] = [.wait(forDuration: t), .fadeIn(withDuration: 0.02)]
            for p in out.cometPath { actions.append(.move(to: cellCenter(p), duration: 0.07)) }
            actions += [.fadeOut(withDuration: 0.05), .removeFromParent()]
            addChild(ball); ball.run(.sequence(actions))
            for p in comet.clearedCells {
                let idx = out.cometPath.firstIndex(of: p) ?? 0
                let when = t + 0.07 * Double(idx + 1)
                let node = cellNodes[p.row][p.col]
                let color = colorForShard(at: p, placed: placed)
                run(.sequence([.wait(forDuration: when), .run { [weak self, weak node] in
                    node?.texture = TextureFactory.well(size: (self?.cell ?? 40) - 4)
                    self?.burst(at: self?.cellCenter(p) ?? .zero, color: color)
                }]))
            }
            t += 0.07 * Double(out.cometPath.count) + 0.1
        }
        return t + 0.15
    }

    /// Board colours are gone by the time we animate, so remember them from before the clear.
    private var shardColors: [GridPoint: UIColor] = [:]
    private func colorForShard(at p: GridPoint, placed: Piece) -> UIColor {
        shardColors[p] ?? Theme.brick(placed.color)
    }

    private func makeBall(color: UIColor = .white) -> SKShapeNode {
        let b = SKShapeNode(circleOfRadius: cell * 0.2)
        b.fillColor = color; b.strokeColor = Theme.ink; b.lineWidth = 2; b.zPosition = 40
        return b
    }

    private func burst(at pos: CGPoint, color: UIColor) {
        let n = UIAccessibility.isReduceMotionEnabled ? 3 : 7     // Reduce Motion: ~30% particles
        for _ in 0..<n {
            let s = SKSpriteNode(color: color, size: CGSize(width: cell * 0.2, height: cell * 0.2))
            s.position = pos; s.zPosition = 30
            addChild(s)
            let d = CGVector(dx: CGFloat.random(in: -cell...cell), dy: CGFloat.random(in: -cell * 0.6...cell * 1.2))
            s.run(.sequence([.group([.move(by: d, duration: 0.35), .fadeOut(withDuration: 0.35),
                                     .rotate(byAngle: .pi, duration: 0.35)]), .removeFromParent()]))
        }
    }

    private func showCombo(_ n: Int, at delay: TimeInterval) {
        comboLabel.text = "COMBO x\(n)"
        comboLabel.fontColor = Theme.yellow
        comboLabel.position = CGPoint(x: size.width / 2, y: boardOrigin.y + cell * 8 + 6)
        comboLabel.alpha = 0
        comboLabel.run(.sequence([.wait(forDuration: delay), .fadeIn(withDuration: 0.05),
                                  .wait(forDuration: 0.5), .fadeOut(withDuration: 0.2)]))
        if !UIAccessibility.isReduceMotionEnabled {
            content.run(.sequence([.wait(forDuration: delay + 0.2),
                                   .moveBy(x: 4, y: 0, duration: 0.03), .moveBy(x: -8, y: 0, duration: 0.05),
                                   .moveBy(x: 4, y: 0, duration: 0.03)]))
        }
    }

    // MARK: Game over / restart (BF-009)
    private func showGameOver() {
        overlay.removeAllChildren()
        let dim = SKSpriteNode(color: .black, size: size)
        dim.alpha = 0.55; dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(dim)
        if let nm = session.nearMiss {                    // near-miss: the gap pulses yellow
            for p in nm.gapCells {
                let g = SKShapeNode(rectOf: CGSize(width: cell - 2, height: cell - 2), cornerRadius: 3)
                g.strokeColor = Theme.yellow; g.lineWidth = 4; g.fillColor = .clear
                g.position = cellCenter(p)
                g.run(.repeatForever(.sequence([.fadeAlpha(to: 0.3, duration: 0.4), .fadeAlpha(to: 1, duration: 0.4)])))
                overlay.addChild(g)
            }
        }
        func label(_ s: String, _ size: CGFloat, _ y: CGFloat, _ color: UIColor) {
            let l = SKLabelNode(text: s); styleLabel(l, size: size, color: color)
            l.position = CGPoint(x: self.size.width / 2, y: y); overlay.addChild(l)
        }
        if session.goal != nil { Haptics.warning(); onLevelLost?(); return }
        label("SO CLOSE!", Theme.FontSize.l, size.height * 0.62, Theme.yellow)
        label("SCORE \(session.score)", Theme.FontSize.m, size.height * 0.62 - 40, .white)
        label("BEST \(max(best, session.score))", Theme.FontSize.s, size.height * 0.62 - 66, Theme.mutedInk)
        label("TAP TO PLAY AGAIN", Theme.FontSize.s, size.height * 0.62 - 110, .white)
        Haptics.warning()
        onGameOver?(session.score)
    }

    // MARK: Boosters (inventory is checked/decremented by AppState before calling these)
    func performUndo() -> Bool {
        guard !busy, session.undo() else { return false }
        overlay.removeAllChildren(); syncBoard(); syncTray(); syncHUD(); return true
    }
    func performReroll() -> Bool {
        guard !busy, session.reroll() else { return false }
        syncTray(animated: true); syncHUD()
        if session.isGameOver { showGameOver() }
        return true
    }
    func beginSmash() { smashMode = true }
    var canUndo: Bool { session.canUndo }

    func restart(seed: UInt64, cometEnabled: Bool? = nil, comboSetup: Bool = false) {
        self.seed = seed
        removeAllActions(); overlay.removeAllChildren(); clearPreview()
        dragNode?.removeFromParent(); dragNode = nil; dragSlot = nil; busy = false
        children.filter { $0 !== content && $0 !== overlay }.forEach { $0.removeFromParent() }
        if let c = cometEnabled { self.cometEnabled = c }
        var cfg = GameConfig.defaults; cfg.comet.enabled = self.cometEnabled
        session = BoardScene.makeSession(seed: seed, config: cfg, comboSetup: comboSetup)
        syncBoard(); syncTray(animated: true); syncHUD()
        if session.isGameOver { showGameOver() }
    }
}

private extension Line {
    /// i-th cell (0…7) of this line, in ball travel order.
    func cell(_ i: Int) -> GridPoint {
        switch self {
        case .row(let r): return GridPoint(row: r, col: i)
        case .col(let c): return GridPoint(row: 7 - i, col: c)   // ball travels bottom→top from the paddle
        }
    }
}
