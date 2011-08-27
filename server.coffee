static = require 'node-static'
nko = require('nko')('3K5CfNDu8AAVXRy3')
files  = new static.Server('./public')

server = require('http').createServer (req, resp) -> 
  req.addListener 'end', -> 
    files.serve req, resp

port = if process.env.NODE_ENV == 'production' then 80  else 8000

server.listen port, ->
  console.log 'Ready'

nowjs    = require 'now'
everyone = nowjs.initialize(server, 
  {socketio: {'log level': 1}})

DB = require './DB'

everyone.now.addUser = (user, callback)->
  DB.users.addUser user, callback
Constants = require ('./public/common').Constants
console.log Constants
#require './public/game'
#require './generator/gen'

idMap = {}
plots = {}

everyone.now.requestPlot= (difficulty) ->
  x = 1
  y = 0
  puzzle = PuzzleGenerator.randomPuzzle(difficulty)
  #gm = new GameManager (puzzle, x ,y)
  everyone.now.startPlot(x, y, puzzle, @user.clientId)
  #plots[idMap[@user.clientId]] = gm

