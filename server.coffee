static = require 'node-static'
files  = new static.Server('./public');

server = require('http').createServer (req, resp) -> 
  req.addListener 'end', -> files.serve(req, resp)
  
  server.listen 80
 

  nowjs    = require 'now'
  everyone = nowjs.initialize(server, {socketio: {'log level': 1}})
