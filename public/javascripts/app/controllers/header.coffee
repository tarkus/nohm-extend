class Header extends Spine.Controller
  className: "header"

  reload: =>
    @render()
    
  render: =>
    @html @template("header") profile: window.Profile
    @

@app.exports["module header"] = Header
