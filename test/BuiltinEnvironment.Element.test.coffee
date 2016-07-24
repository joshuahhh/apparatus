test = require("tape")
util = require("util")
_ = require("underscore")
fs = require("fs")

NewSystem = require("../src/NewSystem/NewSystem")
BuiltinEnvironment = require("../src/NewSystem/BuiltinEnvironment")
Util = require("../src/Util/Util")


test "Make a rectangle", (t) ->
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
  t.equal(myCanvas.toBuffer().base64Slice(), "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")

  t.end()
