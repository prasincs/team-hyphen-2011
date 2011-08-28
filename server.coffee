static = require 'node-static'
nko    = require('nko')('3K5CfNDu8AAVXRy3')
files  = new static.Server('./public')

DB          = require './DB'
Constants   = require('./public/common').Constants
Game        = require './public/game'
GameManager = Game.GameManager
GridEntity  = Game.GridEntity
Puzzle      = Game.Puzzle
Mirror      = Game.Mirror
Prism       = Game.Prism
Filter      = Game.Filter
generator   = require './generator/gen'

server = require('http').createServer (req, resp) -> 
  req.addListener 'end', -> files.serve req, resp

port = if process.env.NODE_ENV == 'production' then 80 else 8000

server.listen port

nowjs    = require 'now'
everyone = nowjs.initialize(server) #, {socketio: {'log level': 1}})

lastPlotId = 1
idMap = {}
plots = {}


plotId = 1
initPlot = [10,10]
usedPlots = {}
plotIdToCoord = []
usedPlotQ = []

getPlot = (x,y)->
  usedPlots[x + ","+y]

isPlotAssigned = (x,y)->
  getPlot(x,y)

plotNeighbors = (x,y)->
  neighbors = {}
  count = 0
  if isPlotAssigned(x-1, y)
    neighbors["E"]= [x-1,y]
    count +=1
  if isPlotAssigned(x+1, y)
    neighbors["W"] = [x+1, y]
    count +=1
  if isPlotAssigned(x, y-1)
    neighbors["N"] = [x, y-1]
    count +=1
  if isPlotAssigned(x, y+1)
    neighbors["S"] = [x, y+1]
    count +=1
  neighbors.count = count
  neighbors

updatePlotNeighbors = (x,y)->
  plot = getPlot(x,y)
  plot.neighbors = plotNeighbors(x,y)
  plot.openSides =  4 - plot.neighbors.count

assignPlot = (x,y, u)->
  neighbors = plotNeighbors(x,y)
  usedPlots[x+","+y] = {
    plotId: plotId,
    loc: [x,y],
    clientId: u.clientId,
    neighbors: neighbors
    openSides: 4 - neighbors.count
  }
  plotIdToCoord[plotId] = x+","+y
  usedPlotQ.push(plotId)
  usedPlotQ.sort (id1,id2) ->
    usedPlots[plotIdToCoord[id1]].openSides - usedPlots[plotIdToCoord[id2]].openSides
  # remove all the ones with sides filled already
  while usedPlots[plotIdToCoord[usedPlotQ[0]]].openSides == 0
      usedPlotQ.shift()
  plotId++
  delete neighbors.count
  for dir, coord of neighbors
    [x,y] = coord
    updatePlotNeighbors(x,y)

getCrowdedPlotId = ->
  usedPlotQ[0]

getEmptyNeighborCoord = (id)->
  plot = usedPlots[plotIdToCoord[id]]
  [x,y] = plot.loc
  neighbors = plot.neighbors
  # could be done a bit smartly with more stuff
  if not neighbors["E"]
    [x-1,y]
  else if not neighbors["W"]
    [x+1,y]
  else if not neighbors["N"]
    [x, y-1]
  else if not neighbors["S"]
    [x, y+1]

userPlot = (u, assign = false) ->
  if assign
    assignPlot assign.gridX, assign.gridY, u
  plots[u.clientId] = assign if assign
  plots[u.clientId]

getNewPlot = ->
  plot = []
  if plotId == 1
    plot = initPlot
  else
    crowdedPlotId = getCrowdedPlotId()
    plot = usedPlots[plotIdToCoord[crowdedPlotId]]
    plot = getEmptyNeighborCoord(crowdedPlotId)
  plot



everyone.now.requestPlot = (difficulty) ->
  [x,y] = getNewPlot()
  puzzle = new Puzzle(10, generator.serialize())
  gm = new GameManager lastPlotId, puzzle, x ,y
  everyone.now.startPlot plotId , [x, y], puzzle, @user.clientId
  assignPlot x,y, @user
  userPlot @user, gm


everyone.now.requestNeighborPlots = (id)->
  for clientId, gm of plots
    if  clientId != @user.clientId
      @now.drawPlot gm.id, [gm.gridX, gm.gridY], gm.puzzle, clientId


everyone.now.entityAdded = (entity)->
  console.log "entity added " + entity.type
  [x,y] = entity.position
  type = Constants.RevEntityType[entity.type]
  et = new Game[type](entity.position, entity.orientation, entity.mobility)
  

  plot = userPlot @user
  everyone.now.addEntity plot.id, et

everyone.now.entityRemoved = (x, y) ->
  everyone.now.removeEntity userPlot(@user), x, y
  
everyone.now.entityRotated = (x, y) ->
  everyone.now.rotateEntity userPlot(@user), x, y

#everyone.now.validateSolution = (solution)->
#  unimplemented
