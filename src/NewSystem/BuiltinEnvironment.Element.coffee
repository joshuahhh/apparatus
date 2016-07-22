_ = require "underscore"
NewSystem = require "./NewSystem"
Util = require "../Util/Util"
Dataflow = require "../Dataflow/Dataflow"
Model = require "../Model/Model"  # for non-nodes, like ParticularElement
Graphic = require "../Graphic/Graphic"


module.exports = (BuiltinEnvironment) ->
  BuiltinEnvironment.createVariantOfBuiltinSymbol "Element", "NodeWithAttributes",
    {
      label: "Attribute"

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

      # viewMatrix determines the pan and zoom of an Element. It is only used for
      # Elements that can be a Project.editingElement (i.e. Elements within the
      # create panel). The default is zoomed to 100 pixels per unit.
      viewMatrix: new Util.Matrix(100, 0, 0, 100, 0, 0)


      # ===========================================================================
      # Getters
      # ===========================================================================

      childElements: -> @node.childNodesOfType('isElement')

      variables: -> @node.childNodesOfType('isVariable')

      components: -> @node.childNodesOfType('isComponent')

      # Includes attributes of components!
      allAttributes: ->
        result = []
        for variable in @variables()
          result.push(variable)
        for component in @components()
          for attribute in component.bundle.attributes()
            result.push(attribute)
        return result


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

      matrix: ->
        matrix = new Util.Matrix()
        for transform in @childrenOfType(Model.Transform)
          matrix = matrix.compose(transform.matrix())
        return matrix

      _contextMatrix: ->
        parent = @parent()
        if parent and parent.isVariantOf(Element)
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
        graphic.particularElement = new Model.ParticularElement(this, spreadEnv)

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
      new NewSystem.Change_RunConstructor(
        new NewSystem.NodeRef_Pointer("root"),
        "setUpElement")
    ]

  BuiltinEnvironment.changes_AddVariableToElement = (elementRef, variableCloneId) ->
    variableRef = new NewSystem.NodeRef_Pointer(variableCloneId + "/root")

    [
      new NewSystem.Change_CloneSymbol("Variable", variableCloneId)
      BuiltinEnvironment.changes_SetAttributeExpression(variableRef, "0.00")...
      new NewSystem.Change_AddChild(elementRef, variableRef, Infinity)
    ]

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
      BuiltinEnvironment.changes_CloneSymbolAndAddToRoot("TransformComponent", "transform")...
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

  BuiltinEnvironment.changes_AddAnchorToParent = (parentRef, anchorCloneId, x, y) ->
    anchorRef = new NewSystem.NodeRef_Pointer(anchorCloneId + "/root")
    xRef = new NewSystem.NodeRef_Pointer(anchorCloneId + "/master/transform/x/root")
    yRef = new NewSystem.NodeRef_Pointer(anchorCloneId + "/master/transform/y/root")

    [
      new NewSystem.Change_CloneSymbol("Anchor", anchorCloneId)
      BuiltinEnvironment.changes_SetAttributeExpression(xRef, x)...
      BuiltinEnvironment.changes_SetAttributeExpression(yRef, y)...
      new NewSystem.Change_AddChild(parentRef, anchorRef, Infinity)
    ]

  BuiltinEnvironment.createVariantOfBuiltinSymbol "PathComponent", "Component",
    {
      _devLabel: "PathComponent"
      label: "Path"
      graphicClass: Graphic.PathComponent
    }
    [
      BuiltinEnvironment.changes_AddAttributeToParent(new NewSystem.NodeRef_Pointer("root"), "Close Path", "closed", "true")...
    ]

  BuiltinEnvironment.createVariantOfBuiltinSymbol "Path", "Shape",
    {
      label: "Path"
      graphicClass: Graphic.Path
    }
    [
      BuiltinEnvironment.changes_CloneSymbolAndAddToRoot("PathComponent", "path")...
      BuiltinEnvironment.changes_CloneSymbolAndAddToRoot("FillComponent", "fill")...
      BuiltinEnvironment.changes_CloneSymbolAndAddToRoot("StrokeComponent", "stroke")...
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
      BuiltinEnvironment.changes_AddAnchorToParent(new NewSystem.NodeRef_Pointer("root"), "1", "0.00", "0.00")...
      BuiltinEnvironment.changes_AddAnchorToParent(new NewSystem.NodeRef_Pointer("root"), "2", "0.00", "1.00")...
      BuiltinEnvironment.changes_AddAnchorToParent(new NewSystem.NodeRef_Pointer("root"), "3", "1.00", "1.00")...
      BuiltinEnvironment.changes_AddAnchorToParent(new NewSystem.NodeRef_Pointer("root"), "4", "1.00", "0.00")...
    ]

  #
  # Model.TextComponent = Model.Component.createVariant
  #   _devLabel: "TextComponent"
  #   label: "Text"
  #   getAllowedShapeInterpretationContextForChildren: () ->
  #     return [NONE]
  #
  #   graphicClass: Graphic.TextComponent
  #
  # Model.TextComponent.addChildren [
  #   createAttribute("Text", "text", '"Text"')
  #   createAttribute("Font", "fontFamily", '"Lucida Grande"')
  #   createAttribute("Color", "color", "rgba(0.20, 0.20, 0.20, 1.00)")
  #   createAttribute("Align", "textAlign", '"start"')
  #   createAttribute("Baseline", "textBaseline", '"alphabetic"')
  # ]
  #
  # Model.Text = Model.Shape.createVariant
  #   label: "Text"
  #   graphicClass: Graphic.Text
  #
  # Model.Text.addChildren [
  #   Model.TextComponent.createVariant()
  # ]
