db = require("./mongohq").init({
  
  user: "team-hyphen",
  password: "mongohyphen",
  name: "nko",
  host: "staff.mongohq.com",
  port: 10082
})

doSomething = (err, coll) ->
  coll.insert {'x' : 2}

db.open (err, client)->
  db.collection "test", doSomething
  
