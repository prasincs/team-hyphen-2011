var mongo=require("mongoskin"),
db = mongo.db("team-hyphen:mongohyphen@staff.mongohq.com:10082/nko");
test = db.collection('test')
test.find().toArray(function(err, items){
  console.dir(items);
});

//test.insert({a:2})

