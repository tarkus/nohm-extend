if module.parent?
  {Nohm} = module.parent.require 'nohm'
else
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
      conn = Nohm.client
      affected_rows = 0
      @find (err, ids) =>
        return callback.call model, err, affected_rows if err or ids.length < 1
        ids.forEach (id, idx) =>
          @load id, (err, props) ->
            console.log @errors if err
            if property
              @properties[property].__updated = true
            else
              for p, def of @properties when def.index or def.unique
                @properties[p].__updated = true
                if @__inDB
                  propLower = if @properties[p].type is 'string' \
                    then @properties[p].__oldValue.toLowerCase() \
                    else @properties[p].__oldValue
                  conn.del "#{Nohm.prefix.unique}#{@modelName}:#{p}:#{propLower}", Nohm.logError
            @save (err) ->
              console.log @errors if err
              console.log "Indexed #{@modelName} on '#{property or 'all indexed properties'}' for row id #{@id}"
              affected_rows += 1
              callback.call model, err, affected_rows if idx is ids.length - 1

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
              @unindex undefined_properties, callback


  @_methods: null


module.exports = NohmExtend
