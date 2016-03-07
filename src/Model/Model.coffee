_ = require "underscore"
Dataflow = require "../Dataflow/Dataflow"
Graphic = require "../Graphic/Graphic"
Util = require "../Util/Util"


module.exports = Model = {}

# These are *classes*
Model.Project = require "./Project"
Model.ParticularElement = require "./ParticularElement"
Model.Layout = require "./Layout"

# These are *variants of the Node object*
Model.Node = require "./Node"
Model.Link = require "./Link"
Model.Attribute = require "./Attribute"
Model.ExpressionAttribute = Model.Attribute.ExpressionAttribute
Model.InternalAttribute = Model.Attribute.InternalAttribute
Model.Element = require "./Element"

Model.Editor = require "./Editor"


Model.Variable = Model.ExpressionAttribute.createVariant
  label: "Variable"

# Links an Element to the Attributes it controls.
Model.ControlledAttributeLink = Model.Link.createVariant
  label: "ControlledAttributeLink"

# Links an Attribute to the Attributes it references in its expression.
Model.ReferenceLink = Model.Link.createVariant
  label: "ReferenceLink"

createAttribute = (label, name, exprString) ->
  attribute = Model.ExpressionAttribute.createVariant
    label: label
    name: name
  attribute.setExpression(exprString)
  return attribute

# =============================================================================
# Components
# =============================================================================

Model.Component = Model.Node.createVariant
  label: "Component"

  attributes: ->
    @childrenOfType(Model.Attribute)

  expressionAttributes: ->
    @childrenOfType(Model.ExpressionAttribute)

  internalAttributes: ->
    @childrenOfType(Model.InternalAttribute)

  getAttributesByName: ->
    _.indexBy @attributes(), "name"

  getAttributesValuesByName: ->
    result = {}
    for attribute in @attributes()
      name = attribute.name
      value = attribute.value()
      result[name] = value
    return result

  graphicClass: Graphic.Component

  graphicAttribute: ->
    @getAttributesByName().graphic

  graphic: ->
    @graphicAttribute().value()

Model.ComponentGraphic = Model.InternalAttribute.createVariant
  label: 'Graphic'
  name: 'graphic'
  internalFunction: (attributeValues) ->
    # TRICKY BUSINESS: This depends on @parent().graphicClass, so you can
    # override this in Component's variants. But make sure to set its children
    # to link to whatever other attributes it depends on! ALSO TRICKY:
    # graphicClass is not part of the attribute system, so it's got to be
    # static.
    graphic = new (@parent().graphicClass)
    graphic.attributeValues = attributeValues
    return graphic

Model.Component.addChildren [
  Model.ComponentGraphic.createVariant {}
]


Model.Transform = Model.Component.createVariant
  label: "Transform"
  graphicClass: Graphic.Transform

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

Model.InternalAttributeMatrix = Model.InternalAttribute.createVariant
  label: 'Matrix'
  name: 'matrix'
  internalFunction: ({x, y, sx, sy, rotate}) ->
    Util.Matrix.naturalConstruct(x, y, sx, sy, rotate)

Model.InternalAttributeContextMatrix = Model.InternalAttribute.createVariant
  label: 'Context Matrix'
  name: 'contextMatrix'
  internalFunction: ({parentAccumulatedMatrix}) ->
    if parentAccumulatedMatrix
      return parentAccumulatedMatrix
    else
      return new Util.Matrix()

Model.InternalAttributeAccumulatedMatrix = Model.InternalAttribute.createVariant
  label: 'Accumulated Matrix'
  name: 'accumulatedMatrix'
  internalFunction: ({matrix, contextMatrix}) ->
    contextMatrix.compose(matrix)

do ->
  Model.Transform.addChildren [
    x = createAttribute("X", "x", "0.00")
    y = createAttribute("Y", "y", "0.00")
    sx = createAttribute("Scale X", "sx", "1.00")
    sy = createAttribute("Scale Y", "sy", "1.00")
    rotate = createAttribute("Rotate", "rotate", "0.00")
  ]

  matrix = Model.InternalAttributeMatrix.createVariant {}
  matrix.setReferences({x, y, sx, sy, rotate})
  Model.Transform.addChild matrix

  contextMatrix = Model.InternalAttributeContextMatrix.createVariant {}
  # Only reference is to parent accumulated matrix; set by parent Element
  Model.Transform.addChild contextMatrix

  accumulatedMatrix = Model.InternalAttributeAccumulatedMatrix.createVariant {}
  accumulatedMatrix.setReferences({matrix, contextMatrix})
  Model.Transform.addChild accumulatedMatrix

  Model.Transform.graphicAttribute().setReferences({
    x, y, sx, sy, rotate, matrix, contextMatrix, accumulatedMatrix
  })


Model.Fill = Model.Component.createVariant
  label: "Fill"
  graphicClass: Graphic.Fill

do ->
  Model.Fill.addChildren [
    color = createAttribute("Fill Color", "color", "rgba(0.93, 0.93, 0.93, 1.00)")
  ]

  Model.Fill.graphicAttribute().setReferences({color})

Model.Stroke = Model.Component.createVariant
  label: "Stroke"
  graphicClass: Graphic.Stroke

do ->
  Model.Stroke.addChildren [
    color = createAttribute("Stroke Color", "color", "rgba(0.60, 0.60, 0.60, 1.00)")
    lineWidth = createAttribute("Line Width", "lineWidth", "1")
  ]

  Model.Stroke.graphicAttribute().setReferences({color, lineWidth})


# =============================================================================
# Elements
# =============================================================================

Model.GraphicsOfComponents = Model.InternalAttribute.createVariant
  label: 'Graphics Of Components'
  name: 'graphicsOfComponents'
  internalFunction: (attributeValues) ->
    _.toArray(attributeValues)

Model.GraphicsOfChildElements = Model.InternalAttribute.createVariant
  label: 'Graphics Of Child Elements'
  name: 'graphicsOfChildElements'
  internalFunction: (attributeValues) ->
    # We use a Graphic.Element to wrap up the child element graphics, since it
    # has the right tree-spread-node structure.
    graphic = new Graphic.Element
    graphic.childGraphicSpreads = _.toArray(attributeValues)
    return graphic

Model.ElementGraphic = Model.InternalAttribute.createVariant
  label: 'Graphic'
  name: 'graphic'
  internalFunction: ({graphicsOfComponents, graphicsOfChildElements, _env}) ->
    # TRICKY BUSINESS: This depends on @parent().graphicClass, so you can
    # override this in Component's variants. But make sure to set its children
    # to link to whatever other attributes it depends on! ALSO TRICKY:
    # graphicClass is not part of the attribute system, so it's got to be
    # static.
    graphic = new (@parent().graphicClass)
    graphic.components = graphicsOfComponents  # These won't be spread at all
    graphic.childGraphicSpreads = graphicsOfChildElements
    graphic.particularElement = new Model.ParticularElement(this, _env)
    return graphic

do ->
  Model.Element.addChildren [
    graphicsOfComponents = Model.GraphicsOfComponents.createVariant {}
    graphicsOfChildElements = Model.GraphicsOfChildElements.createVariant {}
    graphic = Model.ElementGraphic.createVariant {}
  ]

  Model.Element.rewireGraphicsOfChildElementsAttribute()

  graphic.setReferences(
    {graphicsOfComponents, graphicsOfChildElements}
    {graphicsOfComponents: no, graphicsOfChildElements: yes}  # asTreeSpread
  )

Model.Shape = Model.Element.createVariant
  label: "Shape"

console.log('A', _.invoke(Model.Element.children(), "devLabel"))
console.log('B', _.invoke(Model.Element.createVariant({}).children(), "devLabel"))
console.log('B master', Model.Element.createVariant({}).master().devLabel())
console.log('C', _.invoke(Model.Shape.children(), "devLabel"))

do ->
  Model.Shape.addChildren [
    transform = Model.Transform.createVariant()
  ]

  Model.Shape.graphicsOfComponentsAttribute().addReferences
    transform: transform.graphicAttribute()


Model.Group = Model.Shape.createVariant
  label: "Group"
  graphicClass: Graphic.Group


Model.Anchor = Model.Shape.createVariant
  label: "Anchor"
  graphicClass: Graphic.Anchor

createAnchor = (x, y) ->
  anchor = Model.Anchor.createVariant()
  transform = anchor.childOfType(Model.Transform)
  attributes = transform.getAttributesByName()
  attributes.x.setExpression(x)
  attributes.y.setExpression(y)
  return anchor


Model.PathComponent = Model.Component.createVariant
  _devLabel: "PathComponent"
  label: "Path"
  graphicClass: Graphic.PathComponent

do ->
  Model.PathComponent.addChildren [
    closed = createAttribute("Close Path", "closed", "true")
  ]

  Model.PathComponent.graphicAttribute().setReferences(
    {closed})

Model.Path = Model.Shape.createVariant
  label: "Path"
  graphicClass: Graphic.Path

do ->
  Model.Path.addChildren [
    path = Model.PathComponent.createVariant()
    fill = Model.Fill.createVariant()
    stroke = Model.Stroke.createVariant()
  ]

  Model.Path.graphicsOfComponentsAttribute().addReferences
    path: path.graphicAttribute()
    fill: fill.graphicAttribute()
    stroke: stroke.graphicAttribute()


Model.Circle = Model.Path.createVariant
  label: "Circle"
  graphicClass: Graphic.Circle


Model.Rectangle = Model.Path.createVariant
  label: "Rectangle"

Model.Rectangle.addChildren [
  createAnchor("0.00", "0.00")
  createAnchor("0.00", "1.00")
  createAnchor("1.00", "1.00")
  createAnchor("1.00", "0.00")
]


Model.TextComponent = Model.Component.createVariant
  _devLabel: "TextComponent"
  label: "Text"
  graphicClass: Graphic.TextComponent

do ->
  Model.TextComponent.addChildren [
    text = createAttribute("Text", "text", '"Text"')
    fontFamily = createAttribute("Font", "fontFamily", '"Lucida Grande"')
    color = createAttribute("Color", "color", "rgba(0.20, 0.20, 0.20, 1.00)")
    textAlign = createAttribute("Align", "textAlign", '"start"')
    textBaseline = createAttribute("Baseline", "textBaseline", '"alphabetic"')
  ]

  Model.TextComponent.graphicAttribute().setReferences(
    {text, fontFamily, color, textAlign, textBaseline})


Model.Text = Model.Shape.createVariant
  label: "Text"
  graphicClass: Graphic.Text

do ->
  Model.Text.addChildren [
    text = Model.TextComponent.createVariant()
  ]

  Model.Text.graphicsOfComponentsAttribute().addReferences
    text: text.graphicAttribute()
