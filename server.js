(function() {
  var files, server, static;
  static = require('node-static');
  files = new static.Server('./public');
  server = require('http').createServer(function(req, resp) {
    var everyone, nowjs;
    req.addListener('end', function() {
      return files.serve(req, resp);
    });
    server.listen(80);
    nowjs = require('now');
    return everyone = nowjs.initialize(server, {
      socketio: {
        'log level': 1
      }
    });
  });
}).call(this);
