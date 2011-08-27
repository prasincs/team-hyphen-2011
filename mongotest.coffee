mongo = require 'mongodb'

server = new mongo.Server "127.0.0.1", 27017, {}

client = new mongo.Db 'test', server

# save() updates existing records or inserts new ones as needed
exampleSave = (dbErr, collection) ->
  console.log "Unable to access database: #{dbErr}" if dbErr
  collection.save { _id: "my_favorite_latte", flavor: "honeysuckle" }, (err, docs) ->
    console.log "Unable to save record: #{err}" if err
    client.close()

client.open (err, database) ->
  client.collection 'coffeescript_example', exampleSave
