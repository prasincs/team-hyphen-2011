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
        if result >= i then result += 1
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
    points = []
    while points.length < number
        point = randomPoint(size)
        if point not in blocked then points.push(point)
    points

genBoard = (n=2,size=10) ->
    board = [["_" for i in [0...10]] for j in [0...10]]
    startPoint = [-1,5,'h']
    endPoint = [10,2,'h']
    [points,blocked] = pickPoints(startPoint,endPoint,size,n)
    [startPoint,points,blocked,endPoint]

class AsciiBoard
    constructor: (size) ->
        @board = (('.' for i in [0...(size+2)]) for j in [0...(size+2)])
    set: (x,y,c) ->
        try
            @board[x+1][y+1] = c
        catch e
            console.log(x + " " + y + " " + c)
            throw e
    addMirror: (x,y) -> @set(x,y,'/')
    addBlock:  (x,y) -> @set(x,y,'#')
    setStart:  ([x,y,d]) -> @set(x,y,'s')
    setEnd:    ([x,y,d]) -> @set(x,y,'e')
    print: ->
        console.log("printing:\n")
        for i in [0...@board.length]
            console.log(@board[i].join(' '))
    addMirrors: (mirrorList) ->
        for [x,y,d] in mirrorList
            @addMirror(x,y)


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

drawBoard()

exports ?= {}
exports.randIntExclude = randIntExclude
exports.pickNext = pickNext
exports.pickPenultimate = pickPenultimate
exports.pickPoints = pickPoints
exports.genBoard = genBoard
exports.getNewPicked = getNewPicked

