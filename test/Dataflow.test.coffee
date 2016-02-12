test = require("tape")

Dataflow = require("../src/Dataflow/Dataflow")


test "Values are computed correctly", (t) ->
  a = new Dataflow.Cell -> 4
  b = new Dataflow.Cell -> a.run() * 2
  t.equal(b.run(), 8)
  t.end()

test "Cacheing works", (t) ->
  aCount = 0
  bCount = 0
  cCount = 0
  a = new Dataflow.Cell ->
    aCount++
    return 4
  b = new Dataflow.Cell ->
    bCount++
    return a.run() * 2
  c = new Dataflow.Cell ->
    cCount++
    return b.run() + a.run()
  Dataflow.run ->
    t.equal(a.run(), 4)
    t.equal(b.run(), 8)
    t.equal(c.run(), 12)
    t.equal(aCount, 1)
    t.equal(bCount, 1)
    t.equal(cCount, 1)
  t.end()

test "Spreads work", (t) ->
  a = new Dataflow.Cell -> new Dataflow.Spread([0 ... 10], a)
  b = new Dataflow.Cell -> a.run() * 2
  c = new Dataflow.Cell -> a.run() + b.run()
  t.deepEqual(a.run().items, [0 ... 10])
  t.deepEqual(b.run().items, [0, 2, 4, 6, 8, 10, 12, 14, 16, 18])
  t.deepEqual(c.run().items, [0, 3, 6, 9, 12, 15, 18, 21, 24, 27])
  t.end()

test "Spreads cross product", (t) ->
  a = new Dataflow.Cell -> new Dataflow.Spread([0 ... 8], a)
  b = new Dataflow.Cell -> new Dataflow.Spread([10, 20], b)
  c = new Dataflow.Cell -> a.run() * b.run()
  for item, index in c.run().items
    t.deepEqual(item.items, [index * 10, index * 20])
  t.end()

test "Spreads rejoin", (t) ->
  a = new Dataflow.Cell -> new Dataflow.Spread([0 ... 10], a)
  b = new Dataflow.Cell -> a.run() * 2
  c = new Dataflow.Cell -> a.run() * 3
  d = new Dataflow.Cell -> c.run() + b.run()
  t.deepEqual(a.run().items, [0 ... 10])
  t.deepEqual(b.run().items, [0, 2, 4, 6, 8, 10, 12, 14, 16, 18])
  t.deepEqual(c.run().items, [0, 3, 6, 9, 12, 15, 18, 21, 24, 27])
  t.deepEqual(d.run().items, [0, 5, 10, 15, 20, 25, 30, 35, 40, 45])

  t.end()

test "All spreads should try to resolve as deep as possible", (t) ->
  a = new Dataflow.Cell -> new Dataflow.Spread([0, 1], a)
  b = new Dataflow.Cell -> a.run() * 2
  c = new Dataflow.Cell -> {a: a.run(), b: b.asSpread()}
  t.deepEqual(c.run().items, [{a: 0, b: 0}, {a: 1, b: 2}])
  d = new Dataflow.Cell -> {b: b.asSpread()}
  t.deepEqual(d.run().b.items, [0, 2])
  t.end()
