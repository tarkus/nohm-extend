themes = ['slide', 'fade']
theme = 'fade'

if theme is 'slide'

  Spine.stage = [{}, {}, {}]

  Spine.Stack.include

    add: (controller) ->
      Spine.stage[2][controller.constructor.name] = controller
      @manager.add(controller)
      @append(controller)

  Spine.Manager.include
    change: (current, args...) ->
      ProgressBar.show()
      $("<div id='buffer' style='left: 10000'/>").appendTo($("body")) if $("#buffer").length is 0
      ###
      for cont in @controllers when cont isnt current
        cont.deactivate(args...)

        current.activate(args...) if current
      ###
      for list, placement in Spine.stage
        continue unless list[current.constructor.name]?
        if placement == 0
          for name, act of Spine.stage[1]
            act.offstage "left", ->
              delete Spine.stage[1][@constructor.name]
              Spine.stage[2][@constructor.name] = @
          current.onstage "left", ->
            delete Spine.stage[0][@constructor.name]
            Spine.stage[1][@constructor.name] = @
        else if placement == 2
          for name, act of Spine.stage[1]
            act.offstage "right", ->
              delete Spine.stage[1][@constructor.name]
              Spine.stage[0][@constructor.name] = @
          current.onstage "right", ->
            delete Spine.stage[2][@constructor.name]
            Spine.stage[1][@constructor.name] = @
      ProgressBar.hide()

  Spine.Controller.include

    onstage: (dir=null, cb=null) ->
      unless dir?
        @activate()
        cb?.apply(@)
        return @
      @el.css "left", if dir is "right" then $(document).width() + 50 else -($(document).width() + 50)
      @el.css "display", "block"
      effect = {}
      effect['left'] = 0
      @el.animate effect, =>
        @activate()
        cb?.apply(@)
      @

    offstage: (dir=null, cb=null) ->
      unless dir?
        @el.css "display", "none"
        @deactivate()
        cb?.apply(@)
        return @
      effect = {}
      effect['left'] = if dir is "right" then -($(document).width() + 50) else $(document).width() + 50
      @el.animate effect, =>
        @el.css "display", "none"
        @deactivate()
        cb?.apply(@)
      @

else if theme is 'fade'

  Spine.Manager.include
    change: (current, args...) ->

      for cont in @controllers when cont isnt current
        cont.el.fadeOut 'fast' if cont.el.hasClass('active')
        cont.deactivate(args...)

      current.el.css({ opacity: 0, display: 'block' }).animate { opacity: 1 }, Math.random() * 100 + 400, =>
        current.activate(args)

Spine.Stack::swap = {} if Spine.Stack

Spine.Controller.include

  ###
  init: () ->
    console.log @stack
  ###
  
  setStack: (stack) -> Spine.Controller::stack = stack

  template: (name) -> window.templates[name] ? (() -> "")
