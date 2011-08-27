class Plot
  hacks : {}
  
  constructor : (@manager, @front, @mid, @back) ->
    @fp = @front.getContext '2d'
    @mp = @mid.getContext '2d'
    @bp = @back.getContext '2d'
    @size  = @front.height
    @scale = @size / 10.0
  
  drawTiles : ->
    @bp.fillStyle = '#999999'
    @bp.fillRect 0, 0, @size, @size
    
    @bp.fillStyle = '#cccccc'
    for x in [0..10]
      for y in [x%2..10] by 2
        @bp.fillRect x*@scale, y*@scale, @scale, @scale

  block : (x, y) ->
    @mp.fillStyle = "#000000"
    @mp.fillRect x*@scale + 4, y*@scale + 4, @scale - 8, @scale - 8
    
  mirror : (x, y, startTopLeft, color = '#000000') ->
    @mp.strokeStyle = color
    @mp.beginPath()
    if startTopLeft
      @mp.moveTo(x*@scale + 4, y*@scale + 4)
      @mp.lineTo((x+1)*@scale - 4, (y+1)*@scale - 4)
    else
      @mp.moveTo((x+1)*@scale - 4, y*@scale + 4)
      @mp.lineTo(@scale + 4, (y+1)*@scale - 4)
    @mp.closePath()
    @mp.stroke()
  
  splitter : (x, y, orientation) ->
    @mp.save()
    @mp.translate((x+0.5) * @scale, (y+0.5) * @scale)
    @mp.rotate(Math.PI/2 * orientation)
    @mp.fillStyle = "#000000"
    @mp.fillRect(4-@scale/2, -@scale/2, @scale-8, 8)
    @mp.fillRect(-4, -@scale/2, 4, @scale)
    @mp.restore()
      
    
  coordsToSquare : (e) ->
    offset = $(@front).offset()
    
    [Math.floor((e.pageX - offset.left)/@scale),
     Math.floor((e.pageY - offset.top)/@scale)]

  hoverHandler : (e) ->
    
    if @lastMouseMove
      @fp.clearRect @lastMouseMove[0]*@scale, @lastMouseMove[1]*@scale, @scale, @scale

    @lastMouseMove = [x,y] = @coordsToSquare e
        
    @fp.strokeStyle = '#00ff00' # ugly color for debugging
    @fp.strokeRect x*@scale+2, y*@scale+2, @scale-4, @scale-4

    # display tool
    if !@manager.getEntityAt(x, y) and UI.tool
      @[UI.tool](x,y)
    
  hackHandler : (e) ->
    [x, y] = @coordsToSquare e
    seq = ['#ff0000', '#ffff00', '#00ffff', '#000000', '#0000ff']
    
    @hacks["#{x}x#{y}"] = -1 if @hacks["#{x}x#{y}"] == undefined
    @hacks["#{x}x#{y}"] += 1
          
    @bp.fillStyle = seq[@hacks["#{x}x#{y}"] % 5]
    @bp.fillRect x*@scale, y*@scale, @scale, @scale
      
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
    
    $("#controls li").click (e) -> UI.tool = $(this).data("tool")
  
  addPlot : (puzzle, $div) ->
    p = new Plot(puzzle, $div.find('.fg')[0], $div.find('.mg')[0], $div.find('.bg')[0])
    $div.mousemove (e) -> 
      p.hoverHandler(e) or true
    $div.mouseup (e) ->
      p.hackHandler(e) or true
    @plots.push p