class Schema extends Spine.Model

  @configure "Schema", "name", "schema"
  @extend Spine.Model.Ajax

  @url: "/schema"

@app.exports["model schema"] = Schema

