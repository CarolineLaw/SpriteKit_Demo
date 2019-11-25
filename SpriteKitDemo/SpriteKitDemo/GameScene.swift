//
//  GameScene.swift
//  SpriteKitDemo
//
//  Created by Caroline Law on 11/21/19.
//  Copyright © 2019 WT. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    let gridSpacing = CGSize(width: 12, height: 12)
    let rowCount = 5
    let colCount = 6

    var contactQueue = [SKPhysicsContact]()

    private var playerNode = SKShapeNode()
    
    override func didMove(to view: SKView) {

        self.playerNode = SKShapeNode.init(rectOf: CGSize.init(width: 50, height: 50), cornerRadius: 50 * 0.3)
        playerNode.position = CGPoint(x: 0, y: -350)
        addChild(playerNode)

        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsBody?.categoryBitMask = PhysicsCategory.wall
//        self.physicsBody?.collisionBitMask = PhysicsCategory.projectile
//        self.physicsBody?.contactTestBitMask = PhysicsCategory.projectile

        setupBlocks()

        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        let touchLocation = touch.location(in: self)

        let projectile = SKSpriteNode.init(color: .white, size: CGSize(width: 25, height: 25))
        projectile.name = "Projectile"
        projectile.position = playerNode.position

        let offset = touchLocation - projectile.position

        if offset.y < 0 { return }

        projectile.physicsBody = SKPhysicsBody(rectangleOf: projectile.frame.size)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.affectedByGravity = false
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.block | PhysicsCategory.wall
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.wall
        projectile.physicsBody?.usesPreciseCollisionDetection = true

        addChild(projectile)

        let direction = offset.normalized()

        let speed = direction * 2000

        let realDest = speed + projectile.position

        let actionMove = SKAction.move(to: realDest, duration: 2.5)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
    }

    func didBegin(_ contact: SKPhysicsContact) {
        contactQueue.append(contact)
    }

    func handle(_ contact: SKPhysicsContact) {
        if contact.bodyA.node?.parent == nil || contact.bodyB.node?.parent == nil {
            return
        }

        if contact.bodyA.node?.name == "Block" {
            contact.bodyA.node?.removeFromParent()
        } else if contact.bodyB.node?.name == "Block" {
            contact.bodyB.node?.removeFromParent()
        }

    }

    func processContacts(forUpdate currentTime: CFTimeInterval) {
        for contact in contactQueue {
            handle(contact)

            if let index = contactQueue.firstIndex(of: contact) {
                contactQueue.remove(at: index)
            }
        }
    }

    struct BlockType {
        static var size: CGSize {
            return CGSize(width: 50, height: 50)
        }
    }

    func makeBlock() -> SKNode {
        let block = SKSpriteNode(color: .white, size: BlockType.size)
        block.name = "Block"

        block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
        block.physicsBody?.isDynamic = false
        block.physicsBody?.categoryBitMask = PhysicsCategory.block
        block.physicsBody?.contactTestBitMask = 0x0
        block.physicsBody?.collisionBitMask = 0x0

        return block
    }

    func setupBlocks() {

        let baseOrigin = CGPoint(x: -155, y: 0)

        for row in 0..<rowCount {

            let y = CGFloat(50)

            let blockPositionY = CGFloat(row) * (BlockType.size.height * 2) - y

            var blockPosition = CGPoint(x: baseOrigin.x, y: blockPositionY)

            for _ in 0..<colCount {
                let block = makeBlock()
                block.position = blockPosition

                addChild(block)

                blockPosition = CGPoint(
                    x: blockPosition.x + BlockType.size.width + gridSpacing.width,
                    y: blockPositionY
                )
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        processContacts(forUpdate: currentTime)
    }
}

struct PhysicsCategory {
    static let projectile: UInt32 = 0b1
    static let block     : UInt32 = 0b10
    static let wall      : UInt32 = 0b11
}

func +(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
  func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
  }
#endif

extension CGPoint {
  func length() -> CGFloat {
    return sqrt(x*x + y*y)
  }

  func normalized() -> CGPoint {
    return self / length()
  }
}
