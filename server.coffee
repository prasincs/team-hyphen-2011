static = require 'node-static'
nko = require('nko')('3K5CfNDu8AAVXRy3')
files  = new static.Server('./public')

server = require('http').createServer (req, resp) -> 
  req.addListener 'end', -> 
    files.serve req, resp

port = if process.env.NODE_ENV == 'production' then 80  else 8000

server.listen port, ->
  console.log 'Ready'

#nowjs    = require 'now'
#everyone = nowjs.initialize(server, {socketio: {'log level': 1}})

