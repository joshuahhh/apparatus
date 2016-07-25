test = require("tape")
util = require("util")
_ = require("underscore")
fs = require("fs")

NewSystem = require("../src/NewSystem/NewSystem")
BuiltinEnvironment = require("../src/NewSystem/BuiltinEnvironment")
Util = require("../src/Util/Util")


test "Make a rectangle", (t) ->
  # for symbolId, symbol of BuiltinEnvironment.symbols
  #   console.log(symbolId)
  #   console.log(symbol.changeList.toString())

  tree = new NewSystem.Tree()
  changes = new NewSystem.ChangeList([
    new NewSystem.Change_CloneSymbol("Rectangle", "myRect")
  ])
  changes.apply(tree, BuiltinEnvironment)

  myRect = (new NewSystem.NodeRef_Pointer("myRect/root")).resolve(tree)
  graphic = myRect.bundle.graphic()
  viewMatrix = new Util.Matrix(100, 0, 0, 100, 0, 0)
  t.true(graphic.hitDetect({x: 50, y: 50, viewMatrix: viewMatrix}))
  t.false(graphic.hitDetect({x: 150, y: 50, viewMatrix: viewMatrix}))
  t.false(graphic.hitDetect({x: -50, y: 50, viewMatrix: viewMatrix}))

  t.end()


test "Make a wide rectangle", (t) ->
  tree = new NewSystem.Tree()
  changes = new NewSystem.ChangeList([
    new NewSystem.Change_CloneSymbol("Rectangle", "myRect")
    BuiltinEnvironment.changes_SetAttributeExpression(
      new NewSystem.NodeRef_Pointer("myRect/master/master/transform/sx/root")
      "2"
    )...
  ])
  changes.apply(tree, BuiltinEnvironment)

  myRect = (new NewSystem.NodeRef_Pointer("myRect/root")).resolve(tree)
  graphic = myRect.bundle.graphic()
  viewMatrix = new Util.Matrix(100, 0, 0, 100, 0, 0)
  t.true(graphic.hitDetect({x: 100, y: 50, viewMatrix: viewMatrix}))
  t.false(graphic.hitDetect({x: 250, y: 50, viewMatrix: viewMatrix}))
  t.false(graphic.hitDetect({x: -50, y: 50, viewMatrix: viewMatrix}))

  t.end()


test "Make a rectangle in a transformed group", (t) ->
  tree = new NewSystem.Tree()
  changes = new NewSystem.ChangeList([
    new NewSystem.Change_CloneSymbol("Rectangle", "myRect")
    new NewSystem.Change_CloneSymbol("Group", "myGroup")
    new NewSystem.Change_AddChild(
      new NewSystem.NodeRef_Pointer("myGroup/root")
      new NewSystem.NodeRef_Pointer("myRect/root")
      Infinity
    )
    BuiltinEnvironment.changes_SetAttributeExpression(
      new NewSystem.NodeRef_Pointer("myGroup/master/transform/sx/root")
      "2"
    )...
  ])
  changes.apply(tree, BuiltinEnvironment)

  myGroup = (new NewSystem.NodeRef_Pointer("myGroup/root")).resolve(tree)
  graphic = myGroup.bundle.graphic()
  viewMatrix = new Util.Matrix(100, 0, 0, 100, 0, 0)
  t.true(graphic.hitDetect({x: 100, y: 50, viewMatrix: viewMatrix}))
  t.false(graphic.hitDetect({x: 250, y: 50, viewMatrix: viewMatrix}))
  t.false(graphic.hitDetect({x: -50, y: 50, viewMatrix: viewMatrix}))

  t.end()


test "Make some text", (t) ->
  tree = new NewSystem.Tree()
  changes = new NewSystem.ChangeList([
    new NewSystem.Change_CloneSymbol("Text", "myText")
    BuiltinEnvironment.changes_SetAttributeExpression(
      new NewSystem.NodeRef_Pointer("myText/text/text/root")
      '"Testing"'
    )...
    BuiltinEnvironment.changes_SetAttributeExpression(
      new NewSystem.NodeRef_Pointer("myText/master/transform/sx/root")
      '0.2'
    )...
    BuiltinEnvironment.changes_SetAttributeExpression(
      new NewSystem.NodeRef_Pointer("myText/master/transform/sy/root")
      '0.2'
    )...
  ])
  changes.apply(tree, BuiltinEnvironment)

  myText = (new NewSystem.NodeRef_Pointer("myText/root")).resolve(tree)
  graphic = myText.bundle.graphic()
  viewMatrix = new Util.Matrix(100, 0, 0, -100, 0, 100)

  Canvas = require("canvas")
  myCanvas = new Canvas(100, 50)
  ctx = myCanvas.getContext("2d")
  graphic.render({ctx: ctx, viewMatrix: viewMatrix})

  correctBuffer = fs.readFileSync("test/BuiltinEnvironment.Element.test.text.png")
  t.equal(myCanvas.toBuffer().base64Slice(), correctBuffer.base64Slice())

  t.end()
