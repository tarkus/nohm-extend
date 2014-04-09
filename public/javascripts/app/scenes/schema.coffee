SchemaModel = @app.require 'model schema'

class Schema extends Spine.Controller

  constructor: ->
    super
    SchemaModel.bind 'refresh', @create

  active: (name) ->
    SchemaModel.fetch url: "#{base_uri}/schema/#{name}"

  create: =>

  render: =>
    @replace @template("schema")()
    @


@app.exports['module schema'] = Schema
