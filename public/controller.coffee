$ ->
  UI.installHandlers()
  
  UI.draw()
  
  reconstitute = (blank, data) -> data.__proto__ = blank
  
  notMyPlot = (plotId) ->
    if plotId == UI.localPlot.manager.id then undefined else UI.plots[plotId]
  
  now = window.now ?= {}

  now.startPlot = (id, coords, puzzle, clientId) ->
    [x, y] = coords
    reconstitute new Puzzle(1), puzzle
    manager = new GameManager(id, puzzle, x, y)
    manager.deserializePuzzle()
    UI.addPlot manager, now.core.clientId == clientId
    now.requestNeighborPlots id
    UI.draw()

  now.drawPlot = (id, [x,y], puzzle, clientId) ->
    if clientId != now.core.clientId
      reconstitute new Puzzle(1), puzzle
      manager = new GameManager(id, puzzle, x, y)
      manager.deserializePuzzle()
      UI.addPlot manager

  
  now.addEntity = (plotId, e) ->
    if (plot = notMyPlot(plotId))
      if Constants.EntityType.MIRROR == e.type
        plot.addEntity(new Mirror(e.position, e.orientation, true))
      else
        plot.addEntity(new Filter(e.position, e.orientation, e.color, true))
      plot.draw()
  
  now.removeEntity = (plot, x, y) ->
    notMyPlot(plot)?.removeEntityAt(x,y)
    
  now.rotateEntity = (plot, x, y) ->
    notMyPlot(plot)?.rotateEntityClockwise(x, y)
    
  now.updateScores = (spintScores, highscores) ->
    unimplemented
  
  now.puzzleCompleted = ->
    UI.showStartDialog()
    
  now.startSprint = (timeLeft) ->
    UI.sprintTime = Date.now() + timeLeft
    UI.plots = []
    $(".plot").remove()
  
  now.endSprint = (timeLeft) ->
    UI.sprintTime = - timeLeft - Date.now()

