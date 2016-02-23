_ = require "underscore"
R = require "./R"
Model = require "../Model/Model"
Monadic = require "../Dataflow/Monadic"
Util = require "../Util/Util"


R.create "Expression",
  propTypes:
    attribute: Model.Attribute

  render: ->
    attribute = @props.attribute

    R.div {className: "Expression", onClick: @_onClick},
      R.ExpressionCode {attribute}
      R.ExpressionValue {attribute}

  _onClick: ->
    window.attribute = @props.attribute

R.create "ExpressionValue",
  propTypes:
    attribute: Model.Attribute
  render: ->
    attribute = @props.attribute
    if attribute.isTrivial()
      R.span {}
    else
      value = attribute.value()
      R.div {className: "ExpressionValue"},
        R.Value {value: value}

R.create "Value",
  propTypes:
    value: "any"
  render: ->
    value = @props.value
    R.span {className: "Value"},
      if value instanceof Error
        "(" + value + ")"
      else if _.isFunction(value)
        "(Function)"
      else if value instanceof Monadic.Spread
        R.SpreadValue {spread: value}
      else if _.isNumber(value)
        Util.toMaxPrecision(value, 3)
      else
        JSON.stringify(value)

# TODO: The styling/formatting for this could be better. Also it should
# highlight the particular selected item when appropriate.
R.create "SpreadValue",
  propTypes:
    spread: "any"
  render: ->
    {spread} = @props
    items = spread.items()
    maxSpreadItems = 5

    R.span {className: "SpreadValue"},
      for index in [0...Math.min(items.length, maxSpreadItems)]
        value = items[index]
        R.span {className: "SpreadValueItem"},
          R.Value {value: value}
      if items.length > maxSpreadItems
        "..."
