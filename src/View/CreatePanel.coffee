_ = require "underscore"
R = require "./R"
Model = require "../Model/Model"
Util = require "../Util/Util"


R.create "CreatePanel",
  contextTypes:
    project: Model.Project
    editor: Model.Editor

  render: ->
    project = @context.project
    layout = @context.editor.layout

    if layout.fullScreen
      return null

    R.div { className: "CreatePanel" },
      R.div { className: "CreatePanelContainer" },
        R.div {className: "Header"}, "Symbols"
        R.div {className: "Scroller"},
          for symbolId in project.createPanelSymbolIds
            R.CreatePanelItem {symbolId, key: symbolId}

          R.div {className: "CreatePanelAddItem"},
            R.button {
              className: "AddButton",
              onClick: @_createNewElement
            }

  _createNewElement: ->
    project = @context.project
    symbolId = project.createNewSymbol()
    project.createPanelSymbolIds.push(symbolId)
    project.setEditing(symbolId)


R.create "CreatePanelItem",
  contextTypes:
    project: Model.Project
    dragManager: R.DragManager

  propTypes:
    symbolId: String

  render: ->
    {symbolId} = @props
    {project} = @context

    symbol = project.__fullEnvironment.getSymbolById(symbolId)
    tree = symbol.getTree(project.__fullEnvironment)
    rootNode = tree.getNodeById("root")

    R.div {
      className: R.cx {
        "CreatePanelItem": true
        "isEditing": @_isEditing()
      }
    },
      R.div {
        className: "CreatePanelThumbnail"
        onMouseDown: @_onMouseDown
      },
        R.Thumbnail {element: rootNode.bundle}

      if @_isEditable()
        R.span {},
          R.div {
            className: "CreatePanelItemEditButton icon-pencil"
            onClick: @_editElement
          }
      if @_isEditable() and !@_isEditing()
          R.div {
            className: "CreatePanelItemRemoveButton icon-x"
            onClick: @_remove
          }

      R.div {
        className: "CreatePanelLabel"
      },
        R.EditableText {
          value: rootNode.bundle.label
          setValue: @_setLabelValue
        }

  _isEditing: ->
    {symbolId} = @props
    {project} = @context
    return symbolId == project.editingSymbolId

  _isEditable: ->
    {symbolId} = @props
    {project} = @context
    return !!project.userEnvironment.symbols[symbolId]

  _setLabelValue: (newValue) ->
    throw "NOT IMPLEMENTED YET"
    @props.element.label = newValue

  _editElement: ->
    {symbolId} = @props
    {project} = @context
    project.setEditing(symbolId)

  _remove: ->
    throw "NOT IMPLEMENTED YET"
    {symbolId} = @props
    {project} = @context
    project.createPanelElements = _.without(project.createPanelElements, element)

  _onMouseDown: (mouseDownEvent) ->
    {dragManager} = @context
    {symbolId} = @props

    mouseDownEvent.preventDefault()
    Util.clearTextFocus()

    dragManager.start mouseDownEvent,
      type: "createElement"
      symbolId: symbolId
      onCancel: =>
        if @_isEditable()
          @_editElement()
      # cursor
