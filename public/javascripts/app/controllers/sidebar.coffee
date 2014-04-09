class Sidebar extends Spine.Controller
  className: "sidebar"

  reload: =>
    @render()
    
  render: =>
    @html @template("sidebar")()
    @

@app.exports["module sidebar"] = Sidebar
