Constants = require('./common')

class GameManager
    constructor: (@puzzle) ->
        @board = new Board(10)
        @numEntitiesByType = {}
        
        (@numEntitiesByType[k] = 0) for k in Constants.EntityType

    addEntity: (entity) ->
        succeeded = false
        if !this.getEntityAt(entity.position[0], entity.position[1])
            if @numEntitiesByType[entity.type] < @puzzle.getMaxForType(entity.type)
                   succeeded = @board.add(entity)

        return succeeded
    
    removeEntity: (entity) ->
        removeEntityAt(entity.position[0], entity.position[1])

    getEntityAt: (x, y) ->
        return @board.getAt(x, y)

    removeEntityAt: (x, y) ->
        occupant = {}
        (occupant = elem for elem in row when elem isnt {} and elem.position is [x,y]) for row in @board
        
        if(!occupant)
            @board.setAt(x, y, {})
    
    rotateEntityClockwise: (x, y) ->
        this.getEntityAt(x, y).rotateClockwise()

    rotateEntityCounterClockwise: (x, y) ->
        this.getEntityAt(x, y).rotateCounterClockwise()

    isSolved: (x, y) ->
        return true

class Board
    constructor: (@size) ->
        @grid =(({} for x in [0...@size]) for y in [0...@size])
        @lasers = []

    add: (entity) ->
        if entity.position[0] < @size entity.position[1] < @size
            @grid[entity.position[0]][entity.position[1]] = entity
            return true

    setAt: (x, y, obj) ->
        @grid[x][y] = obj

    getAt: (x, y) ->
        @grid[x][y]

class Puzzle
    constructor: () ->

    getMaxForType: (entityType) ->


class GridEntity
    constructor: (@position, @orientation, @mobility) ->

    rotateTo: (degrees) ->
        return true

    rotateClockwise: () ->
        return true

    rotateCounterClockwise: () ->
        return true

    # Does this entity accept this laser?
    # Acceptance means it doesn't straight up block it
    accepts: (laser) ->
        return true

class Mirror extends GridEntity
    constructor: (@position, @orientation, @mobility) ->
        @type = Constants.EntityType.MIRROR
        super @position @orientation @mobility

    accepts: (laser) ->
        return true

class Block extends GridEntity
    constructor: (@position, @orientation, @mobility) ->
        @type = Constants.EntityType.BLOCK
        super @position @orientation @mobility

    accepts: (laser) ->
        return false
        
class Filter extends GridEntity
    constructor: (@position, @orientation, @mobility, @color) ->
        @type = Constants.EntityType.FILTER
        super @position @orientation @mobility

    accepts: (laser) ->
        return laser.color is color

class Prism extends GridEntity
    constructor: (@position, @orientation, @mobility) ->
        @type = Constants.EntityType.PRISM
        super @position @orientation @mobility

    accepts: (laser) ->
        return true
 
class Laser
    constructor: (@color) ->
        @chain = []

    extend: (entity) ->
        if(entity.accepts this)
            @chain.push(entity)

    truncate: () ->
        @chain.pop()

exports.GameManager = GameManager
exports.Board = Board
exports.GridEntity = GridEntity
exports.Mirror = Mirror
exports.Block = Block
exports.Filter = Filter
exports.Prism = Prism
exports.Laser = Laser
