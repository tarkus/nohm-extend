Header     = @app.require 'module header'
Footer     = @app.require 'module footer'
Sidebar    = @app.require 'module sidebar'

Dashboard  = @app.require 'module dashboard'
Schema     = @app.require 'module schema'
Record     = @app.require 'module record'

class Stage extends Spine.Stack
  className: "stage"

  controllers:
    dashboard: Dashboard
    record: Record
    schema: Schema

  constructor: ->
    @el = $("<div id='page-wrapper'/>").addClass(@className).appendTo($("#wrapper")) unless @el?
    @footer = new Footer
    @footer.render()

    super
    
  #default: 'home'
class NohmBackend extends Spine.Controller
  className: "app"
  
  constructor: ->
    super

    @header  = new Header
    @sidebar = new Sidebar

    @append @header.render()
    @append @sidebar.render()

    @stage = new Stage
    @setStack @stage

    @routes
      "/schema/:name": (params) =>
        @stage.schema.active(params.name)

      "/*": =>
        @stage.dashboard.active()

$ ->
  moment.lang("zh-cn") if moment

  app = new NohmBackend el: $("#wrapper")
  Spine.Route.setup()

  window.App = app


