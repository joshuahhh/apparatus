_ = require "underscore"
Node = require "./Node"
Link = require "./Link"
Model = require "./Model"
Dataflow = require "../Dataflow/Dataflow"
Monadic = require "../Dataflow/Monadic"
Spread = Monadic.Spread
Util = require "../Util/Util"


module.exports = Element = Node.createVariant
  label: "Element"

  constructor: ->
    # Call "super" constructor
    Node.constructor.apply(this, arguments)

    # Because the expanded properly is not inherited, it is initialized in
    # the constructor for every Element.
    @expanded = false

    # These methods need to be cells because we want to be able to call their
    # asSpread version. Note that we need to keep the original method around
    # (as the _version) so that inheritance doesn't try to make a cell out of
    # a cell.
    propsToCellify = [
      "graphic"
    ]
    for prop in propsToCellify
      this['__' + prop + 'Cell'] = new Dataflow.Cell(this["_" + prop + 'Fn'].bind(this), 'element ' + prop)
      this[prop] = do (prop) -> -> this['__' + prop + 'Cell'].run()
      this[prop + 'AsSpread'] = do (prop) -> -> this['__' + prop + 'Cell'].asSpread()

  # viewMatrix determines the pan and zoom of an Element. It is only used for
  # Elements that can be a Project.editingElement (i.e. Elements within the
  # create panel). The default is zoomed to 100 pixels per unit.
  viewMatrix: new Util.Matrix(100, 0, 0, 100, 0, 0)

  _setParent: (parent) ->
    # Call "super" _setParent
    Node._setParent.apply(this, arguments)

    # Rewire contextMatrix to depend on the right parent matrix
    if parent and parent.isVariantOf(Element)
      @contextMatrixAttribute().setReferences
        parentAccumulatedMatrix: parent.accumulatedMatrixAttribute()
    else
      @contextMatrixAttribute().setReferences {}  # no parentAccumulatedMatrix

  # ===========================================================================
  # Getters
  # ===========================================================================

  childElements: -> @childrenOfType(Element)

  variables: -> @childrenOfType(Model.Variable)

  components: -> @childrenOfType(Model.Component)

  attributes: ->
    result = []
    for variable in @variables()
      result.push(variable)
    for component in @components()
      for attribute in component.attributes()
        result.push(attribute)
    return result


  # ===========================================================================
  # Actions
  # ===========================================================================

  addVariable: ->
    variable = Model.Variable.createVariant()
    variable.setExpression("0.00")
    @addChild(variable)
    return variable


  # ===========================================================================
  # Controlled Attributes
  # ===========================================================================

  controlledAttributes: ->
    controlledAttributes = []
    for controlledAttributeLink in @childrenOfType(Model.ControlledAttributeLink)
      attribute = controlledAttributeLink.target()
      controlledAttributes.push(attribute)
    return controlledAttributes

  addControlledAttribute: (attributeToAdd) ->
    controlledAttributeLink = Model.ControlledAttributeLink.createVariant()
    controlledAttributeLink.setTarget(attributeToAdd)
    @addChild(controlledAttributeLink)

  removeControlledAttribute: (attributeToRemove) ->
    for controlledAttributeLink in @childrenOfType(Model.ControlledAttributeLink)
      attribute = controlledAttributeLink.target()
      if attribute == attributeToRemove
        @removeChild(controlledAttributeLink)

  isController: ->
    return @controlledAttributes().length > 0

  # An implicitly controlled attribute is a controlled attribute or a
  # dependency of a controlled attribute.
  implicitlyControlledAttributes: ->
    return @allDependencies(@controlledAttributes())

  # A controllable attribute is one which, if changed, would affect my
  # geometry. Thus all attributes within Transform components, their
  # dependencies, as well as all controllable attributes up my parent chain.
  controllableAttributes: ->
    _.unique(@_controllableAttributes())
  _controllableAttributes: ->
    result = []
    for component in @components()
      continue unless component.controllableAttributes?
      for attribute in component.controllableAttributes()
        result.push(attribute)
        result.push(attribute.dependencies()...)
    if @parent()
      result.push(@parent()._controllableAttributes()...)
    return result


  # ===========================================================================
  # Attributes to change
  # ===========================================================================

  attributesToChange: ->
    attributesToChange = @implicitlyControlledAttributes()
    if attributesToChange.length == 0
      attributesToChange = @defaultAttributesToChange()
    attributesToChange = @onlyNumbers(attributesToChange)
    return attributesToChange

  defaultAttributesToChange: ->
    result = []
    for component in @components()
      continue unless component.defaultAttributesToChange?
      result.push(component.defaultAttributesToChange()...)
    return result


  # ===========================================================================
  # Control Points
  # ===========================================================================

  controlPoints: ->
    result = []
    for component in @components()
      continue unless component.controlPoints?
      controlPoints = component.controlPoints()
      for controlPoint in controlPoints
        attributesToChange = controlPoint.attributesToChange
        attributesToChange = @allDependencies(attributesToChange)
        attributesToChange = @onlyNumbers(attributesToChange)
        controlPoint.attributesToChange = attributesToChange
      result.push(controlPoints...)
    return result


  # ===========================================================================
  # Attribute List Helpers
  # ===========================================================================

  allDependencies: (attributes) ->
    result = []
    for attribute in attributes
      result.push(attribute)
      result.push(attribute.dependencies()...)
    return _.unique(result)

  onlyNumbers: (attributes) ->
    _.filter attributes, (attribute) ->
      attribute.isNumber()


  # ===========================================================================
  # Geometry
  # ===========================================================================

  matrixAttribute: ->
    @childOfType(Model.Transform).getAttributesByName().matrix

  matrix: ->
    @matrixAttribute().value()

  contextMatrixAttribute: ->
    @childOfType(Model.Transform).getAttributesByName().contextMatrix

  contextMatrix: ->
    @contextMatrixAttribute().value()

  contextMatrixAsSpread: ->
    @contextMatrixAttribute().valueCell().asSpread()

  accumulatedMatrixAttribute: ->
    @childOfType(Model.Transform).getAttributesByName().accumulatedMatrix

  accumulatedMatrix: ->
    @accumulatedMatrixAttribute().value()

  accumulatedMatrixAsSpread: ->
    @accumulatedMatrixAttribute().valueCell().asSpread()


  # ===========================================================================
  # Graphic
  # ===========================================================================

  particularElementSpread: ->
    Spread.multimap [@accumulatedMatrixSpread(), @contextMatrixSpread()], (accumulatedMatrix, contextMatrix, spreadEnv) =>
      new Model.ParticularElement2(this, accumulatedMatrixSpread, contextMatrix)

  allComponentGraphicsSpread: ->
    componentGraphicSpreads = @components().map (component) -> component.graphic()
    return Spread.product(componentGraphicSpreads)

  # This fella should return a tree-spread of Graphics.
  _graphicFn: ->
    # NEXT STEP: Implement graphic in a way which works for spreads, but isn't necessarily an attribute
    # (Then we can work on making it an attribute if we want)

    allComponentGraphicsSpread = @allComponentGraphicsSpread()
    childElementGraphicsSpreads = @childElements().map (childElement) -> childElement.graphic()

    return allComponentGraphicsSpread.multimap2WithTrees(
      childElementGraphicsSpreads,
      (allComponentGraphics, childElementGraphics) =>
        graphic = new @graphicClass()

        graphic.components = allComponentGraphics
        graphic.childGraphicSpreads = childElementGraphics

        return graphic
    )

  allGraphics: ->
    throw new Error('THIS METHOD IS CAPUT EXCEPT REMEMBER RECURSION STUFF')

    return [] if @_isBeyondMaxDepth()
    result = @graphicAsSpread()
    if result instanceof Dataflow.Spread
      return result.flattenToArray()
    else
      return [result]

  _isBeyondMaxDepth: ->
    # This might want to be adjustable somewhere rather than hard coded here.
    return @depth() > 20
