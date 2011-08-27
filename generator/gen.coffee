randInt = (range) -> Math.floor(Math.random()*(range+1))
randIntExclude = (range,excluded) ->
    x = randInt(range - excluded.length)
    for i in excluded
        if x >= i then x += 1
    x % (range+1)

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
    picked.concat(getNewPicked(current,pick))
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
    picked ||= [ [start[0],start[1]], [end[0],end[1]] ]
    if n is 1
        [pickPenultimate(start,end)]
    else
        [next,picked] = pickNext(start,size,picked)
        list = pickPoints(next,end,size,n-1,picked=picked)
        list.unshift(next)
        list

genBoard = (n=2,size=10) ->
    board = [["_" for i in [0...10]] for j in [0...10]]
    startPoint = [0,5,'h']
    endPoint = [9,2,'h']
    pickPoints(startPoint,endPoint,size,n)

exports.randIntExclude = randIntExclude
exports.pickNext = pickNext
exports.pickPenultimate = pickPenultimate
exports.pickPoints = pickPoints
exports.genBoard = genBoard
exports.getNewPicked = getNewPicked


#create a path through the board
#    prev = START
#    loop () =
#        next = choose_linear_from prev
#        pts << next
#        prev = next
#        loop ()
#    when we get ~3-4 in, make next line up with end point, and then go to there
