_ = require "underscore"

# A DynamicScope object is just a dictionary which you can temporarily extend
# for the duration of a function call and which restores itself afterwards.

module.exports = class DynamicScope
  constructor: (@context={}) ->

  with: (newContext, fn) ->
    previousContext = @context
    @_updateContext(previousContext, newContext)

    try
      result = fn()
    finally
      @context = previousContext
    return result

  _updateContext: (previousContext, newContext) ->
    @context = newContext
    for own key, value of previousContext
      @context[key] = value unless @context.hasOwnProperty(key)
