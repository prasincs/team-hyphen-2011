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

class Block
    constructor: (@x,@y) -> @type = 'block'
    toString: -> '#'

class Mirror
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
    
class Color
    constructor: (@color,@parent,endCount=1) ->
        @pickStartpoint()
        @solutionPoints = []
        @excludedEnds = []
        @usedPoints = []
        @mirrors = []
        @addEndpoint() for i in [0...endCount]
    pickStartpoint: => @start = @pickEdgepoint()
    addEndpoint: =>
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
    pickEdgepoint: (excluded=[]) =>
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
    getLine: (start,end) =>
        switch start.dir
            when 'h'
                Assert.true(start.y is end.y, "direction is h, y values should match")
                ([x,start.y] for x in [start.x..end.x])
            when 'v'
                Assert.true(start.x is end.x, "direction is v, x values should match")
                ([start.x,y] for y in [start.y..end.y])
            else Assert.error("dir must be one of 'h' or 'v'")
    # does the work of creating the 'board'
    make: (count,prev=undefined) =>
        # TODO: remove this assert
        Assert.true(@ends.length is 1,"only 1 endpoint supported (for now)")
        prev ?= @start
        @makePath(count,prev)
        @makeMirrors()
        # TODO: finish up actual solution generation here
    # makes actual mirror objects from the solution points
    makeMirrors: =>
        pts = (x for x in @solutionPoints)
        pts.unshift(@start)
        # TODO: make this work with multiple ends
        pts.push(@ends[0])
        prev = @start
        for m,i in pts[1...(pts.length-1)]
            [prev,next] = [pts[i],pts[i+2]]
            mirror = new Mirror(m.x,m.y,m.dir)
            mirror.setOrientation(prev,next)
            @mirrors.push(mirror)
    pickPenultimate: (prev,end) =>
        # then we need to add another point first
        if prev.dir is end.dir then prev = @pickPoint(prev)
        pt = switch prev.dir
            when 'h' then new Pt1(end.x,prev.y,'v')
            when 'v' then new Pt1(prev.x,end.y,'h')
            else Assert.error("dir must be one of 'h' or 'v'")
        @usedPoints = @usedPoints.concat(@getLine(prev,pt)).concat(@getLine(pt,end))
        @solutionPoints.push(pt)
        pt
    pickPoint: (prev) =>
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
    makePath: (count,prev) =>
        if count is 1
            # TODO: make this work with multiple endings
            @pickPenultimate(prev,@ends[0])
        else
            point = @pickPoint(prev)
            @makePath(count-1,prev=point)

class Puzzle
    constructor: (@count=4,@size=10,@start=false,@end=false,@difficulty='easy') ->
        @red   = new Color('red'  ,this)
        #@green = new Color('green',this)
        #@blue  = new Color('blue' ,this)
        @red.make(@count)
        @static = []
        @makeStatic()


    randomPoint: -> [Rand.int(@size-1),Rand.int(@size-1)]
    randomUnblockedPoints: (count) ->
        # TODO: make this support multiple colors
        blockedStrs = ((b+'') for b in @red.usedPoints)
        points = []
        while points.length < count
            point = @randomPoint()
            if (point+'') not in blockedStrs
                points.push(point)
                blockedStrs.push(point+'')
        points
    makeStatic: (count=20) ->
        for [x,y] in @randomUnblockedPoints(count)
            if Rand.int(2) is 0
                mirror = new Mirror(x,y)
                mirror.orientation = ['ne','nw','sw','se'][Rand.int(3)]
                @static.push(mirror)
            else
                @static.push(new Block(x,y))
        for mirror in @red.mirrors
            if Rand.int(3) is 0 then @static.push(mirror)
                

    # maybe TODO: print out things that aren't from the red part
    printAscii: ->
        board = (('.' for i in [0...(@size+2)]) for j in [0...(@size+2)])
        #for [x,y] in @red.usedPoints
        #    board[x+1][y+1] = '!'
        #for mirror in @red.mirrors
        #    board[mirror.x+1][mirror.y+1] = switch mirror.orientation
        #        when 'nw','se' then '/'
        #        when 'ne','sw' then '\\'
        #        else Assert.error("orientation must be one of ne,sw,nw,se (is #{mirror.orientation})")
        for static in @static
            space = board[static.x+1][static.y+1]
            if space isnt '.' then Assert.error("static elements shouldn't cover things (#{space}) up!")
            board[static.x+1][static.y+1] = static.toString()
        s = @red.start
        e = @red.ends[0]
        board[s.x+1][s.y+1] = 's'
        board[e.x+1][e.y+1] = 'e'
        for line in board
            console.log(line.join(' '))

p = new Puzzle()
p.printAscii()



class M
    constructor = (@x,@y,@orientation) -> @type = M

class B
    constructor = (@x,@y) -> @type = B

genBoard = (n=4,size=10,start=false,end=false) ->
    [startSet,endSet] = [not not start,not not end]
    done = false
    until done
        try
            board = [["_" for i in [0...10]] for j in [0...10]]
            start ||= selectEdgePoint(size,exclude=end)
            end ||= selectEdgePoint(size,[start[0],start[1]])
            [points,blocked] = pickPoints(start,end,size,n)
            mirrors = assignDirections(start,end,points)
            done = true
        catch e
            start = false if not startSet
            end = false if not endSet
    blocks = pickRandomPoints(size,blocked,number=30)
    includedMirrorIdxs = uniqueRandInts(rantInt(2))
    includedMirrors = M(x,y,d) for [x,y,d],i in mirrors when i in includedMirrorIdxs
    mirrors = M(x,y,d) for [x,y,d],i in mirrors when i not in includedMirrorIdxs
    newMirrorIdxs = uniqueRandInts(randInt(5))
    permanent = for [x,y],i in blocks
        if i in newMirrorIdxs
            M(x,y,['ne','nw','se','sw'][randInt(3)])
        else
            B(x,y)
    permanent = permanent.concat(includedMirrors)
    [start,mirrors,permanent,end]

class AsciiBoard
    constructor: (size) ->
        @board = (('.' for i in [0...(size+2)]) for j in [0...(size+2)])
    set: (x,y,c) ->
        try
            @board[x+1][y+1] = c
        catch e
            console.log(x + " " + y + " " + c)
            throw e
    addMirror: (x,y,d) ->
        switch d
            when 'ne' then @set(x,y,'\\')
            when 'sw' then @set(x,y,'\\')
            when 'nw' then @set(x,y,'/')
            when 'se' then @set(x,y,'/')
            else throw "direction should be one of ne,nw,se,sw"
    addBlock:  (x,y) -> @set(x,y,'#')
    setStart:  ([x,y,d]) -> @set(x,y,'s')
    setEnd:    ([x,y,d]) -> @set(x,y,'e')
    print: ->
        for i in [0...@board.length]
            console.log(@board[i].join(' '))
    addMirrors: (mirrorList) ->
        for [x,y,d] in mirrorList
            @addMirror(x,y,d)

drawBoard = () ->
    size = 10
    [start,generated,blocked,end] = genBoard(n=4,size=size)
    try
        ab = new AsciiBoard(size)
        for [x,y] in blocked
            ab.addBlock(x,y)
        ab.addMirrors(generated)
        ab.setStart(start)
        ab.setEnd(end)
        ab.print()
    catch e
        console.log(start)
        console.log(end)
        console.log(generated)
        console.log(blocked)

makeBoard = () ->
    size = 10
    b = new Board(size)
    done = false
    [[sX,sY,sD],mirrors,permanent,[eX,eY,eD]] = genBoard(n=4,size=size)
    mirrors2 = []
    orientmap = {nw:1 ,ne:2 ,se:3, sw:4}
    for m in mirrors
        mirror = new Mirror([m.x,m.y],orientmap[m.orientation],false)
        mirrors2.push(mirror)
    for b in permanent 
        if b.type is B
            elem = new Block([b.x,b.y])
        else
            elem = new Mirror([b.x,b.y],orientmap[b.orientation])
        b.add(elem)
    d = if sD is 'h' then (if sY is -1 then 'left' else 'right') else (if sX is -1 then 'down' else 'up')
    b.add(new Startpoint([sX,sY]),d)
    d = if eD is 'h' then (if eY is -1 then 'left' else 'right') else (if eX is -1 then 'down' else 'up')
    b.add(new Endpoint([eX,eY]),d)
    [b,mirrors2]

exports ?= {}
exports.Rand = Rand

