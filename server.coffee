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


server = require('http').createServer (req, resp) -> 
  req.addListener 'end', -> files.serve req, resp

port = if process.env.NODE_ENV == 'production' then 80 else 8000

server.listen port

nowjs    = require 'now'
everyone = nowjs.initialize(server) #, {socketio: {'log level': 1}})


idMap = {}
plots = {}
lastPlot = [0,0] #get from database
usedPlots = {}

isPlotAssigned = (x,y)->
  usedPlots[x+","+y]

assignPlot = (x,y, u)->
  usedPlots[x+","+y] = u.clientId #get from database

userPlot = (u, assign = false) ->
  if assign
    assignPlot assign.gridX, assign.gridY, u
  plots[idMap[u.clientId]] = assign if assign
  plots[idMap[u.clientId]]



getNewPlot = ->
  plot = lastPlot
  while lastPlot == plot
    direction = Math.floor(Math.random()*4)+1
    [x,y] = plot
    switch direction
      when Constants.LaserDirection.N
        y= y+1
      when Constants.LaserDirection.S
        y= y-1
      when Constants.LaserDirection.W
        x= x+1
      when Constants.LaserDirection.E 
        x = x-1
    if not isPlotAssigned x,y
      lastPlot = [x,y]
      break
    else
      nextDir = Math.floor(Math.random()*4+1)
      plot = [x+nextDir, y+nextDir]
  lastPlot


everyone.now.requestPlot = (difficulty) ->
  [x,y] = getNewPlot()
  console.log x, y
  puzzle = new Puzzle(10)
  #idMap[@user.clientId] = {
  #  clientId:   @user.clientId,
  #  difficulty: difficulty
  #}
  gm = new GameManager puzzle, x ,y
  everyone.now.startPlot([x, y], puzzle, @user.clientId)
  userPlot @user, gm




everyone.now.entityAdded = (entity)->
  console.log "entity added " + entity.type
  [x,y] = entity.position

  type = Constants.RevEntityType[entity.type]
  et = new Game[type](entity.position, entity.orientation, entity.mobility)
  
  console.log(et.constructor.name)

  plot = userPlot @user
  console.log plot
  everyone.now.addEntity [plot.gridX, plot.gridY], et

everyone.now.entityRemoved = (x, y) ->
  everyone.now.removeEntity userPlot(@user), x, y
  
everyone.now.entityRotated = (x, y) ->
  everyone.now.rotateEntity userPlot(@user), x, y
