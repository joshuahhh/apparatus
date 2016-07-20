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
Model.NodeWithAttributes = require "./NodeWithAttributes"
Model.Link = require "./Link"
Model.Attribute = require "./Attribute"
Model.Element = require "./Element"


Model.Editor = require "./Editor"

# =============================================================================
# Elements
# =============================================================================

# Shape Interpretation Contexts
RENDERING = 'renderingContext'
ANCHOR_COLLECTION = 'anchorCollectionContext'
NONE = 'noDraggingContext'

Model.Shape = Model.Element.createVariant
  label: "Shape"

  getAllowedShapeInterpretationContext: () ->
    return [RENDERING]

  getAllowedShapeInterpretationContextForChildren: () ->
    return [RENDERING]

Model.Shape.addChildren [
  Model.Transform.createVariant()
]

Model.Group = Model.Shape.createVariant
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


Model.Anchor = Model.Shape.createVariant
  label: "Anchor"

  getAllowedShapeInterpretationContext: () ->
    return [ANCHOR_COLLECTION]

  getAllowedShapeInterpretationContextForChildren: () ->
    return [NONE]

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

Model.PathComponent.addChildren [
  createAttribute("Close Path", "closed", "true")
]

Model.Path = Model.Shape.createVariant
  label: "Path"
  graphicClass: Graphic.Path

Model.Path.addChildren [
  Model.PathComponent.createVariant()
  Model.Fill.createVariant()
  Model.Stroke.createVariant()
]


Model.Circle = Model.Path.createVariant
  label: "Circle"
  getAllowedShapeInterpretationContextForChildren: () ->
    return [NONE]

  graphicClass: Graphic.Circle


Model.Rectangle = Model.Path.createVariant
  label: "Rectangle"
  getAllowedShapeInterpretationContextForChildren: () ->
    return [ANCHOR_COLLECTION]

Model.Rectangle.addChildren [
  createAnchor("0.00", "0.00")
  createAnchor("0.00", "1.00")
  createAnchor("1.00", "1.00")
  createAnchor("1.00", "0.00")
]


Model.TextComponent = Model.Component.createVariant
  _devLabel: "TextComponent"
  label: "Text"
  getAllowedShapeInterpretationContextForChildren: () ->
    return [NONE]

  graphicClass: Graphic.TextComponent

Model.TextComponent.addChildren [
  createAttribute("Text", "text", '"Text"')
  createAttribute("Font", "fontFamily", '"Lucida Grande"')
  createAttribute("Color", "color", "rgba(0.20, 0.20, 0.20, 1.00)")
  createAttribute("Align", "textAlign", '"start"')
  createAttribute("Baseline", "textBaseline", '"alphabetic"')
]

Model.Text = Model.Shape.createVariant
  label: "Text"
  graphicClass: Graphic.Text

Model.Text.addChildren [
  Model.TextComponent.createVariant()
]
