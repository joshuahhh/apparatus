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
      {type: "AddAttributeToParent", parentId: "root", label: "X", name: "x", exprString: "0.00"}
      {type: "AddAttributeToParent", parentId: "root", label: "Y", name: "y", exprString: "0.00"}
      {type: "AddAttributeToParent", parentId: "root", label: "Scale X", name: "sx", exprString: "1.00"}
      {type: "AddAttributeToParent", parentId: "root", label: "Scale Y", name: "sy", exprString: "1.00"}
      {type: "AddAttributeToParent", parentId: "root", label: "Rotate", name: "rotate", exprString: "0.00"}
    ]

  BuiltinEnvironment.createVariantOfBuiltinSymbol "FillComponent", "Component",
    {
      _devLabel: "FillComponent"
      label: "Fill"
      graphicClass: Graphic.FillComponent
    }
    [
      {type: "AddAttributeToParent", parentId: "root", label: "Fill Color", name: "color", exprString: "rgba(0.93, 0.93, 0.93, 1.00)"}
    ]

  BuiltinEnvironment.createVariantOfBuiltinSymbol "StrokeComponent", "Component",
    {
      _devLabel: "StrokeComponent"
      label: "Stroke"
      graphicClass: Graphic.StrokeComponent
    }
    [
      {type: "AddAttributeToParent", parentId: "root", label: "Stroke Color", name: "color", exprString: "rgba(0.60, 0.60, 0.60, 1.00)"}
      {type: "AddAttributeToParent", parentId: "root", label: "Line Width", name: "lineWidth", exprString: "1"}
    ]

  BuiltinEnvironment.createVariantOfBuiltinSymbol "PathComponent", "Component",
    {
      _devLabel: "PathComponent"
      label: "Path"
      graphicClass: Graphic.PathComponent
    }
    [
      {type: "AddAttributeToParent", parentId: "root", label: "Close Path", name: "closed", exprString: "true"}
    ]

  BuiltinEnvironment.createVariantOfBuiltinSymbol "TextComponent", "Component",
    {
      _devLabel: "TextComponent"
      label: "Text"
      graphicClass: Graphic.TextComponent
    }
    [
      {type: "AddAttributeToParent", parentId: "root", label: "Text", name: "text", exprString: '"Text"'}
      {type: "AddAttributeToParent", parentId: "root", label: "Font", name: "fontFamily", exprString: '"Lucida Grande"'}
      {type: "AddAttributeToParent", parentId: "root", label: "Color", name: "color", exprString: "rgba(0.20, 0.20, 0.20, 1.00)"}
      {type: "AddAttributeToParent", parentId: "root", label: "Align", name: "textAlign", exprString: '"start"'}
      {type: "AddAttributeToParent", parentId: "root", label: "Baseline", name: "textBaseline", exprString: '"alphabetic"'}
    ]
