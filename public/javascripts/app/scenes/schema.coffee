SchemaModel = @app.require 'model schema'

class Schema extends Spine.Controller

  constructor: ->
    super
    SchemaModel.bind 'refresh', @create

  active: (name) ->
    SchemaModel.fetch url: "#{base_uri}/schema/#{name}"

  create: (schema) =>
    @schema = schema
    @render()
    console.log 'hi'

  render: =>
    @replace @template("schema") schema: @schema
    @


@app.exports['module schema'] = Schema
