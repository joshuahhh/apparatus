module.exports = class HoverManager
  constructor: ->
    @hoveredParticularElement = null
    @doubleHoveredParticularElement = null
    @controllerParticularElement = null
    @attributesToChange = []
    @hoveredAttribute = null
