{Nohm} = require "nohm"

extend = (dest, objs...) ->
  for obj in objs
    dest[k] = v for k, v of obj
  dest

class NohmExtend extends Nohm

  @model: (name, options) ->
    options.methods ?= {}
    options.extends ?= {}

    options.methods = extend options.methods, @_methods

    model = Nohm.model(name, options)
    model = extend model, @_extends, options.extends
    model.modelName = name
    model

  @_extends:

    getClient: -> Nohm.client
    getHashKey: (id) -> "#{Nohm.prefix.hash}#{@modelName}:#{id}"

    get: (criteria, callback) ->
      @findAndLoad criteria, (err, objs) ->
        return callback(err) if err
        if objs.length is 1
          callback.call(objs[0], null, objs[0].allProperties())
        else
          callback.call(null, objs)

    ids: (ids, callback) ->
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

    index: (property, callback) ->
      if typeof property is "function"
        callback = property
        property = null

      model = @
      multi = Nohm.client.multi()
      affected_rows = 0
      old_unique = []
      new_unique = []
      @find (err, ids) =>
        return callback.call model, err, affected_rows if err or ids.length < 1
        ids.forEach (id, idx) =>
          @load id, (err, props) ->
            console.log id, @errors if err
            set_update = (prop) =>
              if @properties[prop].unique
                propLower = if @properties[prop].type is 'string' \
                  then @properties[prop].__oldValue.toLowerCase() \
                  else @properties[prop].__oldValue
                multi.setnx "#{Nohm.prefix.unique}#{@modelName}:#{prop}:#{@properties[prop].value}", id
              else
                @properties[prop].__updated = true

            if property
              set_update(property)
            else
              for p, def of @properties when def.index or def.unique
                set_update(p)

            @save (err) ->
              console.log "Indexed #{@modelName} on '#{property or 'all indexed properties'}' for row id #{@id}"
              affected_rows += 1
              if idx is ids.length - 1
                multi.exec()
                callback.call model, err, affected_rows

    deindex: (properties, callback) ->
      model = @
      multi = Nohm.client.multi()
      deletes = []
      if typeof properties is 'function'
        callback = properties
        properties = null
      properties = [properties] if typeof properties is 'string'
      unless properties
        ins = new model
        properties = []
        for p, def of ins.properties when def.index or def.unique
          properties.push p

      properties.forEach (p, idx) =>
        Nohm.client.keys "#{Nohm.prefix.unique}#{@modelName}:#{p}:*", (err, unique_keys) =>
          deletes = unique_keys
          Nohm.client.keys "#{Nohm.prefix.index}#{@modelName}:#{p}:*", (err, index_keys) =>
            deletes = deletes.concat index_keys
            Nohm.client.keys "#{Nohm.prefix.scoredindex}#{@modelName}:#{p}:*", (err, scoredindex_keys) =>
              deletes = deletes.concat scoredindex_keys

              if idx is properties.length - 1
                multi.del deletes if deletes.length > 0
                multi.exec (err, results) =>
                  console.log "Deleted #{deletes.length} related keys for '#{properties.join(', ')}' of #{@modelName}"
                  return callback.call model, err, deletes.length


    clean: (callback) ->
      model = new @
      multi = Nohm.client.multi()
      deletes = []
      affected_rows = 0
      undefined_properties = []
      @find (err, ids) =>
        return callback.call @, err, affected_rows if err or ids.length < 1
        ids.forEach (id, idx) =>
          @getClient().hgetall @getHashKey(id), (err, values) =>
            keys = if values then Object.keys(values) else []
            err = 'not found' unless Array.isArray(keys) and keys.length > 0 and not err

            if err
              Nohm.logError "loading a hash produced an error: #{err}"
              return callback?.call @, err

            # Delete unused properties
            for p of values
              is_enumerable = values.hasOwnProperty(p)
              is_meta = p is '__meta_version'
              is_property = model.properties.hasOwnProperty(p)
              if not is_meta and not model.properties.hasOwnProperty(p)
                affected_rows += 1
                if undefined_properties.indexOf(p) is -1
                  Nohm.logError "Undefined property '#{p}' found, will be deleted"
                  undefined_properties.push p
                multi.hdel @getHashKey(id), p

            # Delete unused index keys
            if idx is ids.length - 1
              return callback.call model, err, affected_rows unless undefined_properties.length > 0
              multi.exec (err, results) ->
                console.log "Cleaned up undefined properties #{undefined_properties.join(', ')}"
              @deindex undefined_properties, callback


  @_methods: null

  @middleware: ->
    express  = require 'express'
    assets   = require 'connect-assets'
    template = require 'fuyun-template'

    app = express()

    app.locals.title = "Nohm Backend"

    StatsHandler = (req, res, next) ->
      Nohm.client.info (err, result) ->
        res.locals.stats = result unless err
        next err

    CountHandler = (req, res, next) ->
        models = NohmExtend.getModels()
        total = Object.keys(models).length
        output = {}
        counter = 0
        _count = (name) ->
          model.count (err, count) ->
            counter += 1
            return next err if err
            output[name] = count
            if counter is total
              res.locals.count = output
              next()
        _count name for name, model of models

    app.configure ->
      app.set 'view engine', 'jade'
      app.set 'views', "#{__dirname}/../views"

      app.use express.favicon "#{__dirname}/../public/images/favicon.png"
      app.use express.compress()
      app.use express.methodOverride()
      app.use express.json strict: false
      app.use express.urlencoded()
      app.use express.cookieParser()
      app.use express.static "#{__dirname}/../public"

      app.use app.router

    app.on 'mount', (parent) ->

      parent.nohm_backend = app
      app.locals.base_uri = app.path()
      app.locals.models = JSON.stringify Object.keys NohmExtend.getModels()

      app.use assets
        src: "#{__dirname}/../public"
        helperContext: app.locals
        servePath: app.path()

      app.use NohmExtend.connect
        url: "/validator.js"
        namespace: 'validator'

      template.setup "app", prefix: "#{app.path()}/templates"
      template.attach app

      app.use "/templates", template.connect()

    app.get "/schema/:name", (req, res) ->
      return res.status 404 unless req.params.name
      schema = NohmExtend.getModels()[req.params.name]['properties']
      console.log schema
      res.send JSON.stringify schema

    app.get "/record/:model/page/:page", (req, res) ->
      return res.status 404 unless req.params.model
      page = req.params.page or 1
      number_per_page = 30
      model = NohmExtend.getModels()[req.params.name]
      model.sort
        field: 'created_at'
        direction: 'DESC'
        start: (page - 1) * number_per_page
        limit: number_per_page
      , (err, ids) ->
        return res.status 500 if err
        all = []
        counter = 0
        total = ids.length
        ids.forEach (id) ->
          model.load id, (err, props) ->
            counter += 1
            return if err
            props.id = @id
            all.push props
            if counter is total
              res.send all

        

      schema = NohmExtend.getModels()[req.params.name]['properties']
      console.log schema
      res.send JSON.stringify schema

    app.get "/stats", StatsHandler, (req, res) ->
      res.send JSON.stringify res.locals.stats

    app.get "/count", CountHandler, (req, res) ->
      res.send JSON.stringify res.locals.count

    app.get "/", StatsHandler, CountHandler, (req, res) ->
        res.render "layout", (err, html) ->
          return console.log err if err
          html = html.replace '{models}', JSON.stringify res.locals.count
          html = html.replace '{stats}', JSON.stringify res.locals.stats
          res.send html

  @listen: (server) ->
    ###
    io = require('socket.io') server

    io.configure ->
      io.enable 'browser client minification'
      io.enable 'browser client etag'
      io.enable 'browser client gzip'

      io.set 'origins = *'
      io.set 'log level', 1

    io.path '/nohm-extend'

    io.of('nohm-extend').on 'connection', (socket) ->
      socket.emit "hello"
    ###

module.exports = NohmExtend
