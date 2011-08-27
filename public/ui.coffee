class Plot
  
  constructor : (@manager, @front, @mid, @back) ->
    @fp = @front.getContext '2d'
    @mp = @mid.getContext '2d'
    @bp = @back.getContext '2d'
    @size  = @front.height
    @scale = @size / 10.0
    @pen = @mp
  
  drawTiles : ->
    @bp.fillStyle = '#999999'
    @bp.fillRect 0, 0, @size, @size
    
    @bp.fillStyle = '#cccccc'
    for x in [0..10]
      for y in [x%2..10] by 2
        @bp.fillRect x*@scale, y*@scale, @scale, @scale

  drawEntities : ->
    @pen = @mp
    @pen.clearRect 0, 0, @size, @size
    for x in [0..9]
      for y in [0..9]
        if e = @manager.getEntityAt(x, y)
          @[e.constructor.name.toLowerCase()](e)

  block : (e) ->
    [x,y] = e.position
    @pen.fillStyle = "#000000"
    @pen.fillRect x*@scale + 4, y*@scale + 4, @scale - 8, @scale - 8
    
  mirror : (e) ->
    [x, y] = e.position
    
    @pen.strokeStyle = e.color || "#000000"
    @pen.beginPath()
    if e.orientation % 2 == 1 # NW
      @pen.moveTo(x*@scale + 4, y*@scale + 4)
      @pen.lineTo((x+1)*@scale - 4, (y+1)*@scale - 4)
    else
      @pen.moveTo((x+1)*@scale - 4, y*@scale + 4)
      @pen.lineTo(x*@scale + 4, (y+1)*@scale - 4)
    @pen.closePath()
    @pen.stroke()
  
  prism : (e) ->
    [x,y] = e.position
    
    @pen.save()
    @pen.translate((x+0.5) * @scale, (y+0.5) * @scale)
    @pen.rotate(Math.PI/2 * (e.orientation-1))
    @pen.fillStyle = "#000000"
    @pen.fillRect(4-@scale/2, -@scale/2, @scale-8, 8)
    @pen.fillRect(-4, -@scale/2, 4, @scale)
    @pen.restore()
  
  filter : (e) -> @mirror(e)
    
  coordsToSquare : (e) ->
    offset = $(@front).offset()
    
    [Math.floor((e.pageX - offset.left)/@scale),
     Math.floor((e.pageY - offset.top)/@scale)]

  clearLast : () ->
    if @lastMouseMove
      @fp.clearRect @lastMouseMove[0]*@scale, @lastMouseMove[1]*@scale, @scale, @scale
    

  hoverHandler : (e) ->
    @clearLast()

    @lastMouseMove = [x,y] = @coordsToSquare e
        
    @fp.strokeStyle = '#00ff00' # ugly color for debugging
    @fp.strokeRect x*@scale+2, y*@scale+2, @scale-4, @scale-4

    # display tool
    if !@manager.getEntityAt(x, y) and UI.tool
      @pen = @fp
      @[UI.tool.toLowerCase()](new (window[UI.tool])([x,y], 1, true))
    
  clickHandler : (e) ->
    [x, y] = @coordsToSquare e
    
    if entity = @manager.getEntityAt(x, y)
      if e.which == 3 # right click
        @manager.removeEntityAt(x, y)
      else
        @manager.rotateEntityClockwise(x, y)
    else if UI.tool
      @manager.addEntity(new (window[UI.tool])([x,y], 1, true))
    @drawEntities()
    @clearLast()
    
UI =
  zoomLevel : 1 # between 0 and 1 with 1 being max zoom level and 0.25 being 4x further away
  center    : [0, 0]
  plots     : []
  container : false
  mousedown : false
  tool      : false      
  
  zoom : (to) ->
    zoomLevel = to
    if zoomLevel >= 0.75
      $("#palate").fadeIn()
    else
      $("#palate").fadeOut()
      
  draw : ->
    for plot in @plots
      plot.drawTiles()
  
  
  installHandlers : ->
    $(document).mousedown (e) ->
      UI.mousedown = [e.pageX, e.pageY]
    $(document).mouseup (e) ->
      UI.mousedown = false
      
    $(document).mousemove (e) =>
      if @mousedown
        # pan
        @center[0] += e.pageX - @mousedown[0]
        @center[1] += e.pageY - @mousedown[1]
        UI.mousedown = [e.pageX, e.pageY]
      true
    
    $("#palate li").click (e) -> UI.tool = $(this).data("tool")
  
  addPlot : (puzzle, $div) ->
    p = new Plot(puzzle, $div.find('.fg')[0], $div.find('.mg')[0], $div.find('.bg')[0])
    $div.mousemove (e) -> p.hoverHandler(e) or true
    $div.mouseup (e)   -> p.clickHandler(e) or true
    $div.mouseout (e)  -> p.clearLast()     or true
    @plots.push p