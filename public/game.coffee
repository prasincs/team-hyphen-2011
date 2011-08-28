if require?
  Constants = require('./common').Constants

class GameManager
    constructor: (@id, @puzzle, @gridX, @gridY) ->
        @board = new Board(10)
        @changed = []
        @numEntitiesByType = {}
        
        (@numEntitiesByType[k] = 0) for _, k of Constants.EntityType

    remainingEntities: (entityType) ->
        @puzzle.getMaxForType(entityType) - @numEntitiesByType[entityType]

    deserializePuzzle: () ->
        """
            [
                'STRANG',
                [ RED EDGES
                    [start x, start y],
                    [end x, end y]
                ],
                [ BLUE EDGES
                    [start x, start y],
                    [end x, end y]
                ]
            ]
        """

        """
            / -> Mirror NW
            \\ -> Mirror SW
            r -> Red Filter NW
            R -> Red Filter NE
            g -> Green Filter NW
            G -> Green Filter NE
            ^ -> Block
            . -> Empty
        """
        translationTable =
            '/'  : (position) -> return new Mirror(position, Constants.EntityOrient.NW, true)
            '\\' : (position) -> return new Mirror(position, Constants.EntityOrient.SW, true)
            'r'  : (position) -> return new Filter(position, Constants.EntityOrient.NW, Constants.Red, true)
            'R'  : (position) -> return new Filter(position, Constants.EntityOrient.NE, Constants.Red, true)
            'g'  : (position) -> return new Filter(position, Constants.EntityOrient.NW, Constants.Green, true)
            'G'  : (position) -> return new Filter(position, Constants.EntityOrient.NE, Constants.Green, true)
            'b'  : (position) -> return new Block(position)
            '.'  : (position) -> return false

        inferDirection = ([x,y]) ->
            # Given position, infer the laser direction
            top = (0 <= x < 10) and y < 0
            bottom = (0 <= x < 10) and y >= 10

            left = x < 0 and (0 <= y < 10)
            right = x >= 10 and (0 <= y < 10)

            if top
                Constants.LaserDirection.S
            else if bottom
                Constants.LaserDirection.N
            else if left
                Constants.LaserDirection.E
            else if right
                Constants.LaserDirection.W

        inferAcceptDirection = ([x, y]) ->
            # Given position, infer the laser accept direction by just flipping
            # the result of what the emit direction would be.
            (inferDirection([x,y]) + 2) % 4

        entities  = @puzzle.data[0]

        [redStart, redEnd]  = @puzzle.data[1]

        if @puzzle.data.length is 3
            [blueStart, blueEnd] = @puzzle.data[2]
       
        for i in [0...entities.length]
            c = entities[i]
            row = Math.floor(i / 10)
            col = i % 10
            @addEntity(translationTable[c]([row, col]))
        
        if redStart
            redStartEntity = new Startpoint(redStart, inferDirection(redStart), Constants.Red)
            @addEntity(redStartEntity)
            @addLaser(new Laser(Constants.Red, redStartEntity))
        if redEnd
            @addEntity(new Endpoint(redEnd, inferAcceptDirection(redEnd), Constants.Red))
        if blueStart
            blueStartEntity = new Startpoint(blueStart, inferDirection(blueStart), Constants.Blue)
            @addEntity(blueStartEntity)
            @addLaser(new Laser(Constants.Blue, blueStartEntity))
        if blueEnd
            @addEntity(new Endpoint(blueEnd, inferAcceptDirection(blueEnd), Constants.Blue))


    addEntity: (entity) ->
        if entity is false
            @board.setAt(entity)
        else
            succeeded = false
            if entity.type is Constants.EntityType.START
                @board.startpoints.push(entity)
                succeeded = true
            else if entity.type is Constants.EntityType.END
                @board.endPoints.push(entity)
                succeeded = true
            else if !@getEntityAt(entity.position[0], entity.position[1])
                if @numEntitiesByType[entity.type] < @puzzle.getMaxForType(entity.type)
                       succeeded = @board.add(entity)
                       @addToChanged(entity.position)

            @traceAllLasers()
            
            if succeeded
                @incrementEntityType(entity.type) unless entity.static

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
            currDir = (((laser.segments[laser.segments.length-2].direction-1)%4) + 4) % 4

        else
            startPoint = laser.startpoint
            currDir = startPoint.direction

        dy = 0
        dx = 0
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
        mapDir(currDir)
        x = startPoint.position[0] + dx
        y = startPoint.position[1] + dy
        branches = []
        
        unless laser.segments.length
            firstSeg = new LaserSegment(laser.startpoint, null, laser, currDir)
            laser.segments.push(firstSeg)


        blocked = false
        while( not blocked and x >= 0 and y >= 0 and x < @board.size and y < @board.size)
            mapDir(currDir)
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
                        blocked = true
                        break
                    when Constants.EntityType.FILTER
                        if current.color is laser.color
                            seg = new LaserSegment(current, null, laser, currDir)
                            currDir = current.bounceDirection(currDir)
                            seg.direction = currDir
                            laser.segments.push(seg)
                        else
                            seg = new LaserSegment( current, null, laser, currDir)
                            seg.direction = currDir
                            laser.segments.push(seg)
                    when Constants.EntityType.PRISM
                        # ugh
                        directions = current.splitDirection(currDir)
                        currDir = directions.right

                        branched = new Laser(laser.color, laser.startpoint)
                        branched.segments = laser.segments.slice(0)
                        branched.chain = laser.chain.slice(0)
                        branched.segments.push(new LaserSegment(current, null, laser, directions.left))

                        # Store the temporary laser and the grid coord at which the split happened
                        # so we can merge.
                        branches.push([branched, [x, y]])

                        # Continue tracing the laser that took the left fork
                        @traceLaser(branched)
                        
                        # Continue tracing the laser that took the right fork 
                        seg = new LaserSegment(current, null, laser, currDir)
                        laser.segments.push(seg)

                        break
            mapDir(currDir)
            x += dx
            y += dy

            # Special check for endpoints
            endpoint = (e for e in this.board.endPoints when x is e.position[0] and y is e.position[1])
            if endpoint.length
                previous = laser.segments[laser.segments.length-1]
                previous.end = endpoint[0]
            
        if branches.length
            laser.merge(branches)

    removeEntity: (entity) ->
        removeEntityAt(entity.position[0], entity.position[1])

    getEntityAt: (x, y) ->
        @board.getAt(x, y)

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
            unless occupant.static
                @decrementEntityType(occupant.type)
                @board.setAt(x, y, false)
                @traceAllLasers()
    
    incrementEntityType: (type) ->
        @numEntitiesByType[type] += 1

    decrementEntityType: (type) ->
        @numEntitiesByType[type] -= 1
    
    rotateEntityClockwise: (x, y) ->
        entity = @getEntityAt(x, y)
        if entity
            unless entity.static
                entity.rotateClockwise()
                @traceAllLasers()
                @addToChanged(x, y)
    
    rotateEntityCounterClockwise: (x, y) ->
        entity = @getEntityAt(x, y)
        if entity
            unless entity.static
                entity.rotateCounterClockwise()
                @traceAllLasers()
                @addToChanged(x, y)

    isSolved: (x, y) ->
        # Basic idea is to walk each laser and make sure the path has the following properties
        #   - Starts at a valid start point
        #   - Ends at a valid end point
        #   - Every entity in between accepts it.
        
        results = (@validateLaser(laser) for laser in @board.lasers)

        finalResult = true
        (finalResult &= e.satisfied for e in @board.endPoints)

        return !!(finalResult)
    
    validateSegment: (segment) ->
        unless segment.end
            return true

        if(segment.start.position[0] is segment.end.position[0])
            # Check if any of the entities between the start / end on this row are blockers.
            colBetween = @board.grid[segment.start.position[0]][Math.max(segment.start.position[1]+1, 9)..Math.min(segment.end.position[1]-1, 0)]
            
            blockers = (elem for elem in colBetween when elem and not elem.accepts(segment.laser))

            return not blockers.length

        else if(segment.start.position[1] is segment.end.position[1])
            # Check if any of the entities between the start / end on this column are blockers
            row = (@board.grid[segment.start.position[1]][k] for k in [0...@board.size])
            row = row[Math.max(segment.start.position[0]+1, 9)..Math.min(segment.end.position[0]-1, 0)]
            
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

        @startpoints = []
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
    constructor: (maxEntitiesNum = 1000, @data) ->
        # Actual values to be filled in once we get settled on a representation
        @maxEntitiesByType = {}
        (@maxEntitiesByType[k] = maxEntitiesNum) for _, k of Constants.EntityType

    getMaxForType: (entityType) ->
        @maxEntitiesByType[entityType]

class GridEntity
    constructor: (@position, @orientation, @static) ->
      @type ||= 0
    
    rotateTo: (orientation) ->
        @orientation = orientation

    rotateClockwise: () ->
        @orientation = (@orientation + 1) % 4

    rotateCounterClockwise: () ->
        @orientation = (((@orientation - 1)%4) + 4) % 4

    # Does this entity accept this laser?
    # Acceptance means it doesn't straight up block it
    accepts: (laser) -> true


class Endpoint extends GridEntity
    constructor: (@position, @acceptDirection, @color) ->
        @type = Constants.EntityType.END
        super(@position, 1, true)
    
    accepts: (laser) -> true

class Startpoint extends GridEntity
    constructor: (@position, @direction, @color) ->
        @type = Constants.EntityType.START
        super(@position, 1, true)
    
    accepts: (laser) -> true
    

class Mirror extends GridEntity
    constructor: (@position, @orientation, @static) ->
        @type = Constants.EntityType.MIRROR
        super(@position, @orientation, @static)

    accepts: (laser) -> false
    bounceDirection: (direction) ->
        # Tried to make this an expression, but I kept getting syntax errors
        if @orientation is Constants.EntityOrient.NW or @orientation is Constants.EntityOrient.SE
            if direction is Constants.LaserDirection.N or direction is Constants.LaserDirection.S
               result = (direction + 1) % 4
               
            else
               result = (((direction - 1)%4) + 4) % 4
        else if @orientation is Constants.EntityOrient.SW or @orientation is Constants.EntityOrient.NE
            if direction is Constants.LaserDirection.N or direction is Constants.LaserDirection.S
                result = (((direction - 1)%4) + 4) % 4
            else
                result = (direction + 1) % 4
        return result

class Block extends GridEntity
    constructor: (@position) ->
        @type = Constants.EntityType.BLOCK
        super(@position, 1, true)

    accepts: (laser) -> false
        
class Filter extends GridEntity
    constructor: (@position, @orientation, @color, @static) ->
        @type = Constants.EntityType.FILTER
        super(@position, @orientation, @static)

    accepts: (laser) -> laser.color == @color
    bounceDirection: (direction) ->
        # Tried to make this an expression, but I kept getting syntax errors
        if @orientation is Constants.EntityOrient.NW or @orientation is Constants.EntityOrient.SE
            if direction is Constants.LaserDirection.N or direction is Constants.LaserDirection.S
               result = (direction + 1) % 4
               
            else
               result = (((direction - 1)%4) + 4) % 4
        else if @orientation is Constants.EntityOrient.SW or @orientation is Constants.EntityOrient.NE
            if direction is Constants.LaserDirection.N or direction is Constants.LaserDirection.S
                result = (((direction - 1)%4) + 4) % 4
            else
                result = (direction + 1) % 4
        return result

class Prism extends GridEntity
    constructor: (@position, @orientation, @static) ->
        @type = Constants.EntityType.PRISM
        super(@position, @orientation, @static)
    
    splitDirection: (direction) ->
        result =
            left: (((direction - 1)%4) + 4) % 4
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
        @mergeSingle(packet[0], packet[1]) for packet in laserPackets

    mergeSingle: (laser, split) ->
        
        # Find the point at which this laser deviates and grab every segment after that 
        toMerge = ((laser.segments[laser.segments.indexOf(k)..laser.segments.length])[0] for k in laser.segments when k.start.position[0] is split[0] and k.start.position[1] is split[1])
        (@segments.push(seg) for seg in toMerge)

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
