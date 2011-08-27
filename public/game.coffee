class GameManager
    constructor: (@puzzle) ->
        @board = new Board(10) 
    addEntity: (entity) ->
        return true
    removeEntity: (x, y) ->
        occupant = {}
        (occupant = elem for elem in row when elem isnt {} and elem.position is [x,y]) for row in @board
        @board.setAt(x, y, {})

class Board
    constructor: (@size) ->
        @grid =(({} for x in [0...@size]) for y in [0...@size])
        @lasers = []

    setAt: (x, y, obj) ->
        @grid[x][y] = obj

    getAt: (x, y) ->
        @grid[x][y]

class GridEntity
    constructor: (@position, @orientation, @type) ->

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
    constructor: (@position, @orientation, @type) ->
        super @position @orientation @type

    accepts: (laser) ->
        return true

class Block extends GridEntity
    constructor: (@position, @orientation, @type) ->
        super @position @orientation @type

    accepts: (laser) ->
        return false
        
class Filter extends GridEntity
    constructor: (@position, @orientation, @type, @color) ->
        super @position @orientation @type

    accepts: (laser) ->
        return laser.color is color

class Prism extends GridEntity
    constructor: (@position, @orientation, @type) ->
        super @position @orientation @type

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
