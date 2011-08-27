static = require 'node-static'
nko = require('nko')('3K5CfNDu8AAVXRy3')
files  = new static.Server('./public')

DB = require './DB'

Constants = require('./public/common').Constants
Game = require './public/game'
GameManager = Game.GameManager

server = require('http').createServer (req, resp) -> 
  req.addListener 'end', -> files.serve req, resp

port = if process.env.NODE_ENV == 'production' then 80  else 8000

server.listen port

nowjs    = require 'now'
everyone = nowjs.initialize(server) #, {socketio: {'log level': 1}})

#require './generator/gen'

idMap = {}
plots = {}

everyone.now.addUser = (user, callback)->
  DB.users.addUser user, callback

everyone.now.requestPlot= (difficulty) ->
  x = 1
  y = 0
  puzzle = PuzzleGenerator.randomPuzzle(difficulty)
  gm = new GameManager puzzle, x ,y
  everyone.now.startPlot(x, y, puzzle, @user.clientId)
  plots[idMap[@user.clientId]] = gm

