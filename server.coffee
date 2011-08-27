static = require 'node-static'
nko = require('nko')('3K5CfNDu8AAVXRy3')
files  = new static.Server('./public')

server = require('http').createServer (req, resp) -> 
  req.addListener 'end', -> 
    files.serve req, resp, (e, res) ->
      if e and e.status == 404
        files.serveFile '/not-found.html'
  
server.listen process.env.PORT || 7777

#nowjs    = require 'now'
#everyone = nowjs.initialize(server, {socketio: {'log level': 1}})

