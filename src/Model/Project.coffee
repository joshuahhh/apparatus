_ = require "underscore"
Model = require "./Model"
Dataflow = require "../Dataflow/Dataflow"
NodeVisitor = require "../Util/NodeVisitor"
NewSystem = require "../NewSystem/NewSystem"
BuiltinEnvironment = require "../NewSystem/BuiltinEnvironment"
Util = require "../Util/Util"

module.exports = class Project
  constructor: ->
    @userEnvironment = new NewSystem.Environment()
    @__fullEnvironment = new NewSystem.CompoundEnvironment([BuiltinEnvironment, @userEnvironment])

    initialSymbolId = @createNewSymbol()

    @editingSymbolId = initialSymbolId
    @selectedParticularElement = null

    @createPanelSymbolIds = [
      "Rectangle"
      "Circle"
      "Text"
      initialSymbolId
    ]

    propsToMemoize = [
      "controlledAttributes"
      "implicitlyControlledAttributes"
      "controllableAttributes"
    ]
    for prop in propsToMemoize
      this[prop] = Dataflow.memoize(this[prop].bind(this))


  # ===========================================================================
  # Selection
  # ===========================================================================

  editingSymbol: ->
    return @__fullEnvironment.getSymbolById(@editingSymbolId)

  editingTree: ->
    return @editingSymbol().getTree(@__fullEnvironment)

  setEditing: (symbolId) ->
    @editingSymbolId = symbolId
    @selectedParticularElement = null

  select: (particularElement) ->
    if !particularElement
      @selectedParticularElement = null
      return
    @selectedParticularElement = particularElement
    @_expandToElement(particularElement.element(@editingTree()))

  _expandToElement: (element) ->
    changes = []
    while element = element.parentBundle()
      if not element.expanded
        changes.push({type: "ExtendNodeWithLiteral", nodeId: element.node.id, literal: {expanded: true}})
    @addChanges(changes)


  # ===========================================================================
  # Actions
  # ===========================================================================

  createNewSymbol: (symbolId) ->
    symbolId = Util.generateId()

    changes = [
      {type: "CloneSymbol", symbolId: "Group", cloneId: ""}
      {type: "ExtendNodeWithLiteral", nodeId: "root", literal: {label: "New Symbol", expanded: true}}
    ]
    changeList = new NewSystem.ChangeList(changes)
    symbol = new NewSystem.Symbol(changeList)

    @userEnvironment.addSymbol(symbolId, symbol)

    return symbolId

  addChanges: (changes) ->
    @editingSymbol().addChanges(changes)

    # console.log("#{@editingSymbolId} is now:\n" + @editingSymbol().changeList.toString())

  setExpression: (attributeId, exprString, references) ->
    @addChanges [
      {type: "SetAttributeExpression", attributeId: attributeId, exprString: exprString, references: references}
    ]

  createElement: (symbolId) ->
    cloneId = Util.generateId()
    @addChanges [
      {type: "AddChildFromClonedSymbol", parentId: "root", insertionIndex: Infinity, symbolId, cloneId}
    ]

    newParticularElement = new Model.ParticularElement(NewSystem.buildId(cloneId, "root"))
    @select(newParticularElement)
    return newParticularElement

  addControlledAttribute: (elementId, attributeId) ->
    @addChanges [
      {type: "AddControlledAttributeToElement", elementId, attributeId}
    ]

  removeControlledAttribute: (elementId, attributeId) ->
    @addChanges [
      {type: "RemoveControlledAttributeFromElement", elementId, attributeId}
    ]

  removeSelectedElement: ->
    return unless @selectedParticularElement
    selectedElement = @selectedParticularElement.element(@editingTree())
    parent = selectedElement.parent()
    return unless parent
    @addChanges [
      {type: "DeparentNode", nodeId: selectedElement.node.id}
    ]
    @select(null)

  groupSelectedElement: ->
    throw "NOT IMPLEMENTED YET"
    return unless @selectedParticularElement
    selectedElement = @selectedParticularElement.element(@editingTree())
    parent = selectedElement.parent()
    return unless parent
    group = Model.Group.createVariant()
    group.expanded = true
    parent.replaceChildWith(selectedElement, group)
    group.addChild(selectedElement)
    @select(new Model.ParticularElement(group.node.id))

  duplicateSelectedElement: ->
    throw "NOT IMPLEMENTED YET"
    # This implementation is a little kooky in that it creates a master that
    # is not in createPanelElements. This leads to weirdness with showing
    # novel attributes in the right sidebar.
    return unless @selectedParticularElement
    selectedElement = @selectedParticularElement.element(@editingTree())
    parent = selectedElement.parent()
    return unless parent
    firstClone = selectedElement.createVariant()
    secondClone = selectedElement.createVariant()
    parent.replaceChildWith(selectedElement, firstClone)
    index = parent.children().indexOf(firstClone)
    parent.addChild(secondClone, index+1)
    @select(new Model.ParticularElement(secondClone.node.id))

  createSymbolFromSelectedElement: ->
    throw "NOT IMPLEMENTED YET"
    return unless @selectedParticularElement
    selectedElement = @selectedParticularElement.element(@editingTree())
    parent = selectedElement.parent()
    return unless parent
    master = selectedElement
    variant = selectedElement.createVariant()
    parent.replaceChildWith(selectedElement, variant)
    @select(new Model.ParticularElement(variant.node.id))
    # Insert master into createPanelElements.
    index = @createPanelElements.indexOf(@editingElement)
    @createPanelElements.splice(index, 0, master)

  findUnnecessaryNodes: ->
    throw "NOT IMPLEMENTED YET"

    # These nodes are necessary per se.
    rootNodes = @createPanelElements.slice()
    for name, obj of Model
      if Model.Node.isPrototypeOf(obj)
        rootNodes.push(obj)

    unnecessaryNodes = []

    # If a node is necessary, its master is necessary and its children are
    # necessary. Its parent and its variants are not necessarily necessary.
    necessaryNodeVisitor = new NodeVisitor
      linksToFollow: {master: yes, variants: no, parent: no, children: yes}
    necessaryNodeVisitor.visit(rootNode) for rootNode in rootNodes

    connectedNodeVisitor = new NodeVisitor
      linksToFollow: {master: yes, variants: yes, parent: yes, children: yes}
      onVisit: (node) ->
        if !necessaryNodeVisitor.hasVisited(node)
          unnecessaryNodes.push(node)
    connectedNodeVisitor.visit(rootNode) for rootNode in rootNodes

    connectedNodeVisitor.finish()
    necessaryNodeVisitor.finish()

    return unnecessaryNodes


  # ===========================================================================
  # Memoized attribute sets
  # ===========================================================================

  controlledAttributes: ->
    return @selectedParticularElement?.element(@editingTree()).controlledAttributes() ? []

  implicitlyControlledAttributes: ->
    return @selectedParticularElement?.element(@editingTree()).implicitlyControlledAttributes() ? []

  controllableAttributes: ->
    return @selectedParticularElement?.element(@editingTree()).controllableAttributes() ? []
