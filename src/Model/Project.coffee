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
    @fullEnvironment = new NewSystem.CompoundEnvironment([BuiltinEnvironment, @userEnvironment])

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

  setEditing: (symbolId) ->
    @editingSymbolId = symbolId
    @selectedParticularElement = null

  select: (particularElement) ->
    if !particularElement
      @selectedParticularElement = null
      return
    @selectedParticularElement = particularElement
    @_expandToElement(particularElement.element)

  _expandToElement: (element) ->
    while element = element.parentBundle()
      element.expanded = true


  # ===========================================================================
  # Actions
  # ===========================================================================

  createNewSymbol: ->
    symbolId = Util.generateId()

    rootRef = new NewSystem.NodeRef_Pointer(NewSystem.buildId("master", "root"))

    changes = [
      new NewSystem.Change_CloneSymbol("Group", "master")
      new NewSystem.Change_SetPointerDestination("root", rootRef)
      new NewSystem.Change_ExtendNodeWithLiteral(rootRef, {label: "New Symbol", expanded: true})
    ]
    changeList = new NewSystem.ChangeList(changes)
    symbol = new NewSystem.Symbol(changeList)

    @userEnvironment.addSymbol(symbolId, symbol)

    return symbolId

  removeSelectedElement: ->
    throw "NOT IMPLEMENTED YET"
    return unless @selectedParticularElement
    selectedElement = @selectedParticularElement.element
    parent = selectedElement.parent()
    return unless parent
    parent.removeChild(selectedElement)
    @select(null)

  groupSelectedElement: ->
    throw "NOT IMPLEMENTED YET"
    return unless @selectedParticularElement
    selectedElement = @selectedParticularElement.element
    parent = selectedElement.parent()
    return unless parent
    group = Model.Group.createVariant()
    group.expanded = true
    parent.replaceChildWith(selectedElement, group)
    group.addChild(selectedElement)
    @select(new Model.ParticularElement(group))

  duplicateSelectedElement: ->
    throw "NOT IMPLEMENTED YET"
    # This implementation is a little kooky in that it creates a master that
    # is not in createPanelElements. This leads to weirdness with showing
    # novel attributes in the right sidebar.
    return unless @selectedParticularElement
    selectedElement = @selectedParticularElement.element
    parent = selectedElement.parent()
    return unless parent
    firstClone = selectedElement.createVariant()
    secondClone = selectedElement.createVariant()
    parent.replaceChildWith(selectedElement, firstClone)
    index = parent.children().indexOf(firstClone)
    parent.addChild(secondClone, index+1)
    @select(new Model.ParticularElement(secondClone))

  createSymbolFromSelectedElement: ->
    throw "NOT IMPLEMENTED YET"
    return unless @selectedParticularElement
    selectedElement = @selectedParticularElement.element
    parent = selectedElement.parent()
    return unless parent
    master = selectedElement
    variant = selectedElement.createVariant()
    parent.replaceChildWith(selectedElement, variant)
    @select(new Model.ParticularElement(variant))
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
    throw "NOT IMPLEMENTED YET"
    return @selectedParticularElement?.element.controlledAttributes() ? []

  implicitlyControlledAttributes: ->
    throw "NOT IMPLEMENTED YET"
    return @selectedParticularElement?.element.implicitlyControlledAttributes() ? []

  controllableAttributes: ->
    throw "NOT IMPLEMENTED YET"
    return @selectedParticularElement?.element.controllableAttributes() ? []
