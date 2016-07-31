_ = require "underscore"
NewSystem = require "./NewSystem"
Util = require "../Util/Util"
Dataflow = require "../Dataflow/Dataflow"
Model = require "../Model/Model"  # for non-nodes, like ParticularElement
Graphic = require "../Graphic/Graphic"


module.exports = (BuiltinEnvironment) ->
  BuiltinEnvironment.createVariantOfBuiltinSymbol "Element", "NodeWithAttributes",
    {
      label: "Element"

      isElement: ->
        true

      setUpElement: ->
        # Because the expanded properly is not inherited, it is initialized in
        # the constructor for every Element.
        @expanded = false

        # These methods need to be cells because we want to be able to call their
        # asSpread version. Note that we need to keep the original method around
        # (as the _version) so that inheritance doesn't try to make a cell out of
        # a cell.
        propsToCellify = [
          "graphic"
          "contextMatrix"
          "accumulatedMatrix"
        ]
        for prop in propsToCellify
          this[prop] = Dataflow.cell(this["_" + prop].bind(this))


      # ===========================================================================
      # Getters
      # ===========================================================================

      childElements: -> @childBundlesOfType('isElement')

      variables: -> @childBundlesOfType('isVariable')

      components: ->
        @childBundlesOfType('isComponent')

      # Includes attributes of components!
      allAttributes: ->
        result = []
        for variable in @variables()
          result.push(variable)
        for component in @components()
          for attribute in component.attributes()
            result.push(attribute)
        return result


      # ===========================================================================
      # Controlled Attributes
      # ===========================================================================

      controlledAttributes: ->
        controlledAttributes = []
        for controlledAttributeLink in @childBundlesOfType("isControlledAttributeLink")
          attribute = controlledAttributeLink.target()
          controlledAttributes.push(attribute)
        return controlledAttributes

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
        if @parentBundle()
          result.push(@parentBundle()._controllableAttributes()...)
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

      matrix: ->
        matrix = new Util.Matrix()
        for transform in @childBundlesOfType("isTransformComponent")
          matrix = matrix.compose(transform.matrix())
        return matrix

      _contextMatrix: ->
        parent = @parentBundle()
        if parent?.isElement?()
          return parent.accumulatedMatrix()
        else
          return new Util.Matrix()

      _accumulatedMatrix: ->
        return @contextMatrix().compose(@matrix())


      # ===========================================================================
      # Graphic
      # ===========================================================================

      _graphic: ->
        graphic = new @graphicClass()

        spreadEnv = Dataflow.currentSpreadEnv()
        graphic.particularElement = new Model.ParticularElement(@node.id, spreadEnv)

        graphic.matrix = @accumulatedMatrix()

        graphic.components = _.map @components(), (component) ->
          component.graphic()

        graphic.childGraphics = _.flatten(_.map(@childElements(), (element) ->
          element.allGraphics()
        ))

        return graphic

      allGraphics: ->
        return [] if @_isBeyondMaxDepth()
        result = @graphic.asSpread()
        if result instanceof Dataflow.Spread
          return result.flattenToArray()
        else
          return [result]

      _isBeyondMaxDepth: ->
        # This might want to be adjustable somewhere rather than hard coded here.
        return @depth() > 20
    }
    [
      {type: "RunConstructor", nodeId: "root", methodName: "setUpElement", methodArguments: []}
    ]

  BuiltinEnvironment.addCompoundChangeType "AddVariableToElement", ({elementId, variableCloneId}) ->
    [
      {type: "CloneSymbol", symbolId: "Variable", cloneId: variableCloneId}
      {type: "SetAttributeExpression", attributeId: NewSystem.buildId(variableCloneId, "root"), exprString: "0.00"}
      {type: "AddChild", parentId: "elementId", childId: "variableId", insertionIndex: Infinity}
    ]

  BuiltinEnvironment.addCompoundChangeType "AddControlledAttributeToElement", ({elementId, attributeId}) ->
    linkCloneId = Util.generateId()
    [
      {type: "CloneSymbolAndAddToParent", symbolId: "ControlledAttributeLink", cloneId: linkCloneId, parentId: elementId, insertionIndex: Infinity}
      {type: "SetOldSchoolLinkTarget", linkId: NewSystem.buildId(linkCloneId, "root"), linkTargetId: attributeId}
    ]

  BuiltinEnvironment.addAtomicChangeType "RemoveControlledAttributeFromElement", ({elementId, attributeId}, tree, environment) ->
    element = tree.getNodeById(elementId).bundle

    for controlledAttributeLink in element.childBundlesOfType("isControlledAttributeLink")
      curAttributeId = controlledAttributeLink.target().node.id
      if curAttributeId == attributeId
        tree.deparentNode(controlledAttributeLink.node.id)


  # Shape Interpretation Contexts
  RENDERING = 'renderingContext'
  ANCHOR_COLLECTION = 'anchorCollectionContext'
  NONE = 'noDraggingContext'

  BuiltinEnvironment.createVariantOfBuiltinSymbol "Shape", "Element",
    {
      label: "Shape"

      getAllowedShapeInterpretationContext: () ->
        return [RENDERING]

      getAllowedShapeInterpretationContextForChildren: () ->
        return [RENDERING]
    }
    [
      {type: "CloneSymbolAndAddToParent", parentId: "root", symbolId: "TransformComponent", cloneId: "transform"}
    ]

  BuiltinEnvironment.createVariantOfBuiltinSymbol "Group", "Shape",
    {
      label: "Group"
      getAllowedShapeInterpretationContext: () ->
        childElements = this.childElements()
        isRenderable = _.some(childElements, (child) ->
          _.some(child.getAllowedShapeInterpretationContext(), (shapeContext) -> shapeContext == RENDERING))

        if childElements.length == 0
          return [ANCHOR_COLLECTION, RENDERING]
        else if isRenderable
          return [RENDERING]
        else
          return [ANCHOR_COLLECTION]

      getAllowedShapeInterpretationContextForChildren: () ->
        if this._parent?.getAllowedShapeInterpretationContextForChildren
          return this._parent.getAllowedShapeInterpretationContextForChildren()
        else
          return [RENDERING]

      graphicClass: Graphic.Group
    }

  BuiltinEnvironment.createVariantOfBuiltinSymbol "Anchor", "Shape",
    label: "Anchor"

    getAllowedShapeInterpretationContext: () ->
      return [ANCHOR_COLLECTION]

    getAllowedShapeInterpretationContextForChildren: () ->
      return [NONE]

    graphicClass: Graphic.Anchor

  BuiltinEnvironment.addCompoundChangeType "AddAnchorToParent", ({parentId, anchorCloneId, x, y}) ->
    anchorId = NewSystem.buildId(anchorCloneId, "root")
    xId = NewSystem.buildId(anchorCloneId, "transform", "x", "root")
    yId = NewSystem.buildId(anchorCloneId, "transform", "y", "root")

    [
      {type: "CloneSymbolAndAddToParent", parentId: parentId, symbolId: "Anchor", cloneId: anchorCloneId}
      {type: "SetAttributeExpression", attributeId: xId, exprString: x, references: {}}
      {type: "SetAttributeExpression", attributeId: yId, exprString: y, references: {}}
    ]

  BuiltinEnvironment.createVariantOfBuiltinSymbol "Path", "Shape",
    {
      label: "Path"
      graphicClass: Graphic.Path
    }
    [
      {type: "CloneSymbolAndAddToParent", parentId: "root", symbolId: "PathComponent", cloneId: "path"}
      {type: "CloneSymbolAndAddToParent", parentId: "root", symbolId: "FillComponent", cloneId: "fill"}
      {type: "CloneSymbolAndAddToParent", parentId: "root", symbolId: "StrokeComponent", cloneId: "stroke"}
    ]

  BuiltinEnvironment.createVariantOfBuiltinSymbol "Circle", "Path",
    {
      label: "Circle"
      getAllowedShapeInterpretationContextForChildren: () ->
        return [NONE]
      graphicClass: Graphic.Circle
    }

  BuiltinEnvironment.createVariantOfBuiltinSymbol "Rectangle", "Path",
    {
      label: "Rectangle"
      getAllowedShapeInterpretationContextForChildren: () ->
        return [ANCHOR_COLLECTION]
    }
    [
      {type: "AddAnchorToParent", parentId: "root", anchorCloneId: "1", x: "0.00", y: "0.00"}
      {type: "AddAnchorToParent", parentId: "root", anchorCloneId: "2", x: "0.00", y: "1.00"}
      {type: "AddAnchorToParent", parentId: "root", anchorCloneId: "3", x: "1.00", y: "1.00"}
      {type: "AddAnchorToParent", parentId: "root", anchorCloneId: "4", x: "1.00", y: "0.00"}
    ]

  BuiltinEnvironment.createVariantOfBuiltinSymbol "Text", "Shape",
    {
      label: "Text"
      getAllowedShapeInterpretationContextForChildren: () ->
        return [NONE]
      graphicClass: Graphic.Text
    }
    [
      {type: "CloneSymbolAndAddToParent", parentId: "root", symbolId: "TextComponent", cloneId: "text"}
    ]
