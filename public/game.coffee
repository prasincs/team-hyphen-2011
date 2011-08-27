class GameManager
    constructor: (@puzzle, @gridX, @gridY) ->
        @board = new Board(10)
        @changed = []
        @numEntitiesByType = {}
        @endpoints = []
        
        (@numEntitiesByType[k] = 0) for _, k of Constants.EntityType

    addEntity: (entity) ->
        if entity.type is Constants.EntityType.START
            @startpoint = entity
        else if entity.type is Constants.EntityType.END
            @endpoints.push entity
        succeeded = false
        if !@getEntityAt(entity.position[0], entity.position[1])
            if @numEntitiesByType[entity.type] < @puzzle.getMaxForType(entity.type)
                   succeeded = @board.add(entity)
                   @incrementEntityType(entity.type)
                   @addToChanged(entity.position)

        #@updateLasers(entity)
        return succeeded
    
    removeEntity: (entity) ->
        removeEntityAt(entity.position[0], entity.position[1])

    updateLasers: (entity) ->
        # Ensure the laser segments are still correct given the new entity
        correctLaser(laser, entity) for laser in board.lasers when not validateLaser(laser)

    correctLaser: (laser, entity) ->
        # If a laser has segments that are no longer valid given the current entity,
        # correct it based on the laser type. (filter vs block vs mirror...)
        
        # Removes all laser segments after AND including the current segment
        chopAllAfterCurrent = () ->
            laser.segments = laser.segments[0..laser.segments.length (i-1)]

        i = 0
        currentSegment = laser.segments[i]
        while(currentSegment and i < laser.segments.length)
            if @isBetween(currentSegment, entity)
                toEntity = new LaserSegment(currentSegment.end, entity, laser)
                switch entity.type
                    when Constants.EntityType.BLOCK
                        # remove all laser segments including and after the current
                        laser.segments = laser.segments[0..laser.segments.length - (i-1)]

                        # Add the new segment that points from the end of the last segment
                        # to the new entity.
                        laser.segments.push(toEntity)
                    when Constants.EntityType.MIRROR
                        # Bounce laser
                        null
                    when Constants.EntityType.PRISM
                        # Split laser at 90 degree angles
                        rightSegment = new LaserSegment(entity, null, laser, (currentSegment.direction + 1) % 4)
                        leftSegment = new LaserSegment(entity, null, laser, (currentSegment.direction - 1) % 4)
                        chopAllAfterCurrent()

                        laser.segments.push(toEntity, rightSegment, leftSegment)

                       
                    when Constants.EntityType.FILTER
                        # Block if the color of the laser is not equal to that of the filter
                        if entity.color isnt laserSegment.laser.color
                            chopAllAfterCurrent()
                            laser.segments.push(toEntity)

                    else
                        # Do nothing
                        null
            i += 1
    isBetween: (segment, entity) ->
        startPos = segment.start.position
        endPos = segment.end.position

        if startPos[0] is endPos[0]
            entity in (@board.grid[startPos[0]][startPos[1]+1..endPos[1]-1])
        else if startPos[1] is endPos[1]
            entity in ((@board.grid[startPos[1]][k] for k in [0...@board.size])[startPos[0]+1..endPos[0]-1])

    getEntityAt: (x, y) ->
        result = @board.getAt(x, y)

    addLaser: (laser) ->
        @board.lasers.push(laser)

    flushChanged: () ->
        @changed = []

    addToChanged: (x, y) ->
        if not [x, y] in @changed
            @changed.push([x, y])

    removeEntityAt: (x, y) ->
        occupant = @board.getAt(x, y)
        if occupant
            @decrementEntityType(occupant.type)

        @board.setAt(x, y, false)
    
    incrementEntityType: (type) ->
        @numEntitiesByType[type] += 1

    decrementEntityType: (type) ->
        @numEntitiesByType[type] -= 1
    
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
        
        results = (@validateLaser(laser) for laser in @board.lasers)

        # For now, just take the win condition to be 'all lasers reaching an end state through valid moves'
        finalResult = true
        (finalResult &= result for result in results)
        return !!(finalResult)
    
    validateSegment: (segment) ->
        console.log @board
        if(segment.start.position[0] is segment.end.position[0])
            # Check if any of the entities between the start / end on this row are blockers.
            colBetween = @board.grid[segment.start.position[0]][segment.start.position[1]+1..segment.end.position[1]-1]
            
            blockers = (elem for elem in colBetween when elem and not elem.accepts(segment.laser))

            return not blockers.length

        else if(segment.start.position[1] is segment.end.position[1])
            # Check if any of the entities between the start / end on this column are blockers
            row = (@board.grid[segment.start.position[1]][k] for k in [0...@board.size])
            row = row[segment.start.position[0]+1..segment.end.position[0]-1]
            
            blockers = (elem for elem in row when elem and not elem.accepts(segment.laser))
            
            return not blockers.length

    validateLaser: (laser) ->
        results = (@validateSegment(seg) for seg in laser.segments)
        ret = true
        (ret &= result for result in results)
        return !!ret and
               laser.segments[laser.segments.length-1].end.type is Constants.EntityType.END and
               laser.segments[0].start.type is Constants.EntityType.START
"""[
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
                                    if dir%2 == 0 then turnRight() else turnLeft()
                                when Constants.EntityOrient.NE, Constants.EntityOrient.SW
                                    if dir%2 == 0 then turnLeft() else turnRight()

                    prevPos = currentPos
                    move()
"""

class Board
    constructor: (@size) ->
        @grid = ((false for x in [0...@size]) for y in [0...@size])
        @lasers = []

    add: (entity) ->
        if entity.position[0] < @size and entity.position[1] < @size
            @grid[entity.position[1]][entity.position[0]] = entity
            true

    setAt: (x, y, obj) ->
        if x < @size and y < @size 
            @grid[y][x] = obj
            true

    getAt: (x, y) ->
        return @grid[y][x]
        
class Puzzle
    constructor: () ->

    getMaxForType: (entityType) ->
        return 100000

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
    accepts: (laser) -> true


class Endpoint extends GridEntity
    constructor: (@position) ->
        @type = Constants.EntityType.END
        super(@position, 1, false)
    
    accepts: (laser) -> true

class Startpoint extends GridEntity
    constructor: (@position) ->
        @type = Constants.EntityType.START
        super(@position, 1, false)
    
    accepts: (laser) -> true
    

class Mirror extends GridEntity
    constructor: (@position, @orientation, @mobility) ->
        @type = Constants.EntityType.MIRROR
        super(@position, @orientation, @mobility)

    accepts: (laser) -> false

class Block extends GridEntity
    constructor: (@position) ->
        @type = Constants.EntityType.BLOCK
        super(@position, 1, false)

    accepts: (laser) -> false
        
class Filter extends GridEntity
    constructor: (@position, @orientation, @mobility, @color) ->
        @type = Constants.EntityType.FILTER
        super(@position, @orientation, @mobility)

    accepts: (laser) -> laser.color == @color

class Prism extends GridEntity
    constructor: (@position, @orientation, @mobility) ->
        @type = Constants.EntityType.PRISM
        super(@position, @orientation, @mobility)

    accepts: (laser) -> false
 
class Laser
    constructor: (@color, @startpoint) ->
        @chain = []
        @segments = []

    extend: (entity) ->
        if entity.accepts(this) or entity.type is Constants.EntityType.MIRROR
            segment = new LaserSegment(@segments[@segments.length - 1]?.start or @startpoint, entity, this)
            
            
            
            @segments.push(segment)
            @chain.push(entity)
        return this

    truncate: () ->
        @chain.pop()
        @segments.pop()

class LaserSegment
    constructor: (@start, @end, @laser, @direction) ->
        if @start.type is Constants.EntityType.START
            @direction = @start.direction

