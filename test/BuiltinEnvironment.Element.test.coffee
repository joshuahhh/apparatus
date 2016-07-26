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
  changes = new NewSystem.ChangeList [
    {type: "CloneSymbol", symbolId: "Rectangle", cloneId: "myRect"}
  ]
  changes.apply(tree, BuiltinEnvironment)

  myRect = tree.getNodeById("myRect/root")
  graphic = myRect.bundle.graphic()
  viewMatrix = new Util.Matrix(100, 0, 0, 100, 0, 0)
  t.true(graphic.hitDetect({x: 50, y: 50, viewMatrix: viewMatrix}))
  t.false(graphic.hitDetect({x: 150, y: 50, viewMatrix: viewMatrix}))
  t.false(graphic.hitDetect({x: -50, y: 50, viewMatrix: viewMatrix}))

  t.end()


test "Make a wide rectangle", (t) ->
  tree = new NewSystem.Tree()
  changes = new NewSystem.ChangeList([
    {type: "CloneSymbol", symbolId: "Rectangle", cloneId: "myRect"}
    {type: "SetAttributeExpression", attributeId: "myRect/transform/sx/root", exprString: "2"}
  ])
  changes.apply(tree, BuiltinEnvironment)

  myRect = tree.getNodeById("myRect/root")
  graphic = myRect.bundle.graphic()
  viewMatrix = new Util.Matrix(100, 0, 0, 100, 0, 0)
  t.true(graphic.hitDetect({x: 100, y: 50, viewMatrix: viewMatrix}))
  t.false(graphic.hitDetect({x: 250, y: 50, viewMatrix: viewMatrix}))
  t.false(graphic.hitDetect({x: -50, y: 50, viewMatrix: viewMatrix}))

  t.end()


test "Make a rectangle in a transformed group", (t) ->
  tree = new NewSystem.Tree()
  changes = new NewSystem.ChangeList([
    {type: "CloneSymbol", symbolId: "Rectangle", cloneId: "myRect"}
    {type: "CloneSymbol", symbolId: "Group", cloneId: "myGroup"}
    {type: "AddChild", parentId: "myGroup/root", childId: "myRect/root", insertionIndex: Infinity}
    {type: "SetAttributeExpression", attributeId: "myGroup/transform/sx/root", exprString: "2"}
  ])
  changes.apply(tree, BuiltinEnvironment)

  myGroup = tree.getNodeById("myGroup/root")
  graphic = myGroup.bundle.graphic()
  viewMatrix = new Util.Matrix(100, 0, 0, 100, 0, 0)
  t.true(graphic.hitDetect({x: 100, y: 50, viewMatrix: viewMatrix}))
  t.false(graphic.hitDetect({x: 250, y: 50, viewMatrix: viewMatrix}))
  t.false(graphic.hitDetect({x: -50, y: 50, viewMatrix: viewMatrix}))

  t.end()


test "Make some text", (t) ->
  tree = new NewSystem.Tree()
  changes = new NewSystem.ChangeList [
    {type: "CloneSymbol", symbolId: "Text", cloneId: "myText"}
    {type: "SetAttributeExpression", attributeId: "myText/text/text/root", exprString: '"Testing"'}
    {type: "SetAttributeExpression", attributeId: "myText/transform/sx/root", exprString: "0.2"}
    {type: "SetAttributeExpression", attributeId: "myText/transform/sy/root", exprString: "0.2"}
  ]
  changes.apply(tree, BuiltinEnvironment)

  myText = tree.getNodeById("myText/root")
  graphic = myText.bundle.graphic()
  viewMatrix = new Util.Matrix(100, 0, 0, -100, 0, 100)

  Canvas = require("canvas")
  myCanvas = new Canvas(100, 50)
  ctx = myCanvas.getContext("2d")
  graphic.render({ctx: ctx, viewMatrix: viewMatrix})

  correctBuffer = fs.readFileSync("test/BuiltinEnvironment.Element.test.text.png")
  t.equal(myCanvas.toBuffer().base64Slice(), correctBuffer.base64Slice())

  t.end()
