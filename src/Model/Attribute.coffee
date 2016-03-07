_ = require "underscore"
Util = require "../Util/Util"
Dataflow = require "../Dataflow/Dataflow"
Monadic = require "../Dataflow/Monadic"
Spread = Monadic.Spread
Evaluator = require "../Evaluator/Evaluator"
Node = require "./Node"
Model = require "./Model"


module.exports = Attribute = Node.createVariant
  label: "Attribute"

  constructor: ->
    # Call "super" constructor
    Node.constructor.apply(this, arguments)

    @__valueCell = new Dataflow.Cell(@_value.bind(this), @dependerCells.bind(this))

  valueCell: ->
    @__valueCell

  value: ->
    @valueCell().run()

  _evaluate: (referenceValues) ->
    throw new Error("Not implemented")

  # Returns [false] if there's no quick evaluation, or [true, easyValue].
  _easyEvaluate: ->
    [false]

  _value: ->
    [hasEasyValue, easyValue] = @_easyEvaluate()
    return Spread.fromValue(easyValue) if hasEasyValue

    if (circularReferencePath = @circularReferencePath())?
      return new CircularReferenceError(circularReferencePath)

    referenceValues = _.mapObject @references(), (referenceAttribute) ->
      referenceAttribute.value()

    try
      return Spread.flexibind(referenceValues, (args) => @_evaluate(args))
    catch error
      throw error
      # if error instanceof Dataflow.UnresolvedSpreadError
      #   # This is legit uncool.
      #   throw error
      # else
      #   # This is a user error.
      #   return error

  setReferences: (references) ->
    # Remove all existing reference links
    for referenceLink in @childrenOfType(Model.ReferenceLink)
      referenceLink.deregisterFromTarget()
      @removeChild(referenceLink)

    @addReferences(references)

    # Invalidate the value cell
    @valueCell().invalidate()

  addReferences: (references) ->
    # Create appropriate reference links
    for own key, reference of references
      @addReference(key, reference)

  addReference: (key, reference) ->
    referenceLink = Model.ReferenceLink.createVariant()
    referenceLink.key = key
    referenceLink.setTarget(reference)
    @addChild(referenceLink)

    @valueCell().invalidate()

  references: ->
    references = {}
    for referenceLink in @childrenOfType(Model.ReferenceLink)
      key = referenceLink.key
      attribute = referenceLink.target()
      references[key] = attribute
    return references

  hasReferences: -> _.any(@references(), -> true)

  isNumber: ->
    false

  isTrivial: ->
    # TODO
    return @isNumber()

  isNovel: ->
    false

  # Descends through all recursively referenced attributes. An object is
  # returned with two properties:
  #   dependencies: array consisting of the set of all recursive dependencies
  #     (will be reasonable even if a circular reference exists)
  #   circularReferencePath: a chain of dependencies resulting in a circular
  #     reference, if one exists, or null
  _analyzeDependencies: ->
    dependencies = []

    attributePath = []
    circularReferencePath = null

    recurse = (attribute) ->
      attributePath.push(attribute)
      # Detect circular references, and don't get trapped
      if attributePath.indexOf(attribute) != attributePath.length - 1
        circularReferencePath ?= attributePath.slice()
      else
        for referenceAttribute in _.values(attribute.references())
          dependencies.push(referenceAttribute)
          recurse(referenceAttribute)
      attributePath.pop()

    recurse(this)

    dependencies = _.unique(dependencies)

    return {
      dependencies
      circularReferencePath
    }

  # Returns all referenced attributes recursively. In other words every
  # attribute which, if it changed, would affect me.
  dependencies: ->
    return @_analyzeDependencies().dependencies

  # If there is a circular reference in the attribute's dependency graph,
  # returns a chain of dependencies representing it. Otherwise returns null.
  circularReferencePath: ->
    return @_analyzeDependencies().circularReferencePath

  parentElement: ->
    result = @parent()
    until result.isVariantOf(Model.Element)
      result = result.parent()
    return result

  dependerCells: ->
    incomingReferenceLinks = @incomingLinksOfType(Model.ReferenceLink)
    return incomingReferenceLinks.map((link) -> link.parent().valueCell())

Attribute.ExpressionAttribute = Attribute.createVariant
  label: "ExpressionAttribute"

  _easyEvaluate: ->
    if @isNumber()
      return [true, parseFloat(@exprString)]
    return [false]

  _evaluate: (referenceValues) ->
    if @_isDirty()
      @_updateCompiledExpression()

    @__compiledExpression.evaluate(referenceValues)

  _isDirty: ->
    return true if !@hasOwnProperty("__compiledExpression")
    return true if @__compiledExpression.exprString != @exprString
    return false

  _updateCompiledExpression: ->
    compiledExpression = new CompiledExpression(this)
    if compiledExpression.isSyntaxError
      compiledExpression.fn = @__compiledExpression?.fn ? -> new Error("Syntax error")
    @__compiledExpression = compiledExpression

  isNumber: ->
    return Util.isNumberString(@exprString)

  isNovel: ->
    @hasOwnProperty("exprString")

  setExpression: (exprString, references={}) ->
    @exprString = String(exprString)
    @setReferences(references)


Attribute.InternalAttribute = Attribute.createVariant
  label: "InternalAttribute"

  _evaluate: (referenceValues) ->
    @internalFunction(referenceValues)

class CompiledExpression
  constructor: (@attribute) ->
    @exprString = @attribute.exprString
    @referenceKeys = _.keys(@attribute.references())

    if @exprString == ""
      @_setSyntaxError()
      return

    if Util.isNumberString(@exprString)
      value = parseFloat(@exprString)
      @_setConstant(value)
      return

    wrapped = @_wrapped()
    try
      compiled = Evaluator.evaluate(wrapped)
    catch error
      @_setSyntaxError()
      return

    if @referenceKeys.length == 0
      try
        value = compiled()
      catch error
        @_setConstant(error)
        return
      @_setConstant(value)
      return

    @_setFn(compiled)

  _setSyntaxError: ->
    @isSyntaxError = true

  _setConstant: (value) ->
    @isConstant = true
    @fn = -> value

  _setFn: (fn) ->
    @fn = fn

  evaluate: (referenceValues) ->
    return @fn(referenceValues)

  _wrapped: ->
    result    = "'use strict';\n"
    result   += "(function ($$$referenceValues) {\n"

    for referenceKey in @referenceKeys
      result += "  var #{referenceKey} = $$$referenceValues.#{referenceKey};\n"

    if @exprString.indexOf("return") == -1
      result += "  return #{@exprString};\n"
    else
      result += "\n\n#{@exprString}\n\n"

    result   += "});"
    return result

Attribute.CircularReferenceError = class CircularReferenceError extends Error
  constructor: (@attributePath) ->
    labels = _.pluck(@attributePath, 'label')
    @message = "Circular reference: #{labels.join(' -> ')}"
