class GameManager
    constructor: (@puzzle) ->
         
    addEntity: (entity) ->
        return true

class Board
    constructor: (@size) ->
        @grid = ({} for x in [0...@size])
        @grid.push ({} for x in [0...@size]) for y in [0...@size]
        @lasers = []

class GridEntity
    constructor: (@position, @orientation, @type) ->

    rotateTo: (degrees) ->
        return true

    rotateClockwise: () ->
        return true

    rotateCounterClockwise: () ->
        return true

class Mirror extends GridEntity
    constructor: (@position, @orientation, @type) ->
        super @position @orientation @type

class Block extends GridEntity
    constructor: (@position, @orientation, @type) ->
        super @position @orientation @type
        
class Filter extends GridEntity
    constructor: (@position, @orientation, @type, @color) ->
        super @position @orientation @type

class Prism extends GridEntity
    constructor: (@position, @orientation, @type, @color) ->
        super @position @orientation @type
 
class Laser
    constructor: (@color) ->
        @chain = []

    extend: (entity) ->
        @chain.push(entity)

    truncate: () ->
        @chain.pop()


