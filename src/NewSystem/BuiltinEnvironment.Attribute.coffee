_ = require "underscore"
NewSystem = require "./NewSystem"
Util = require "../Util/Util"
Dataflow = require "../Dataflow/Dataflow"
Evaluator = require "../Evaluator/Evaluator"


module.exports = (BuiltinEnvironment) ->
  BuiltinEnvironment.createVariantOfBuiltinSymbol "Attribute", "Node",
    {
      label: "Attribute"

      isAttribute: ->
        true

      setUpAttribute: ->
        @value = Dataflow.cell(@_value.bind(this))

      _value: ->
        # Optimization
        if @isNumber()
          return parseFloat(@exprString)

        if @_isDirty()
          @_updateCompiledExpression()

        if (circularReferencePath = @circularReferencePath())?
          return new CircularReferenceError(circularReferencePath)

        referenceValues = _.mapObject @references(), (referenceAttribute) ->
          referenceAttribute.bundle.value()

        try
          return @__compiledExpression.evaluate(referenceValues)
        catch error
          if error instanceof Dataflow.UnresolvedSpreadError
            throw error
          else
            return error

      _isDirty: ->
        return true if !@hasOwnProperty("__compiledExpression")
        return true if @__compiledExpression.exprString != @exprString
        return false

      _updateCompiledExpression: ->
        compiledExpression = new CompiledExpression(this)
        if compiledExpression.isSyntaxError
          compiledExpression.fn = @__compiledExpression?.fn ? -> new Error("Syntax error")
        @__compiledExpression = compiledExpression

      references: ->
        # console.log('references is', @node.linkTargetNodes())
        @node.linkTargetNodes()

      hasReferences: ->
        _.any(@references(), -> true)

      isNumber: ->
        return Util.isNumberString(@exprString)

      isTrivial: ->
        # TODO
        return @isNumber()

      isNovel: ->
        @hasOwnProperty("exprString")

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
          # console.log('recurse', attribute)
          attributePath.push(attribute)
          # Detect circular references, and don't get trapped
          if attributePath.indexOf(attribute) != attributePath.length - 1
            circularReferencePath ?= attributePath.slice()
          else
            for referenceAttribute in _.values(attribute.bundle.references())
              dependencies.push(referenceAttribute)
              recurse(referenceAttribute)
          attributePath.pop()

        recurse(this.node)

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
        until result.isElement?()
          result = result.parent()
        return result
    }
    [
      new NewSystem.Change_RunConstructor(
        new NewSystem.NodeRef_Pointer("root"),
        "setUpAttribute")
    ]

  BuiltinEnvironment.change_SetAttributeExpression = (attributeRef, exprString, references = {}) ->
    changes = []

    changes.push(new NewSystem.Change_ExtendNodeWithLiteral(attributeRef, {exprString: String(exprString)}))

    # Remove all existing reference links
    changes.push(new NewSystem.Change_RemoveAllLinks(attributeRef))

    # Create appropriate reference links
    for own linkKey, attribute of references
      # console.log('REFERENCE RECEIVED:', linkKey, 'TO', attribute.id)
      changes.push(new NewSystem.Change_SetNodeLinkTarget(attributeRef, linkKey, new NewSystem.NodeRef_Node(attribute.id)))

    return changes

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

      compiled = @_wrapFunctionInSpreadCheck(compiled)

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

    _wrapFunctionInSpreadCheck: (fn) ->
      return =>
        result = fn(arguments...)
        if result instanceof Dataflow.Spread
          result.origin = @attribute
        return result

  BuiltinEnvironment.CircularReferenceError = class CircularReferenceError extends Error
    constructor: (@attributePath) ->
      labels = _.pluck(@attributePath, 'label')
      @message = "Circular reference: #{labels.join(' -> ')}"
