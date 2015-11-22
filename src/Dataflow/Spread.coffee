_ = require "underscore"


# A spread is an array annotated with an origin (a Model.Attribute).

module.exports = class Spread
  constructor: (@items, @origin) ->

  # Recursively converts a spread to an array. So if I'm a nested spread,
  # toArray will return a nested array.
  toArray: ->
    _.map @items, (item) ->
      if item instanceof Spread
        item.toArray()
      else
        item

  flattenToArray: ->
    _.flatten(@toArray())
