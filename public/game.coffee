class GameManager
    constructor: (@puzzle) ->
         
    addEntity: (entity) ->
        return true

class Board
    constructor: (@width, @height) ->
        @grid = ({} for x in [0...@width])
        @grid.push ({} for x in [0...@width]) for y in [0...@height]
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
class 
