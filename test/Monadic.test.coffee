test = require("tape")
_ = require("underscore")
util = require("util")

Monadic = require("../src/Dataflow/Monadic")
Spread = Monadic.Spread


test "Spread::map works", (t) ->
  a = Spread.fromArray([0, 1, 2])
  b = a.map((x) -> x * x)
  t.deepEqual(b.items(), [0, 1, 4])
  t.end()

test "Spread::fromValue works", (t) ->
  a = Spread.fromValue("Test")
  t.deepEqual(a.items(), ["Test"])
  t.end()

test "Spread::_concat works", (t) ->
  a = Spread.fromArray([[1], [2]])
  b = Spread.fromArray([[10], [20]])
  c = a._concat(b)
  t.deepEqual(c.items(), [[1, 10], [1, 20], [2, 10], [2, 20]])
  t.end()

test "Spread::_concat works on parallel spreads", (t) ->
  a = Spread.fromArray([[1], [2]])
  b = a.map((x) -> [x[0] * 10])
  c = a._concat(b)
  t.deepEqual(c.items(), [[1, 10], [2, 20]])
  t.end()

test "Spread.product works", (t) ->
  a = Spread.fromArray([1, 2])
  b = Spread.fromArray([10, 20])
  c = Spread.product([a, b])
  t.deepEqual(c.items(), [[1, 10], [1, 20], [2, 10], [2, 20]])
  t.end()

test "Spread.product works on parallel spreads", (t) ->
  a = Spread.fromArray([1, 2])
  b = a.map((x) -> x * 10)
  c = Spread.product([a, b])
  t.deepEqual(c.items(), [[1, 10], [2, 20]])
  t.end()

test "Spread.multimap works", (t) ->
  a = Spread.fromArray([1, 2])
  b = Spread.fromArray([10, 20])
  c = Spread.multimap([a, b], (a, b) -> a + b)
  t.deepEqual(c.items(), [11, 21, 12, 22])
  t.end()

test "Spread.multimap works on parallel spreads", (t) ->
  a = Spread.fromArray([1, 2])
  b = a.map((x) -> x * 10)
  c = Spread.multimap([a, b], (a, b) -> a + b)
  t.deepEqual(c.items(), [11, 22])
  t.end()

test "Spread.join works", (t) ->
  a = Spread.fromArray([Spread.fromArray([1, 2]), Spread.fromArray([3, 4])])
  b = a.join()
  t.deepEqual(b.items(), [1, 2, 3, 4])
  t.end()





test "Spreads work", (t) ->
  a = Spread.fromArray([0 ... 10])
  b = Spread.multimap([a], (a) -> a * 2)
  c = Spread.multimap([a, b], (a, b) -> a + b)
  t.deepEqual(a.items(), [0 ... 10])
  t.deepEqual(b.items(), [0, 2, 4, 6, 8, 10, 12, 14, 16, 18])
  t.deepEqual(c.items(), [0, 3, 6, 9, 12, 15, 18, 21, 24, 27])
  t.end()

test "Spreads cross product", (t) ->
  a = Spread.fromArray([0 ... 4])
  b = Spread.fromArray([10, 20])
  c = Spread.multimap([a, b], (a, b) -> a * b)
  t.deepEqual(_.sortBy(c.items()), [0, 0, 10, 20, 20, 30, 40, 60])
  t.end()

test "Spreads tree", (t) ->
  a = Spread.fromArray([0 ... 4])
  b = Spread.multibind([a], (a) -> Spread.fromArray([0 ... a]))
  c = Spread.multimap([a, b], (a, b) -> a * b)
  t.deepEqual(_.sortBy(c.items()), [0, 0, 0, 2, 3, 6])
  t.end()

test "Spreads rejoin", (t) ->
  a = Spread.fromArray([0 ... 10])
  b = Spread.multimap([a], (a) -> a * 2)
  c = Spread.multimap([a], (a) -> a * 3)
  d = Spread.multimap([b, c], (b, c) -> b + c)
  t.deepEqual(a.items(), [0 ... 10])
  t.deepEqual(b.items(), [0, 2, 4, 6, 8, 10, 12, 14, 16, 18])
  t.deepEqual(c.items(), [0, 3, 6, 9, 12, 15, 18, 21, 24, 27])
  t.deepEqual(d.items(), [0, 5, 10, 15, 20, 25, 30, 35, 40, 45])
  t.end()

test "All spreads should try to resolve as deep as possible", (t) ->
  a = Spread.fromArray([0, 1])
  b = Spread.multimap([a], (a) -> a  * 2)
  c = Spread.multimap([a, b], (a, b) -> {a: a, b: b})
  t.deepEqual(c.items(), [{a: 0, b: 0}, {a: 1, b: 2}])
  d = Spread.multimap([b], (b) -> {b: b})
  t.deepEqual(d.items(), [{b: 0}, {b: 2}])
  # Keeping "b" out of the "multimap" stops the propagation of the spread upwards in the expression.
  e = {b: b}
  t.deepEqual(e.b.items(), [0, 2])
  t.end()
