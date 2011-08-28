Assert = {}
Assert.error = (msg) ->
    console.trace()
    throw ("ASSERT FAILED: " + msg)
Assert.equals = (a,b,msg) -> Assert.error(msg) unless a is b
Assert.false  = (expr,msg) -> Assert.equals(expr,false,msg)
Assert.true   = (expr,msg) -> Assert.equals(expr,true, msg)
Assert.exists = (expr,msg) -> Assert.true(expr?,msg)

Util = {}
Util.dedup = (arr) ->
    obj = {}
    obj[x.toString(10)] = true for x in arr
    k for k,v of obj

Rand = {}
    # random int from 0 to range (inclusive)
Rand.int = (range) -> Math.floor(Math.random()*(range+1))
    # generates a random int from 0 to range that's not in excluded
Rand.intExclude = (range,excluded) ->
    excluded = Util.dedup(excluded)
    # -1 shouldn't be included here
    excluded = x for x in excluded if x >= 0
    Assert.false(range <= excluded.length,"all possible values in range are excluded")
    result = Rand.int(range - excluded.length)
    for i in excluded
        if result >= i then result += 1
    Assert.true(result >= 0 and result <= range,"result is outside bounds: " + result)
    result
Rand.uniqueInts = (range,count,excluded=[]) ->
    Assert.exists(excluded,"excluded must be an array")
    ints = []
    for i in [0...count]
        int = Rand.intExclude(excluded.concat(ints))
        ints.push(int)
    ints

class Pt1
    constructor: (@x,@y,@dir,edge=false,size=10) ->
        bounds = if edge then [-1,size] else [0,size-1]
        Assert.true(@x >= bounds[0],"bad grid coordinates (#{@x} < #{bounds[0]})")
        Assert.true(@y >= bounds[0],"bad grid coordinates (#{@y} < #{bounds[0]})")
        Assert.true(@x <= bounds[1],"bad grid coordinates (#{@x} > #{bounds[1]})")
        Assert.true(@y <= bounds[1],"bad grid coordinates (#{@y} > #{bounds[1]})")
    check: (other) ->
        switch @dir
            when 'h' then other.y is @y
            when 'v' then other.x is @x

class BlockObj
    constructor: (@x,@y) -> @type = 'block'
    toString: -> '#'

class MirrorObj
    constructor: (@x,@y,@direction) -> @type = 'mirror'
    toString: ->
        switch @orientation
            when 'nw','se' then '/'
            when 'ne','sw' then '\\'
            else Assert.error("impossible case")
    setOrientation: (prev,next) ->
        if @direction is 'h' then [prev,next] = [next,prev]
        [isLeft,isUp] = [prev.x < @x, next.y < @y]
        [isRight,isDown] = [not isLeft, not isUp]
        # nw:   ne:   sw:  se:
        #   n   n     p \  / p
        # p /   \ p     n  n
        if      isLeft  and isUp   then @orientation = 'nw'
        else if isRight and isUp   then @orientation = 'ne'
        else if isLeft  and isDown then @orientation = 'sw'
        else if isRight and isDown then @orientation = 'se'
        else Assert.error("impossible case (setOrientation)")
    makeFilter: (color) ->
        new FilterObj(color,@x,@y,@direction,@orientation)

class FilterObj extends MirrorObj
    constructor: (@color,@x,@y,@direction,@orientation) -> @type = 'filter'
    toString: -> 'f'

class Prism
    constructor: (@x,@y) -> @type = 'prism'
    toString: ->
        switch @orientation
            when 'n' then '⊥'
            when 'e' then '>'
            when 's' then 'T'
            when 'w' then '<'
            else Assert.error("invalid orientation #{@orientation}")
    setOrientation: (prev) ->
        switch prev.dir
            when 'h' then (if prev.x < @x then 'w' else 'e')
            when 'v' then (if prev.y < @y then 'n' else 's')
    
class Color
    constructor: (@color,@parent,endCount=1) ->
        @pickStartpoint()
        @solutionPoints = []
        @excludedEnds = []
        @usedPoints = []
        @mirrors = []
        @addEndpoint() for i in [0...endCount]
    pickStartpoint: -> @start = @pickEdgepoint()
    addEndpoint: ->
        Assert.exists(@start,'@start must be set before adding end points')
        @ends ?= []
        combined = @ends.concat([@start])
        end = @pickEdgepoint(combined)
        switch end.dir
            when 'v'
                newExcl = ([end.x,y] for y in [0...@parent.size])
                @excludedEnds = @excludedEnds.concat(newExcl)
            when 'h'
                newExcl = ([x,end.y] for x in [0...@parent.size])
                @excludedEnds = @excludedEnds.concat(newExcl)
        @ends.push(end)
    pickEdgepoint: (excluded=[]) ->
        done = false
        until done
            dir = ['h','v'][Rand.int(1)]
            coord1 = [-1,@parent.size][Rand.int(1)]
            coord2 = Rand.int(@parent.size-1)
            pt = switch dir
                when 'h' then new Pt1(coord1,coord2,dir,edge=true)
                when 'v' then new Pt1(coord2,coord1,dir,edge=true)
                else Assert.error("dir should be one of 'h' or 'v' (pickEdgepoint)")
            if (ex for ex in excluded when pt.check(ex)).length is 0 then done = true
        pt
    # gets a list of points in a line from start to end (inclusive of end points)
    getLine: (start,end) ->
        switch start.dir
            when 'h'
                Assert.true(start.y is end.y, "direction is h, y values should match")
                ([x,start.y] for x in [start.x..end.x])
            when 'v'
                Assert.true(start.x is end.x, "direction is v, x values should match")
                ([start.x,y] for y in [start.y..end.y])
            else Assert.error("dir must be one of 'h' or 'v'")
    # does the work of creating the 'board'
    make: (count,prevUsed=[],prevEdges=[]) ->
        # TODO: remove this assert
        Assert.true(@ends.length is 1,"only 1 endpoint supported (for now)")
        @usedPoints = @usedPoints.concat(prevUsed)
        @excludedEnds = @excludedEnds.concat(prevEdges)
        @makePath(count,@start)
        @makeMirrors()
        # TODO: finish up actual solution generation here
    # makes actual mirror objects from the solution points
    makeMirrors: ->
        pts = (x for x in @solutionPoints)
        pts.unshift(@start)
        # TODO: make this work with multiple ends
        pts.push(@ends[0])
        prev = @start
        for m,i in pts[1...(pts.length-1)]
            [prev,next] = [pts[i],pts[i+2]]
            mirror = new MirrorObj(m.x,m.y,m.dir)
            mirror.setOrientation(prev,next)
            @mirrors.push(mirror)
    makeFilters: ->
        inList = (obj,list) ->
            Assert.exists(list,'list is undefined')
            Assert.exists(list[0],'list is empty')
            Assert.exists(list[0][0],'incorrect points list format')
            Assert.exists(obj[0],'obj is of incorrect format')
            for elem in list
                if elem[0] is obj[0] and elem[1] is obj[1] then return true
            false
        if @color is 'green'
            used = @parent.red.usedPoints
        else
            used = [pt for pt in @parent.green.usedPoints when not inList(pt,@usedPoints)]
        Assert.true(used.length > 0,'no used points...that seems dubious')
        for mirror,i in @mirrors
            if inList([mirror.x,mirror.y],used)
                filter = mirror.makeFilter(@color)
                @mirrors[i] = filter
    pickPenultimate: (prev,end) ->
        # then we need to add another point first
        if prev.dir is end.dir then prev = @pickPoint(prev)
        pt = switch prev.dir
            when 'h' then new Pt1(end.x,prev.y,'v')
            when 'v' then new Pt1(prev.x,end.y,'h')
            else Assert.error("dir must be one of 'h' or 'v'")
        @usedPoints = @usedPoints.concat(@getLine(prev,pt)).concat(@getLine(pt,end))
        @solutionPoints.push(pt)
        pt
    pickPoint: (prev) ->
        used = @usedPoints.concat(@excludedEnds)
        pt = switch prev.dir
            when 'h'
                excluded = (pt[0] for pt in used when pt[1] is prev.y)
                newX = Rand.intExclude(@parent.size-1,excluded)
                new Pt1(newX,prev.y,'v')
            when 'v'
                excluded = (pt[1] for pt in used when pt[0] is prev.x)
                newY = Rand.intExclude(@parent.size-1,excluded)
                new Pt1(prev.x,newY,'h')
            else Assert.error("dir must be one of 'h' or 'v'")
        Assert.true(prev.x isnt pt.x or prev.y isnt pt.y,
                    "points may not overlap (#{pt.x},#{pt.y})")
        @usedPoints = @usedPoints.concat(@getLine(prev,pt))
        @solutionPoints.push(pt)
        pt
    makePath: (count,prev) ->
        if count is 1
            # TODO: make this work with multiple endings
            @pickPenultimate(prev,@ends[0])
        else
            point = @pickPoint(prev)
            @makePath(count-1,prev=point)

class PuzzleObj
    constructor: (@count=4,@size=10,@start=false,@end=false,@difficulty='easy') ->
        @red   = new Color('red'  ,this)
        @red.make(@count)
        @green = new Color('green',this)
        @green.make(@count,@red.usedPoints,@red.excludedEnds)
        @green.makeFilters()
        @red.makeFilters()
        @makeStatic()

    randomPoint: -> [Rand.int(@size-1),Rand.int(@size-1)]
    randomUnblockedPoints: (count) ->
        # TODO: make this support multiple colors
        blocked = ((false for i in [0...@size]) for j in [0...@size])
        for [x,y] in @green.usedPoints.concat(@red.usedPoints)
            blocked[x][y] = true if -1 < x < @size and -1 < y < @size
        points = []
        while points.length < count
            point = [x,y] = @randomPoint()
            if not blocked[x][y]
                points.push(point)
                blocked[x][y] = true
        points
    makeStatic: (count=30) ->
        @static = []
        points = @randomUnblockedPoints(count)
        for [x,y] in points
            if Rand.int(2) is 0
                mirror = new MirrorObj(x,y)
                mirror.orientation = ['ne','nw','sw','se'][Rand.int(3)]
                @static.push(mirror)
            else
                @static.push(new BlockObj(x,y))
        for mirror in @red.mirrors.concat(@green.mirrors)
            if Rand.int(3) is 0 then @static.push(mirror)
                

    # maybe TODO: print out things that aren't from the red part
    printAscii: ->
        board = (('.' for i in [0...(@size+2)]) for j in [0...(@size+2)])
        #for [x,y] in @green.usedPoints
        #    board[x+1][y+1] = '$'
        #for [x,y] in @red.usedPoints
        #    board[x+1][y+1] = '!'
        #for mirror in @red.mirrors
        #    board[mirror.x+1][mirror.y+1] = switch mirror.orientation
        #        when 'nw','se' then '/'
        #        when 'ne','sw' then '\\'
        #        else Assert.error("orientation must be one of ne,sw,nw,se (is #{mirror.orientation})")
        #for mirror in @green.mirrors
        #    board[mirror.x+1][mirror.y+1] = switch mirror.orientation
        #        when 'nw','se' then '/'
        #        when 'ne','sw' then '\\'
        #        else Assert.error("orientation must be one of ne,sw,nw,se (is #{mirror.orientation})")
        for static in @static
            space = board[static.x+1][static.y+1]
            if space isnt '.' then Assert.error("static elements shouldn't cover things (#{space}, #{static.x},#{static.y}) up!")
            board[static.x+1][static.y+1] = static.toString()
        board[@red.start.x+1][@red.start.y+1] = 's'
        board[@red.ends[0].x+1][@red.ends[0].y+1] = 'e'
        board[@green.start.x+1][@green.start.y+1] = '1'
        board[@green.ends[0].x+1][@green.ends[0].y+1] = '2'
        for line in board
            console.log(line.join(' '))

translationTable = {
    '/':[MirrorObj,'nw'],
    '\\':[MirrorObj,'ne'],
    'r':[FilterObj,'red','nw'],
    'R':[FilterObj,'red','ne'],
    'g':[FilterObj,'green','nw'],
    'G':[FilterObj,'green','ne'],
    '^':[BlockObj,'b'],
    '.':[''],
    }

    #[ 100 char string, [[x,y],[x,y]], [[x,y],[x,y]] ]

getPuzzleSafe = ->
    unsafe = true
    while unsafe
        try
            p = new PuzzleObj()
            unsafe = false
        catch e
            unsafe = true
    p

serialize = (puzzle=false) ->
    puzzle ||= getPuzzleSafe()
        
    elems = ('.' for i in [0...puzzle.size*puzzle.size])
    for obj in puzzle.static
        val = switch obj.type
            when 'mirror'
                switch obj.orientation
                    when 'nw','se' then '/'
                    when 'ne','sw' then '\\'
            when 'block' then 'b'
            when 'filter'
                switch obj.color
                    when 'green'
                        switch obj.orientation
                            when 'nw','se' then 'g'
                            when 'ne','sw' then 'G'
                    when 'red'
                        switch obj.orientation
                            when 'nw','se' then 'r'
                            when 'ne','sw' then 'R'
        pos = obj.x + obj.y*10
        elems[pos] = val
    redEdge = [[puzzle.red.start.x,puzzle.red.start.y],
               [puzzle.red.ends[0].x,puzzle.red.ends[0].y]]
    greenEdge = [[puzzle.green.start.x,puzzle.green.start.y],
                 [puzzle.green.ends[0].x,puzzle.green.ends[0].y]]
    [elems,redEdge,greenEdge]

exports ?= {}
exports.serialize = serialize

