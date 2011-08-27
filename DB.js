var mongo=require('mongoskin'),
  db = mongo.db("team-hyphen:mongohyphen@staff.mongohq.com:10082/nko");

db.bind('users', {
  addUser: function (fn){
    this.insert(fn);
  }
});

exports.users = db.users;
