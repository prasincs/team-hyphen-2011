randInt = (range) -> Math.floor(Math.random()*(range+1))

dedupedLength = (arr) ->
    obj = {}
    obj[x.toString(10)] = true for x in arr
    len = 0
    len += 1 for k,v of obj
    len

randIntExclude = (range,excluded) ->
    result = randInt(range - (dedupedLength excluded))
    for i in excluded
        if result >= i and i >= 0 then result += 1
    if result < 0 then throw "randIntExclude < 0... " + result + " " + range
    result

getNewPicked = (from,to) ->
    [fX,fY,fDir] = from
    [tX,tY,tDir] = to
    if fDir is 'h'
        if fY isnt tY then throw "fDir is h, fY should equal tY"
        [x,fY] for x in [fX..tX]
    else
        if fX isnt tX then throw "fDir is v, fX should equal tX"
        [fX,y] for y in [fY..tY]

pickNext = (current,size,picked) ->
    [cX,cY,cDir] = current
    if cDir is 'h'
        excluded = (x for [x,y] in picked when y is cY)
        newX = randIntExclude(size-1,excluded)
        pick = [newX,cY,'v']
    else
        excluded = (y for [x,y] in picked when x is cX)
        newY = randIntExclude(size-1,excluded)
        pick = [cX,newY,'h']
    picked = picked.concat(getNewPicked(current,pick))
    [pick,picked]

pickPenultimate = (current,end) ->
    [cX,cY,cDir] = current
    [eX,eY,eDir] = end
    if cDir is eDir then throw "directions shouldn't be the same"
    if cDir is 'h'
        [eX,cY,'v']
    else
        [cX,eY,'h']

pickPoints = (start,end,size,n=2,picked=null) ->
    unless picked
        picked = [ [start[0],start[1]], [end[0],end[1]] ]
        if end[2] is 'v'
            picked = picked.concat([end[0],y] for y in [0...size])
        else
            picked = picked.concat([x,end[1]] for x in [0...size])
    if n is 1
        next = pickPenultimate(start,end)
        picked = picked.slice(2+size)
        picked = picked.concat(getNewPicked(start,next))
        picked = picked.concat(getNewPicked(next,end))
        [[next],picked]
    else
        [next,picked] = pickNext(start,size,picked)
        [list,picked] = pickPoints(next,end,size,n-1,picked=picked)
        list.unshift(next)
        [list,picked]

randomPoint = (size) ->
    [randInt(size-1),randInt(size-1)]

pickRandomPoints = (size,blocked,number=10) ->
    blockedStrs = ((b+'') for b in blocked)
    points = []
    while points.length < number
        point = randomPoint(size)
        if (point+'') not in blockedStrs then points.push(point)
    points

assignDirections = (start,end,points) ->
    points.unshift(start)
    points.push(end)
    mirrors = []
    for [x,y,d],i in points[1...(points.length-1)]
        [prev,next] = [points[i],points[i+2]]
        if d is 'h' then [prev,next] = [next,prev]
        if prev[0] < x and next[1] < y
            #   n
            # p /
            mirrors.push([x,y,'nw'])
        if prev[0] > x and next[1] < y
            # n
            # \ p
            mirrors.push([x,y,'ne'])
        if prev[0] < x and next[1] > y
            # p \
            #   n
            mirrors.push([x,y,'sw'])
        if prev[0] > x and next[1] > y
            # / p
            # n
            mirrors.push([x,y,'se'])
    mirrors

genBoard = (n=2,size=10) ->
    done = false
    until done
        try
            board = [["_" for i in [0...10]] for j in [0...10]]
            startPoint = [-1,5,'h']
            endPoint = [10,2,'h']
            [points,blocked] = pickPoints(startPoint,endPoint,size,n)
            mirrors = assignDirections(startPoint,endPoint,points)
            blocks = pickRandomPoints(size,blocked,number=30)
            done = true
    [startPoint,mirrors,blocks,endPoint]

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
    [start,generated,blocked,end] = genBoard(n=6,size=size)
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
    [[sX,sY,sD],mirrors,blocks,[eX,eY,eD]] = genBoard(n=4,size=size)
    for [x,y,d] in mirrors
        orientmap = {nw:1 ,ne:2 ,se:3, sw:4}
        mirror = new Mirror([x,y],orientmap[d],false)
        b.add(mirror)
    for [x,y] in blocks
        block = new Block([x,y])
        b.add(block)
    d = if sD is 'h' then (if sY is -1 then 'left' else 'right') else (if sX is -1 then 'down' else 'up')
    b.add(new Startpoint([sX,sY]),d)
    d = if eD is 'h' then (if eY is -1 then 'left' else 'right') else (if eX is -1 then 'down' else 'up')
    b.add(new Endpoint([eX,eY]),d)
    b

drawBoard()

exports ?= {}
exports.randIntExclude = randIntExclude
exports.pickNext = pickNext
exports.pickPenultimate = pickPenultimate
exports.pickPoints = pickPoints
exports.genBoard = genBoard
exports.getNewPicked = getNewPicked

