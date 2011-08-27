if require?
  Constants = require('./common').Constants

class GameManager
    constructor: (@puzzle, @gridX, @gridY) ->
        @board = new Board(10)
        @changed = []
        @numEntitiesByType = {}
        
        (@numEntitiesByType[k] = 0) for _, k of Constants.EntityType

    remainingEntities: (entityType) ->
        @puzzle.getMaxForType(entityType) - @numEntitiesByType[entityType]

    addEntity: (entity) ->
        succeeded = false
        if entity.type is Constants.EntityType.START
            @board.startpoint = entity
            succeeded = true
        else if entity.type is Constants.EntityType.END
            @board.endPoints.push(entity)
            succeeded = true
        else if !@getEntityAt(entity.position[0], entity.position[1])
            if @numEntitiesByType[entity.type] < @puzzle.getMaxForType(entity.type)
                   succeeded = @board.add(entity)
                   @incrementEntityType(entity.type)
                   @addToChanged(entity.position)

        @traceAllLasers()
        return succeeded
    
    reset: () ->
        e.satisfied = false for e in @board.endPoints
        laser.segments = [] for laser in @board.lasers

    traceAllLasers: () ->
        @reset()
        # Traces the SHIT out of every laser on the board, super hard.
        @traceLaser(laser) for laser in @board.lasers
    
    traceLaser: (laser) ->
        # Trace one laser 1 / num_lasers as HARD AS IT CAN
        
        if laser.segments.length 
            startPoint = laser.segments[laser.segments.length-1].start
        else
            startPoint = laser.startpoint

        dy = 0
        dx = 0
        x = startPoint.position[0]
        y = startPoint.position[1]
        currDir = startPoint.direction
        branches = []
        
        unless laser.segments.length
            firstSeg = new LaserSegment(laser.startpoint, null, laser, currDir)
            laser.segments.push(firstSeg)


        mapDir = (dir) ->
            dirs = Constants.LaserDirection
            switch dir
                when dirs.N
                    dy = -1
                    dx = 0
                when dirs.S
                    dy = 1
                    dx = 0
                when dirs.W
                    dy = 0
                    dx = -1
                when dirs.E
                    dy = 0
                    dx = 1
 
        while(x >= 0 and y >= 0 and x < @board.size-1 and y < @board.size-1)
            mapDir(currDir)
            x += dx
            y += dy
            current = @board.getAt(x, y)
            unless current
                current = @board.getEndPoint(x, y)
            unless not current

                # Connect the end of the last laser to the thing.
                previous = laser.segments[laser.segments.length - 1]
                previous.end = current

                switch current.type
                    when Constants.EntityType.MIRROR
                        # Change direction
                        seg = new LaserSegment( current, null, laser, currDir)
                        currDir = current.bounceDirection(currDir)
                        seg.direction = currDir
                        laser.segments.push(seg)
                        break

                    when Constants.EntityType.BLOCK
                        # Do nothing because ITS A FUCKING BLOCK
                        break
                    when Constants.EntityType.FILTER
                        if current.color isnt laser.color
                            break
                        else
                            seg = new LaserSegment( current, null, laser, currDir)
                            seg.direction = currDir
                            laser.segments.push(seg)
                    when Constants.EntityType.PRISM
                        # ugh
                        directions = current.splitDirection(currDir)
                        currDir = directions[1]

                        branched = new Laser(laser.color, laser.startpoint)
                        branched.segments = laser.segments.slice(0)
                        branched.chain = laser.chain.slice(0)
                        branched.segments.push(new LaserSegment(current, null, laser, directions[0]))

                        # Store the temporary laser and the grid coord at which the split happened
                        # so we can merge.
                        branches.push([branched, [x, y]])

                        # Continue tracing the laser that took the left fork
                        @traceLaser(branched)
                        
                        # Continue tracing the laser that took the right fork 
                        seg = new LaserSegment(current, null, laser, currDir)
                        laser.segments.push(seg)

                        break
        if branches.length
            laser.merge(branches)

    removeEntity: (entity) ->
        removeEntityAt(entity.position[0], entity.position[1])

    getEntityAt: (x, y) ->
        result = @board.getAt(x, y)

    addLaser: (laser) ->
        @board.lasers.push(laser)
        @traceAllLasers()

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
        @traceAllLasers()
    
    incrementEntityType: (type) ->
        @numEntitiesByType[type] += 1

    decrementEntityType: (type) ->
        @numEntitiesByType[type] -= 1
    
    rotateEntityClockwise: (x, y) ->
        @getEntityAt(x, y).rotateClockwise()
        @traceAllLasers()
        @addToChanged(x, y)

    rotateEntityCounterClockwise: (x, y) ->
        @getEntityAt(x, y).rotateCounterClockwise()
        @traceAllLasers()
        @addToChanged(x, y)

    isSolved: (x, y) ->
        # Basic idea is to walk each laser and make sure the path has the following properties
        #   - Starts at a valid start point
        #   - Ends at a valid end point
        #   - Every entity in between accepts it.
        
        results = (@validateLaser(laser) for laser in @board.lasers)

        # For now, just take the win condition to be 'all lasers reaching an end state through valid moves'
        finalResult = true
        (finalResult &= e.satisfied for e in @board.endPoints)

        return !!(finalResult)
    
    validateSegment: (segment) ->
        unless segment.end
            return false

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

        hitsEnd = (seg.end for seg in laser.segments when seg.end and seg.end.type is Constants.EntityType.END)
        if not hitsEnd.length
           return false
        else 

            # Flag the end point as satisfied if this laser is valid and the last entity on the laser
            # is an end point.
            if hitsEnd.length and ret
                e.satisfied = true for e in hitsEnd
            return !!ret

class Board
    constructor: (@size) ->
        @grid = ((false for x in [0...@size]) for y in [0...@size])

        @endPoints = []
        @lasers = []

    add: (entity) ->
        if @inBounds(entity.position[0], entity.position[1])
            @grid[entity.position[1]][entity.position[0]] = entity
            return true

    inBounds: (x, y) ->
        return (x < @size and y < @size and x >= 0 and y >= 0)

    setAt: (x, y, obj) ->
        if @inBounds(x, y)
            @grid[y][x] = obj
            return true

    getAt: (x, y) ->
        if @inBounds(x, y)
            return @grid[y][x]

    getEndPoint: (x, y) ->
        result = (e for e in @endPoints when x is e.position[0] and y is e.position[1])
        unless result.length
            return false
        return result[0]
        
class Puzzle
    constructor: (maxEntitiesNum = 1000) ->
        # Actual values to be filled in once we get settled on a representation
        @maxEntitiesByType = {}
        (@maxEntitiesByType[k] = maxEntitiesNum) for _, k of Constants.EntityType

    getMaxForType: (entityType) ->
        @maxEntitiesByType[entityType]

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
    constructor: (@position, @direction) ->
        @type = Constants.EntityType.START
        super(@position, 1, false)
    
    accepts: (laser) -> true
    

class Mirror extends GridEntity
    constructor: (@position, @orientation, @mobility) ->
        @type = Constants.EntityType.MIRROR
        super(@position, @orientation, @mobility)

    accepts: (laser) -> false
    bounceDirection: (direction) ->
        # Tried to make this an expression, but I kept getting syntax errors
        if @orientation is Constants.EntityOrient.NW or @orientation is Constants.EntityOrient.SE
            if direction is Constants.LaserDirection.N or direction is Constants.LaserDirection.S
               result = (direction + 1) % 4
            else
               result = (direction - 1) % 4
        else if @orientation is Constants.EntityOrient.SW or @orientation is Constants.EntityOrient.NE
            if direction is Constants.LaserDirection.N or direction is Constants.LaserDirection.S
                result = (direction - 1) % 4
            else
                result = (direction + 1) % 4
        return result

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
    
    splitDirection: (direction) ->
        result =
            left: (direction - 1) % 4
            right: (direction + 1) % 4
        return result

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

    merge: (laserPackets) ->

        # Merge each laser packet (laser itself and its divergence point)
        mergeSingle(packet[0], packet[1]) for packet in laserPackets

    mergeSingle: (laser, split) ->
        
        # Find the point at which this laser deviates and grab every segment after that 
        toMerge = (laser.segments[laser.segments.indexof(k)-1..laser.segments.length] for k in laser.segments when k.position[0] is split[0] and k.position[1] is split[1])
        @segments.push(toMerge)

class LaserSegment
    constructor: (@start, @end, @laser, @direction) ->
        if @start.type is Constants.EntityType.START
            @direction = @start.direction

exports ?= {}
exports.GameManager = GameManager
exports.LaserSegment = LaserSegment
exports.Board = Board
exports.Puzzle = Puzzle
exports.Laser = Laser
exports.Prism = Prism
exports.Mirror = Mirror
exports.Filter = Filter
exports.GridEntity = GridEntity
