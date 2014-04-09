class Footer extends Spine.Controller
  className: "footer"

  reload: =>
    @render()
    
  render: =>
    @html @template("footer")
    @

@app.exports["module footer"] = Footer
