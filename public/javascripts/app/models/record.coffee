class Record extends Spine.Model
  @configure "Record", "properties"
  @extend Spine.Model.Ajax

  @url: "/record"

@app.exports["model records"] = Record

