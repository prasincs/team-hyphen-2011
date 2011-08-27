(function() {
  var Connection, Db, db, everyone, files, mongodb, nko, nowjs, server, static;
  static = require('node-static');
  nko = require('nko')('3K5CfNDu8AAVXRy3');
  files = new static.Server('./public');
  server = require('http').createServer(function(req, resp) {
    return req.addListener('end', function() {
      return files.serve(req, resp);
    });
  });
  server.listen(process.env.PORT || 7777);
  nowjs = require('now');
  everyone = nowjs.initialize(server, {
    socketio: {
      'log level': 1
    }
  });
  mongodb = require('mongodb');
  Db = mongodb.Db;
  Connection = mongodb.Connection;
  db = require("./mongohq").init({
    user: "team-hyphen",
    password: "mongohyphen",
    name: "nko",
    host: "staff.mongohq.com",
    port: 10082
  }).db;
  db.collection("test", function(err, collection) {
    return console.log(collection);
  });
}).call(this);
