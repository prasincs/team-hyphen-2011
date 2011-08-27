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

userPlot = (u, assign = false) ->
  plots[idMap[u.clientId]] = assign if assign
  plots[idMap[u.clientId]]

everyone.now.addUser = (user, callback)->
  DB.users.addUser user, callback

everyone.now.requestPlot = (difficulty) ->
  [x,y] = [1,0]
  puzzle = new Puzzle(10)
  gm = new GameManager puzzle, x ,y
  everyone.now.startPlot([x, y], puzzle, @user.clientId)
  userPlot @user, gm

everyone.now.entityAdded = (entity)->
  [x,y] = entity.position

  et = switch (entity.type)
    when Constants.EntityType.MIRROR
      new Mirror entity.position, entity.orientation, entity.mobility
    when Constants.EntityType.PRISM
      new Prism entity.position, entity.orientation, entity.mobility
    when Constants.EntityType.FILTER
      new Filter entity.position, entity.orientation, entity.mobility
    else
      new GridEntity entity.position, entity.orientation, entity.mobility
  
  plot = userPlot @user
  everyone.now.addEntity [plot.gridX, plot.gridY], et

veryone.now.entityRemoved = (x, y) ->
  everyone.now.removeEntity userPlot(@user), x, y
  
everyone.now.entityRotated = (x, y) ->
  everyone.now.rotateEntity userPlot(@user), x, y
