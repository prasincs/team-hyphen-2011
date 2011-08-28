$ ->
  UI.installHandlers()
  
  UI.draw()
  
  reconstitute = (blank, data) -> data.__proto__ = blank
  
  notMyPlot = ([x, y]) ->
    plot = UI.plots[x][y]
    if plot == UI.localPlot then undefined else plot
  
  now = window.now ?= {}

  now.startPlot = ([x, y], puzzle, clientId) ->
    reconstitute new Puzzle(1), puzzle
    UI.addPlot new GameManager(puzzle, x, y), now.core.clientId == clientId
    
  now.addEntity = (plot, e) ->
    notMyPlot(plot)?.addEntity(e) # we gotta recreate this entity
    
  now.removeEntity = (plot, x, y) ->
    notMyPlot(plot)?.removeEntityAt(x,y)
    
  now.rotateEntity = (plot, x, y) ->
    notMyPlot(plot)?.rotateEntityClockwise(x, y)
    
  now.updateScores = (spintScores, highscores) ->
    unimplemented
  
  now.puzzleCompleted = ->
    $("#start-panel").show()
    
  now.startSprint = (timeLeft) ->
    UI.sprintTime = Date.now() + timeLeft
    UI.plots = []
    $(".plot").remove()
  
  now.endSprint = (timeLeft) ->
    UI.sprintTime = - timeLeft - Date.now()

