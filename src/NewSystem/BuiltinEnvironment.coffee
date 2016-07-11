_ = require "underscore"
NewSystem = require "./NewSystem"


module.exports = BuiltinEnvironment = new NewSystem.Environment()

# IDEA: Compiled tree goes through one ADDITIONAL step, to produce a tree
# structure which is totally separated from the whole change-log system (and
# which is possibly 100% compatible with existing Apparatus rendering code.)

# (Why? Currently, compiled trees are designed to fit into the change-log
# system. They're designed to be easy to clone, and they have pointers and stuff
# like that. These needs are separate from the needs of Apparatus rendering.)


# Root "Node" of the Apparatus object model.
Node = new NewSystem.Symbol(new NewSystem.ChangeList([
  new NewSystem.Change_AddNode("root"),
  new NewSystem.Change_SetPointerDestination("root", new NewSystem.NodeRef_Node("root")),
]))
BuiltinEnvironment.addSymbol("Node", Node)

# Helper methods for nodes which have attributes attached.
BuiltinEnvironment.createVariantOfBuiltinSymbol(
  "NodeWithAttributes",
  "Node",
  {
    label: "Node With Attributes"

    attributes: ->
      @childrenOfType(Model.Attribute)

    getAttributesByName: ->
      _.indexBy @attributes(), "name"

    getAttributesValuesByName: ->
      _.mapObject @getAttributesByName(), (attr) -> attr.value()
  }
)

BuiltinEnvironment.createVariantOfBuiltinSymbol(
  "Link",
  "Node",
  {
    label: "Link"

    # setTarget: (@_target) ->

    target: ->
  }
)

BuiltinEnvironment.createVariantOfBuiltinSymbol(
  "Attribute",
  "Node",
  {
    label: "Attribute"

    constructor: ->
      # Call "super" constructor
      Node.constructor.apply(this, arguments)

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
        referenceAttribute.value()

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

    setExpression: (exprString, references={}) ->
      @exprString = String(exprString)

      # Remove all existing reference links
      for referenceLink in @childrenOfType(Model.ReferenceLink)
        @removeChild(referenceLink)

      # Create appropriate reference links
      for own key, attribute of references
        referenceLink = Model.ReferenceLink.createVariant()
        referenceLink.key = key
        referenceLink.setTarget(attribute)
        @addChild(referenceLink)

    references: ->
      references = {}
      for referenceLink in @childrenOfType(Model.ReferenceLink)
        key = referenceLink.key
        attribute = referenceLink.target()
        references[key] = attribute
      return references

    hasReferences: -> _.any(@references(), -> true)

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
  }
)
