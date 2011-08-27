class GameManager
    constructor: (@puzzle) ->
        @board = new Board(10)
        @changed = []
        @numEntitiesByType = {}
        
        (@numEntitiesByType[k] = 0) for k in Constants.EntityType

    addEntity: (entity) ->
        succeeded = false
        if !@getEntityAt(entity.position[0], entity.position[1])
            if @numEntitiesByType[entity.type] < @puzzle.getMaxForType(entity.type)
                   succeeded = @board.add(entity)
                   @incrementEntityType(entity.type)
                   @addToChanged(entity.position)

        return succeeded
    
    removeEntity: (entity) ->
        removeEntityAt(entity.position[0], entity.position[1])

    getEntityAt: (x, y) ->
        result = @board.getAt(x, y)

    flushChanged: () ->
        @changed = []

    addToChanged: (x, y) ->
        if not [x, y] in @changed
            @changed.push([x, y])

    removeEntityAt: (x, y) ->
        occupant = @board.getAt(x, y)
        if occupant
            @decrementEntityType(entity.type)

        @board.setAt(x, y, {})
    
    incrementEntityType: (type) ->
        @numEntitiesByType[entity.type] += 1

    decrementEntityType: (type) ->
        @numEntitiesByType[entity.type] -= 1
    
    rotateEntityClockwise: (x, y) ->
        @getEntityAt(x, y).rotateClockwise()
        @addToChanged(x, y)

    rotateEntityCounterClockwise: (x, y) ->
        @getEntityAt(x, y).rotateCounterClockwise()
        @addToChanged(x, y)

    isSolved: (x, y) ->
        # Basic idea is to walk each laser and make sure the path has the following properties
        #   - Starts at a valid start point
        #   - Ends at a valid end point
        #   - Every entity in between accepts it.
        
        results = [walkLaser(laser) for laser in @board.lasers]

        # For now, just take the win condition to be 'all lasers reaching an end state through valid moves'
        finalResult = true
        finalResult = (finalResult &= result for result in results)

    walkLaser: (laser) ->
        start = laser.chain[0]
        end = laser.chain[laser.chain.length - 1]
        
        if end.type isnt Constants.EntityType.END or
           start.type is Constants.EntityType.END
            return false
        
        currentPos = start.position
        prevPos = currentPos
        currentEntity = start
        i = 0
        success = false

        Directions =
            N: 0
            E: 1
            S: 2
            W: 3

        dir = null

        turnLeft = () ->
            dir = (dir + 1) % 4

        turnRight = () ->
            dir = (dir - 1) % 4

        move = () ->
          [ (currentPos[0]    % 2)*(currentPos[0] - 2),
           ((currentPos[1]+1) % 2)*(currentPos[1] - 1)]

        while i < laser.chain.length
            entityOnSpace = @board.getAt(currentPos[0], currentPos[1])
            i += 1 if entityOnSpace
            
            # Reached the end successfully
            if entityOnSpace.type is Constants.EntityType.END
                success = true
                break
            else if not entityOnSpace.accept(laser)
                break
            else
                if entityOnSpace
                    switch entityOnSpace.type
                        when Constants.EntityType.MIRROR
                            # Figure out which direction we bounce off the mirror
                            switch entityOnSpace.direction
                                when Constants.EntityOrient.NW, Constants.EntityOrient.SE
                                    switch dir
                                        when Directions.N, Directions.S then turnRight()
                                        when Directions.E, Directions.W then turnLeft()

                                when Constants.EntityOrient.NE, Constants.EntityOrient.SW
                                    switch dir
                                        when Directions.N, Directions.S then turnLeft()
                                        when Directions.E, Directions.W then turnRight()

                    prevPos = currentPos
                    move()

class Board
    constructor: (@size) ->
        @grid =((false for x in [0...@size]) for y in [0...@size])
        @lasers = []

    add: (entity) ->
        if entity.position[0] < @size and entity.position[1] < @size
            @grid[entity.position[1]][entity.position[0]] = entity
            return true

    setAt: (x, y, obj) ->
        if x < @size and y @size 
            @grid[y][x] = obj
            return true

    getAt: (x, y) ->
        return @grid[y][x]
        
class Puzzle
    constructor: () ->

    getMaxForType: (entityType) ->


class GridEntity
    constructor: (@position, @orientation, @mobility) ->

    rotateTo: (orientation) ->
        @orientation = orientation

    rotateClockwise: () ->
        @orientation = (@orientation + 1) % 4

    rotateCounterClockwise: () ->
        @orientation = (@orientation - 1) % 4

    # Does this entity accept this laser?
    # Acceptance means it doesn't straight up block it
    accepts: (laser) ->
        return true

class Mirror extends GridEntity
    constructor: (@position, @orientation, @mobility) ->
        @type = Constants.EntityType.MIRROR
        super(@position, @orientation, @mobility)

    accepts: (laser) ->
        return true

class Block extends GridEntity
    constructor: (@position, @orientation, @mobility) ->
        @type = Constants.EntityType.BLOCK
        super(@position, @orientation, @mobility)

    accepts: (laser) ->
        return false
        
class Filter extends GridEntity
    constructor: (@position, @orientation, @mobility, @color) ->
        @type = Constants.EntityType.FILTER
        super(@position, @orientation, @mobility)

    accepts: (laser) ->
        return laser.color is color

class Prism extends GridEntity
    constructor: (@position, @orientation, @mobility) ->
        @type = Constants.EntityType.PRISM
        super(@position, @orientation, @mobility)

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
        
