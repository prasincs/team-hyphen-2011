class Plot
  hacks : {}
  
  constructor : (@puzzle, @front, @back) ->
    @fp = @front.getContext '2d'
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
        
  #drawStatic : ->
    
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
  dragging  : false
  
  showControls : -> @zoomLevel >= 0.75
  
  drawControls : ->
    if @showControls()
      false
      
  draw : ->
    for plot in @plots
      plot.drawTiles()
  
  displayDrag : (x, y) ->
    e = UI.dragging
    l = x - e.width()/2
    t = y - e.height()/2
    UI.dragging.css position: 'absolute', left: l, top: t, zIndex: 1000
  
  installHandlers : ->
    $(document).mousedown (e) ->
      UI.mousedown = [e.pageX, e.pageY]
    $(document).mouseup (e) ->
      UI.mousedown = false
      
    $(document).mousemove (e) =>
      if @dragging
        if @mousedown
          @displayDrag(e.pageX, e.pageY)
        else
          # add entity
          @dragging.remove()
          @dragging = false
      else if @mousedown
        # pan
        @center[0] += e.pageX - @mousedown[0]
        @center[1] += e.pageY - @mousedown[1]
        UI.mousedown = [e.pageX, e.pageY]
      true
    
    $("#item").mousedown (e) ->
      UI.dragging = $(this).clone().attr("being-dragged",false).appendTo($("body"))
      UI.displayDrag(e.pageX, e.pageY)
  
  addPlot : (puzzle, $div) ->
    p = new Plot(puzzle, $div.find('.fg')[0], $div.find('.bg')[0])
    $div.mousemove (e) -> 
      p.hoverHandler(e) or true
    $div.mouseup (e) ->
      p.hackHandler(e) or true
    @plots.push p