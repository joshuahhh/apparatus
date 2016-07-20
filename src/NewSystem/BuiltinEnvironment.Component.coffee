_ = require "underscore"
NewSystem = require "./NewSystem"
Graphic = require "../Graphic/Graphic"


changes_AddAttribute = (parentRef, label, name, exprString) ->
  attributeRef = new NewSystem.NodeRef_Pointer(name + "/root")

  [
    new NewSystem.Change_CloneSymbol("Attribute", name)
    new NewSystem.Change_ExtendNodeWithLiteral(attributeRef, {label: label, name: name})
    new NewSystem.Change_AddChild(parentRef, attributeRef)
  ]


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

  BuiltinEnvironment.createVariantOfBuiltinSymbol "Transform", "Component",
    {
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
      changes_AddAttribute(new NewSystem.NodeRef_Pointer("root"), "X", "x", "0.00")...
      changes_AddAttribute(new NewSystem.NodeRef_Pointer("root"), "Y", "y", "0.00")...
      changes_AddAttribute(new NewSystem.NodeRef_Pointer("root"), "Scale X", "sx", "1.00")...
      changes_AddAttribute(new NewSystem.NodeRef_Pointer("root"), "Scale Y", "sy", "1.00")...
      changes_AddAttribute(new NewSystem.NodeRef_Pointer("root"), "Rotate", "rotate", "0.00")...
    ]

  BuiltinEnvironment.createVariantOfBuiltinSymbol "Fill", "Component",
    {
      label: "Fill"
      graphicClass: Graphic.Fill
    }
    [
      changes_AddAttribute(new NewSystem.NodeRef_Pointer("root"), "Fill Color", "color", "rgba(0.93, 0.93, 0.93, 1.00)")...
    ]

  BuiltinEnvironment.createVariantOfBuiltinSymbol "Stroke", "Component",
    {
      label: "Stroke"
      graphicClass: Graphic.Stroke
    }
    [
      changes_AddAttribute(new NewSystem.NodeRef_Pointer("root"), "Stroke Color", "color", "rgba(0.60, 0.60, 0.60, 1.00)")...
      changes_AddAttribute(new NewSystem.NodeRef_Pointer("root"), "Line Width", "lineWidth", "1")...
    ]
