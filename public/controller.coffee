$ ->
  UI.installHandlers()
  UI.container = $("#map")
  
  UI.addPlot new GameManager(new Puzzle(), 0, 0), true
  UI.addPlot new GameManager(new Puzzle(), 1, 0)
  UI.addPlot new GameManager(new Puzzle(), 0, 1)
  UI.addPlot new GameManager(new Puzzle(), 0, 2)
  UI.addPlot new GameManager(new Puzzle(), 3, 3)
  
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
    # Modal dialog to req new puzzle
    unimplemented
    
  now.startSprint = (timeLeft) ->
    UI.sprintTime = Date.now() + timeLeft
  
  now.endSprint = (timeLeft) ->
    UI.sprintTime = - timeLeft - Date.now()

  now.ready -> 
    now.requestPlot 1
