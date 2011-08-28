# Based on jQuery Infinite Drag, which is (c) 2010 by Ial Li (ianli.com)
# Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.

$ ->
  $.infinitedrag = (draggable, bounds) ->
    new InfiniteDrag($(draggable), bounds)

  class InfiniteDrag
    constructor : (@draggable, @bounds) ->
      @parent = @draggable.parent()
      @parent.mousedown (e) =>
        @draggable.css position: 'absolute'
        @panning = true
        offset = @draggable.offset()
        @panStart = [e.pageX - offset.left, e.pageY - offset.top]
        
        css =
          position:'absolute'
          top:0
          left:0
          width:'100%'
          height:'100%'
          background:'transparent'
          zIndex:1000
          cursor: 'move'
        
        cover = $("<div/>").css(css).appendTo($("body"))
        
        $(document).bind 'mouseup.drag', (e) =>
          @panning = false
          $("body,#wrapper").css cursor: "auto"
          @draggable.css('cursor','auto')
          $(document).unbind('.drag')
          cover.remove()

        lb = - @bounds[2] + @parent.width()/2
        tb = - @bounds[3] + @parent.height()/2
        rb = - @bounds[0] + @parent.width()/2
        bb = - @bounds[1] + @parent.height()/2
          
        cover.bind 'mousemove.drag', (e) =>
          xp = e.pageX - @panStart[0]
          yp = e.pageY - @panStart[1]
          x = Math.max(lb, Math.min(xp, rb))
          y = Math.max(tb, Math.min(yp, bb))
          
          @draggable.css left: x, top: y
          
          e.stopImmediatePropagation()
          
        return false
          
          