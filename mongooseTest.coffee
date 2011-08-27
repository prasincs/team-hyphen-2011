mongoose = require "mongoose"

connStr = "mongodb://team-hyphen:mongohyphen@staff.mongohq.com:10082/nko"

db = mongoose.connect connStr

Test = mongoose.model "test", new mongoose.Schema
  test:
    a: String

