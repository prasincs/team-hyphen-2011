var mongo=require('mongoskin'),
  db = mongo.db("team-hyphen:mongohyphen@staff.mongohq.com:10082/nko");

db.bind('users', {
  addUser: function (user, fn){
    this.insert(user);
    fn;
  }
});

db.bind('plots', {
  addPlot: function (plot, fn){
    this.insert(plot);
    fn;
  },
  setLastPlot: function(coords,fn){
    this.update
  }

});

exports.users = db.users;
exports.plots =db.plots;
