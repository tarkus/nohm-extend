class Dashboard extends Spine.Controller
  className: "dashboard"

  active: =>
    @render()
    
  render: =>
    @html @template("dashboard")()
    console.log @el.html()
    @

@app.exports["module dashboard"] = Dashboard
