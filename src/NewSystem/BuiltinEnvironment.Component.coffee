_ = require "underscore"
NewSystem = require "./NewSystem"
Graphic = require "../Graphic/Graphic"


module.exports = (BuiltinEnvironment) ->

  BuiltinEnvironment.createVariantOfBuiltinSymbol "Component", "NodeWithAttributes",
    {
      label: "Component"

      graphicClass: Graphic.Component

      graphic: ->
        graphic = new @graphicClass()
        _.extend graphic, @getAttributesValuesByName()
        return graphic
    }

  BuiltinEnvironment.createVariantOfBuiltinSymbol "TransformComponent", "Component",
    {
      _devLabel: "TransformComponent"
      label: "Transform"

      matrix: ->
        {x, y, sx, sy, rotate} = @getAttributesValuesByName()
        return Util.Matrix.naturalConstruct(x, y, sx, sy, rotate)
      defaultAttributesToChange: ->
        {x, y} = @getAttributesByName()
        return [x, y]
      controllableAttributes: ->
        {x, y, sx, sy, rotate} = @getAttributesByName()
        return [x, y, sx, sy, rotate]
      controlPoints: ->
        {x, y, sx, sy} = @getAttributesByName()
        return [
          {point: [0, 0], attributesToChange: [x, y], filled: true}
          {point: [1, 0], attributesToChange: [sx], filled: false}
          {point: [0, 1], attributesToChange: [sy], filled: false}
        ]
    }
    [
      BuiltinEnvironment.changes_AddAttributeToParent(new NewSystem.NodeRef_Pointer("root"), "X", "x", "0.00")...
      BuiltinEnvironment.changes_AddAttributeToParent(new NewSystem.NodeRef_Pointer("root"), "Y", "y", "0.00")...
      BuiltinEnvironment.changes_AddAttributeToParent(new NewSystem.NodeRef_Pointer("root"), "Scale X", "sx", "1.00")...
      BuiltinEnvironment.changes_AddAttributeToParent(new NewSystem.NodeRef_Pointer("root"), "Scale Y", "sy", "1.00")...
      BuiltinEnvironment.changes_AddAttributeToParent(new NewSystem.NodeRef_Pointer("root"), "Rotate", "rotate", "0.00")...
    ]

  BuiltinEnvironment.createVariantOfBuiltinSymbol "FillComponent", "Component",
    {
      _devLabel: "FillComponent"
      label: "Fill"
      graphicClass: Graphic.Fill
    }
    [
      BuiltinEnvironment.changes_AddAttributeToParent(new NewSystem.NodeRef_Pointer("root"), "Fill Color", "color", "rgba(0.93, 0.93, 0.93, 1.00)")...
    ]

  BuiltinEnvironment.createVariantOfBuiltinSymbol "StrokeComponent", "Component",
    {
      _devLabel: "StrokeComponent"
      label: "Stroke"
      graphicClass: Graphic.Stroke
    }
    [
      BuiltinEnvironment.changes_AddAttributeToParent(new NewSystem.NodeRef_Pointer("root"), "Stroke Color", "color", "rgba(0.60, 0.60, 0.60, 1.00)")...
      BuiltinEnvironment.changes_AddAttributeToParent(new NewSystem.NodeRef_Pointer("root"), "Line Width", "lineWidth", "1")...
    ]
