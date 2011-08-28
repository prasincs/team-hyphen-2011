# Based on jQuery Infinite Drag, which is (c) 2010 by Ial Li (ianli.com)
# Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.

$ ->
  $.infinitedrag = (draggable, bounds) ->
    new InfiniteDrag($(draggable), bounds)

  class InfiniteDrag
    
    constructor : (@draggable, @bounds) ->
      @css =
        position:'absolute'
        top:0
        left:0
        width:'100%'
        height:'100%'
        background:'transparent'
        zIndex:1000
        cursor: 'move'
      
      @parent = @draggable.parent()
      @parent.mousedown (e) =>
        @draggable.css position: 'absolute'
        offset = @draggable.offset()
        @panStart = [e.pageX - offset.left, e.pageY - offset.top]
        @panning = true
        @cover?.unbind().remove()
        
        $(document).bind 'mouseup.drag', (e) =>
          @panning = false
          $("body,#wrapper").css cursor: "auto"
          $(document).unbind('.drag')
          @cover?.unbind().remove()
          true

        lb = - @bounds[2] + @parent.width()/2
        tb = - @bounds[3] + @parent.height()/2
        rb = - @bounds[0] + @parent.width()/2
        bb = - @bounds[1] + @parent.height()/2
        
        @parent.bind 'mousemove', (f) =>
          @parent.unbind(f)
          return true unless @panning
          @cover = $("<div/>").css(@css).appendTo($("body"))
          @cover.bind 'mousemove.drag', (e) =>
            @cover?.unbind().remove() unless @panning
            xp = e.pageX - @panStart[0]
            yp = e.pageY - @panStart[1]
            x = Math.max(lb, Math.min(xp, rb))
            y = Math.max(tb, Math.min(yp, bb))
          
            @draggable.css left: x, top: y
          
            e.stopImmediatePropagation()
          
        return false
          
          