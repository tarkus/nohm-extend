if module.parent?
  {Nohm} = module.parent.require 'nohm'
else
  {Nohm} = require "nohm"

class NohmExtend extends Nohm

  @extends: {}
  @methods: {}

  @model: (name, options) ->
    options.methods ?= {}
    options.extends ?= {}

    @methods[k] = v for k, v of @_methods
    @methods[k] = v for k, v of options.methods
    options.methods = @methods

    @extends[k] = v for k, v of @_extends
    @extends[k] = v for k, v of options.extends

    model = Nohm.model(name, options)
    model[k] = v for k, v of @extends
    model

  @_extends:
    get: (criteria, callback) ->
        @find criteria, (err, ids) ->
          return callback(err) if err
          if ids.length is 1
            @load ids[0], (err) ->
              return callback(err) if err
              callback(null, @allProperties())
          else
            @loadSome.call(@, [ids, callback])

    loadSome: (ids, callback) ->
      return callback(null, []) if ids.length is 0
      rows = []
      count = 0
      total = ids.length
      for id in ids
        @load parseInt(id), (err, props) ->
          return callback(err) if err
          rows.push @allProperties()
          count++
          callback(null, rows) if count is total

    count: (criteria, callback) ->
      if typeof criteria is 'function'
        callback = criteria
        criteria = null
        m = new this
        return Nohm.client.scard Nohm.prefix.idsets + m.modelName, (err, result) ->
          return callback err if err
          return callback null, result

      @find criteria, (err, ids) ->
        return callback err if err
        return callback null, ids.length
      
    ids: (criteria, callback) ->
      ids = []
      _criteria =
        search: ''
        direction: 'DESC'
        amount: 30
      if typeof criteria is "string"
        criteria = search: criteria
      _criteria extends criteria
      m = _criteria.search.match /([<|>|=]=?)\s*(\d+)/
      return callback 'invalid params' if m.length != 3
      op = m[1]
      value = m[2].toString()
      @find (err, ids) ->
        return callback err if err
        max = ids.length - 1
        idx = ids.indexOf value
        return callback 'not found' if idx is -1
        if op[0] is '>'
          if op[1]? and op[1] is '='
            start = Math.min max, idx
          else
            start = Math.min max, idx + 1
          return callback null, [] if start == max
          result = ids[start..]

        if op[0] is '<'
          if op[1]? and op[1] is '='
            stop = Math.max max, idx
          else
            stop = Math.max 0, idx - 1
          return callback null, [] if stop == 0
          result = ids[..stop]

        result.reverse() if _criteria.direction is "DESC"
        callback null, result[..._criteria.amount]

  @_methods:
    save: (cb) ->
      _cb = (err) =>
        cb?.call(@, err)
      @_super_save.call(@, _cb)
      
    allProperties: (stringify) ->
      props = @_super_allProperties.call(@)
      props.id = parseInt(props.id) if props.id?
      return if stringify? then JSON.stringify props else props

module.exports = NohmExtend
