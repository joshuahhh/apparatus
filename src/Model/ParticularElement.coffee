_ = require "underscore"
Dataflow = require "../Dataflow/Dataflow"


# A ParticularElement is an Element together with a spread environment to
# specify what the index values are for its Element's spreads.
module.exports = class ParticularElement
  constructor: (@element, @spreadEnv) ->
    @spreadEnv ?= {}

  # isEqualTo: (particularElement) ->
  #   return @element == particularElement.element and
  #     @spreadEnv.isEqualTo(particularElement.spreadEnv)

  # This is probably used!
  isAncestorOf: (particularElement) ->
    return @element.isAncestorOf(particularElement.element) and
      _.isMatch(@spreadEnv, particularElement.spreadEnv)
