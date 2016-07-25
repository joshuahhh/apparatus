_ = require "underscore"
NewSystem = require "./NewSystem"
Graphic = require "../Graphic/Graphic"
Util = require "../Util/Util"


module.exports = (BuiltinEnvironment) ->

  BuiltinEnvironment.createVariantOfBuiltinSymbol "Component", "NodeWithAttributes",
    {
      label: "Component"

      isComponent: ->
        true

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

      isTransformComponent: ->
        true

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
      BuiltinEnvironment.changes_AddAttributeToParent("root", "X", "x", "0.00")...
      BuiltinEnvironment.changes_AddAttributeToParent("root", "Y", "y", "0.00")...
      BuiltinEnvironment.changes_AddAttributeToParent("root", "Scale X", "sx", "1.00")...
      BuiltinEnvironment.changes_AddAttributeToParent("root", "Scale Y", "sy", "1.00")...
      BuiltinEnvironment.changes_AddAttributeToParent("root", "Rotate", "rotate", "0.00")...
    ]

  BuiltinEnvironment.createVariantOfBuiltinSymbol "FillComponent", "Component",
    {
      _devLabel: "FillComponent"
      label: "Fill"
      graphicClass: Graphic.FillComponent
    }
    [
      BuiltinEnvironment.changes_AddAttributeToParent("root", "Fill Color", "color", "rgba(0.93, 0.93, 0.93, 1.00)")...
    ]

  BuiltinEnvironment.createVariantOfBuiltinSymbol "StrokeComponent", "Component",
    {
      _devLabel: "StrokeComponent"
      label: "Stroke"
      graphicClass: Graphic.StrokeComponent
    }
    [
      BuiltinEnvironment.changes_AddAttributeToParent("root", "Stroke Color", "color", "rgba(0.60, 0.60, 0.60, 1.00)")...
      BuiltinEnvironment.changes_AddAttributeToParent("root", "Line Width", "lineWidth", "1")...
    ]

  BuiltinEnvironment.createVariantOfBuiltinSymbol "PathComponent", "Component",
    {
      _devLabel: "PathComponent"
      label: "Path"
      graphicClass: Graphic.PathComponent
    }
    [
      BuiltinEnvironment.changes_AddAttributeToParent("root", "Close Path", "closed", "true")...
    ]

  BuiltinEnvironment.createVariantOfBuiltinSymbol "TextComponent", "Component",
    {
      _devLabel: "TextComponent"
      label: "Text"
      graphicClass: Graphic.TextComponent
    }
    [
      BuiltinEnvironment.changes_AddAttributeToParent("root", "Text", "text", '"Text"')...
      BuiltinEnvironment.changes_AddAttributeToParent("root", "Font", "fontFamily", '"Lucida Grande"')...
      BuiltinEnvironment.changes_AddAttributeToParent("root", "Color", "color", "rgba(0.20, 0.20, 0.20, 1.00)")...
      BuiltinEnvironment.changes_AddAttributeToParent("root", "Align", "textAlign", '"start"')...
      BuiltinEnvironment.changes_AddAttributeToParent("root", "Baseline", "textBaseline", '"alphabetic"')...
    ]
