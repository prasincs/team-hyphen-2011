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
Prism       =  Game.Prism
Filter      = Game.Filter


server = require('http').createServer (req, resp) -> 
  req.addListener 'end', -> files.serve req, resp

port = if process.env.NODE_ENV == 'production' then 80 else 8000

server.listen port

nowjs    = require 'now'
everyone = nowjs.initialize(server) #, {socketio: {'log level': 1}})


idMap = {}
plots = {}

everyone.now.addUser = (user, callback)->
  DB.users.addUser user, callback

everyone.now.requestPlot= (difficulty) ->
  [x,y] = [1,0]
  puzzle = new Puzzle(10)
  gm = new GameManager puzzle, x ,y
  console.log @user.clientId
  everyone.now.startPlot(x, y, puzzle, @user.clientId)
  plots[idMap[@user.clientId]] = gm

everyone.now.entityAdded = (entity)->
  console.log entity
  [x,y] = entity.position
  et = new GridEntity entity.position, entity.orientation, entity.mobility

  switch (entity.type)
    when Constants.EntityType.MIRROR
      et = new Mirror entity.position, entity.orientation, entity.mobility
    when Constants.EntityType.PRISM
      et = new Prism entity.position, entity.orientation, entity.mobility
    when Constants.EntityType.FILTER
      et = new Filter entity.position, entity.orientation, entity.mobility
    
  everyone.now.addEntity x, y, et

everyone.now.entityRemoved = (entity)->
  console.log entity
  [x,y] = entity.position
  everyone.now.removeEntity(x,y, entity)
