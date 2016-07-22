test = require("tape")
util = require("util")
_ = require("underscore")

NewSystem = require("../src/NewSystem/NewSystem")
BuiltinEnvironment = require("../src/NewSystem/BuiltinEnvironment")


test "Make a rectangle", (t) ->
  tree = new NewSystem.Tree()
  changes = new NewSystem.ChangeList([
    new NewSystem.Change_CloneSymbol("Rectangle", "myRect")
  ])
  changes.apply(tree, BuiltinEnvironment)

  # console.log(tree.toString())

  myRect = (new NewSystem.NodeRef_Pointer("myRect/root")).resolve(tree)

  console.log(myRect)

  graphic = myRect.bundle.graphic()

  console.log(graphic)

  # t.equal(attribute1.bundle.exprString, "testing", "exprString set correctly")
  # t.equal(attribute1.linkTargetIds['a'], attribute2.id, "link target set correctly")

  t.end()

# test "Ported: 'Numbers work'", (t) ->
#   tree = new NewSystem.Tree()
#   a = makeAttribute(tree, "a")
#
#   setExpression(tree, a, "6")
#   t.equal(a.bundle.exprString, "6", "exprString set correctly")
#   t.equal(a.bundle.value(), 6, "attribute evaluates correctly")
#
#   t.end()
#
# test "Ported: 'Math expressions work'", (t) ->
#   tree = new NewSystem.Tree()
#   a = makeAttribute(tree, "a")
#
#   setExpression(tree, a, "5 + 5")
#   t.equal(a.bundle.exprString, "5 + 5", "exprString set correctly")
#   t.equal(a.bundle.value(), 10, "attribute evaluates correctly")
#
#   t.end()
#
# test "Ported: 'Math expressions work'", (t) ->
#   tree = new NewSystem.Tree()
#   a = makeAttribute(tree, "a")
#   b = makeAttribute(tree, "b")
#
#   setExpression(tree, a, "20")
#   setExpression(tree, b, "$$$a$$$ * 2", {$$$a$$$: a.nodeRefTo()})
#   t.equal(a.tree, tree, "a has the right .tree reference")
#   t.equal(b.tree, tree, "b has the right .tree reference")
#   t.equal(b.bundle.value(), 40, "attribute evaluates correctly")
#
#   t.end()
#
# test "Ported: 'Changes recompile'", (t) ->
#   tree = new NewSystem.Tree()
#   a = makeAttribute(tree, "a")
#   b = makeAttribute(tree, "b")
#
#   setExpression(tree, a, "20")
#   setExpression(tree, b, "$$$a$$$ * 2", {$$$a$$$: a.nodeRefTo()})
#   t.equal(b.bundle.value(), 40)
#
#   setExpression(tree, a, "10")
#   t.equal(b.bundle.value(), 20)
#
#   setExpression(tree, b, "$$$a$$$ * 3", {$$$a$$$: a.nodeRefTo()})
#   t.equal(b.bundle.value(), 30)
#
#   t.end()
#
# test "Ported: 'Dependencies work'", (t) ->
#   tree = new NewSystem.Tree()
#   a = makeAttribute(tree, "a")
#   b = makeAttribute(tree, "b")
#   c = makeAttribute(tree, "c")
#
#   setExpression(tree, a, "$$$b$$$ * 2", {$$$b$$$: b.nodeRefTo()})
#   setExpression(tree, b, "$$$c$$$ * 3", {$$$c$$$: c.nodeRefTo()})
#   setExpression(tree, c, "20")
#
#   t.equal(a.bundle.value(), 120, 'value works')
#   t.deepEqual(a.bundle.dependencies(), [b, c], 'dependencies works')
#   t.equal(a.bundle.circularReferencePath(), null, 'circularReferencePath works')
#
#   t.end()
#
# test "Ported: 'Dependencies work with circular references'", (t) ->
#   tree = new NewSystem.Tree()
#   a = makeAttribute(tree, "a")
#   b = makeAttribute(tree, "b")
#   c = makeAttribute(tree, "c")
#
#   setExpression(tree, a, "$$$b$$$", {$$$b$$$: b.nodeRefTo()})
#   setExpression(tree, b, "$$$c$$$", {$$$c$$$: c.nodeRefTo()})
#   setExpression(tree, c, "$$$b$$$", {$$$b$$$: b.nodeRefTo()})
#
#   expectedCircularReferencePath = [a, b, c, b]
#   expectedError = new BuiltinEnvironment.CircularReferenceError(
#     expectedCircularReferencePath)
#
#   t.deepEqual(a.bundle.value(), expectedError, 'value works')
#   t.deepEqual(a.bundle.dependencies(), [b, c], 'dependencies works')
#   t.deepEqual(a.bundle.circularReferencePath(), expectedCircularReferencePath, 'circularReferencePath works')
#   t.end()
