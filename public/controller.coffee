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
  
  now = window.now ?= {}

  now.startPlot = (x, y, puzzle, clientId) ->
    reconstitute new Puzzle(1), puzzle
    UI.addPlot new GameManager(puzzle, x, y)#, now.core.clientId == clientId
    
  now.addEntity = (x, y, e) ->
    UI.plots[x][y].addEntity(e)
    
  now.removeEntity = (x, y) ->
    UI.plots[x][y].removeEntityAt(x,y)
    
  now.updateScores = (spintScores, highscores) ->
    unimplemented
  
  now.puzzleCompleted = ->
    # Modal dialog to req new puzzle
    unimplemented
    
  now.startSprint = (timeLeft) ->
    UI.sprintTime = Date.now() + timeLeft
  
  now.endSprint = (timeLeft) ->
    UI.sprintTime = - timeLeft - Date.now()

  now.requestPlot 1
