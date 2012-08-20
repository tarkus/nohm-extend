{Nohm} = require 'nohm'
NohmExtend = require('../lib/nohm-extend')

class MyNohm extends NohmExtend

  @extends:
    dummy: ->

  @methods:

    saveMyDay: ->


module.exports = MyNohm
