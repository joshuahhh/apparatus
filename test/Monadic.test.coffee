test = require("tape")
_ = require("underscore")
util = require("util")

Monadic = require("../src/Dataflow/Monadic")
Spread = Monadic.Spread


test "Spread::map works", (t) ->
  a = Spread.fromArray([0, 1, 2])
  b = a.map((x) -> x * x)
  t.deepEqual(b.toArray(), [0, 1, 4])
  t.end()

test "Spread::fromValue works", (t) ->
  a = Spread.fromValue("Test")
  t.deepEqual(a.toArray(), ["Test"])
  t.end()

test "Spread::_multimap2 works", (t) ->
  a = Spread.fromArray([[1], [2]])
  b = Spread.fromArray([[10], [20]])
  concat = (a, b) -> a.concat(b)
  c = a._multimap2(b, concat)
  t.deepEqual(c.toArray(), [[1, 10], [1, 20], [2, 10], [2, 20]])
  t.end()

test "Spread::_multimap2 works on parallel spreads", (t) ->
  a = Spread.fromArray([[1], [2]])
  b = a.map((x) -> [x[0] * 10])
  concat = (a, b) -> a.concat(b)
  c = a._multimap2(b, concat)
  t.deepEqual(c.toArray(), [[1, 10], [2, 20]])
  t.end()

test "Spread.product works", (t) ->
  a = Spread.fromArray([1, 2])
  b = Spread.fromArray([10, 20])
  c = Spread.product({a: a, b: b})
  t.deepEqual(c.toArray(), [{a: 1, b: 10}, {a: 1, b: 20}, {a: 2, b: 10}, {a: 2, b: 20}])
  t.end()

test "Spread.product works on parallel spreads", (t) ->
  a = Spread.fromArray([1, 2])
  b = a.map((x) -> x * 10)
  c = Spread.product({a: a, b: b})
  t.deepEqual(c.toArray(), [{a: 1, b: 10}, {a: 2, b: 20}])
  t.end()

test "Spread.multimap works", (t) ->
  a = Spread.fromArray([1, 2])
  b = Spread.fromArray([10, 20])
  c = Spread.multimap({a: a, b: b}, (obj) -> obj.a + obj.b)
  t.deepEqual(c.toArray(), [11, 21, 12, 22])
  t.end()

test "Spread.multimap works on parallel spreads", (t) ->
  a = Spread.fromArray([1, 2])
  b = a.map((x) -> x * 10)
  c = Spread.multimap({a: a, b: b}, (obj) -> obj.a + obj.b)
  t.deepEqual(c.toArray(), [11, 22])
  t.end()

test "Spread.join works", (t) ->
  a = Spread.fromArray([Spread.fromArray([1, 2]), Spread.fromArray([3, 4])])
  b = a.join()
  t.deepEqual(b.toArray(), [1, 2, 3, 4])
  t.end()

test "Spread::_applyEnv works", (t) ->
  a = new Spread([
    [{x: 0, y: 0}, '00']
    [{x: 0, y: 1}, '01']
    [{x: 1, y: 0}, '10']
    [{x: 1, y: 1}, '11']
  ])
  t.deepEqual(a._applyEnv({}),
    a
  )
  t.deepEqual(a._applyEnv({x: 1}), new Spread([
    [{y: 0}, '10']
    [{y: 1}, '11']
  ]))
  t.deepEqual(a._applyEnv({x: 1, y: 0}), new Spread([
    [{}, '10']
  ]))
  t.deepEqual(a._applyEnv({x: 1, y: 0, z: 100}), new Spread([
    [{}, '10']
  ]))
  t.end()

class TestNode
  constructor: (@_children, @_extraData) ->
  children: -> @_children
  setChildren: (newChildren) ->
    new TestNode(newChildren, @_extraData)

test "Spread::_applyEnvToTree works", (t) ->
  tree = new Spread([
    [
      {x: 0}
      new TestNode([
        new Spread([
          [{y: 0}, new TestNode([], 1)]
          [{y: 1}, new TestNode([], 2)]
        ])
      ])
    ]
    [
      {x: 1}
      new TestNode([
        new Spread([
          [{y: 0}, new TestNode([], 3)]
          [{y: 1}, new TestNode([], 4)]
        ])
      ])
    ]
  ])
  expectedTreeWhenYIs0 = new Spread([
    [
      {x: 0}
      new TestNode([
        new Spread([
          [{}, new TestNode([], 1)]
        ])
      ])
    ]
    [
      {x: 1}
      new TestNode([
        new Spread([
          [{}, new TestNode([], 3)]
        ])
      ])
    ]
  ])
  expectedTreeWhenYIs1 = new Spread([
    [
      {x: 0}
      new TestNode([
        new Spread([
          [{}, new TestNode([], 2)]
        ])
      ])
    ]
    [
      {x: 1}
      new TestNode([
        new Spread([
          [{}, new TestNode([], 4)]
        ])
      ])
    ]
  ])
  expectedTreeWhenXIs1AndYIs0 = new Spread([
    [
      {}
      new TestNode([
        new Spread([
          [{}, new TestNode([], 3)]
        ])
      ])
    ]
  ])

  t.deepEqual(tree._applyEnvToTree({}), tree)
  t.deepEqual(tree._applyEnvToTree({y: 0}), expectedTreeWhenYIs0)
  t.deepEqual(tree._applyEnvToTree({y: 1}), expectedTreeWhenYIs1)
  t.deepEqual(tree._applyEnvToTree({x: 1, y: 0}), expectedTreeWhenXIs1AndYIs0)
  t.end()

test "Spread::multimap2WithTrees works", (t) ->
  spread = new Spread([
    [{y: 0}, 20]
    [{y: 1}, 21]
  ])

  tree1 = new Spread([
    [
      {x: 0}
      new TestNode([
        new Spread([
          [{y: 0}, new TestNode([], 1)]
          [{y: 1}, new TestNode([], 2)]
        ])
      ])
    ]
    [
      {x: 1}
      new TestNode([
        new Spread([
          [{y: 0}, new TestNode([], 3)]
          [{y: 1}, new TestNode([], 4)]
        ])
      ])
    ]
  ])

  tree2 = new Spread([
    [
      {x: 0}
      new TestNode([
        new Spread([
          [{y: 0}, new TestNode([], 11)]
          [{y: 1}, new TestNode([], 12)]
        ])
      ])
    ]
    [
      {x: 1}
      new TestNode([
        new Spread([
          [{y: 0}, new TestNode([], 13)]
          [{y: 1}, new TestNode([], 14)]
        ])
      ])
    ]
  ])


  func = (spreadVal, treeSpreads) ->
    new TestNode(treeSpreads, spreadVal)

  expectedOutput = new Spread([
    [
      {y: 0}
      new TestNode([
        new Spread([
          [
            {x: 0}
            new TestNode([
              new Spread([
                [{}, new TestNode([], 1)]
              ])
            ])
          ]
          [
            {x: 1}
            new TestNode([
              new Spread([
                [{}, new TestNode([], 3)]
              ])
            ])
          ]
        ])
        new Spread([
          [
            {x: 0}
            new TestNode([
              new Spread([
                [{}, new TestNode([], 11)]
              ])
            ])
          ]
          [
            {x: 1}
            new TestNode([
              new Spread([
                [{}, new TestNode([], 13)]
              ])
            ])
          ]
        ])
      ], 20)
    ]
    [
      {y: 1}
      new TestNode([
        new Spread([
          [
            {x: 0}
            new TestNode([
              new Spread([
                [{}, new TestNode([], 2)]
              ])
            ])
          ]
          [
            {x: 1}
            new TestNode([
              new Spread([
                [{}, new TestNode([], 4)]
              ])
            ])
          ]
        ])
        new Spread([
          [
            {x: 0}
            new TestNode([
              new Spread([
                [{}, new TestNode([], 12)]
              ])
            ])
          ]
          [
            {x: 1}
            new TestNode([
              new Spread([
                [{}, new TestNode([], 14)]
              ])
            ])
          ]
        ])
      ], 21)
    ]
  ])

  t.deepEqual(spread.multimap2WithTrees([tree1, tree2], func), expectedOutput)
  t.end()

test "Spread::multimap2WithTreeObject works", (t) ->
  spread = new Spread([
    [{y: 0}, 20]
    [{y: 1}, 21]
  ])

  tree1 = new Spread([
    [
      {x: 0}
      new TestNode([
        new Spread([
          [{y: 0}, new TestNode([], 1)]
          [{y: 1}, new TestNode([], 2)]
        ])
      ])
    ]
    [
      {x: 1}
      new TestNode([
        new Spread([
          [{y: 0}, new TestNode([], 3)]
          [{y: 1}, new TestNode([], 4)]
        ])
      ])
    ]
  ])

  tree2 = new Spread([
    [
      {x: 0}
      new TestNode([
        new Spread([
          [{y: 0}, new TestNode([], 11)]
          [{y: 1}, new TestNode([], 12)]
        ])
      ])
    ]
    [
      {x: 1}
      new TestNode([
        new Spread([
          [{y: 0}, new TestNode([], 13)]
          [{y: 1}, new TestNode([], 14)]
        ])
      ])
    ]
  ])


  func = (spreadVal, {tree1, tree2}) ->
    new TestNode([tree1, tree2], spreadVal)

  expectedOutput = new Spread([
    [
      {y: 0}
      new TestNode([
        new Spread([
          [
            {x: 0}
            new TestNode([
              new Spread([
                [{}, new TestNode([], 1)]
              ])
            ])
          ]
          [
            {x: 1}
            new TestNode([
              new Spread([
                [{}, new TestNode([], 3)]
              ])
            ])
          ]
        ])
        new Spread([
          [
            {x: 0}
            new TestNode([
              new Spread([
                [{}, new TestNode([], 11)]
              ])
            ])
          ]
          [
            {x: 1}
            new TestNode([
              new Spread([
                [{}, new TestNode([], 13)]
              ])
            ])
          ]
        ])
      ], 20)
    ]
    [
      {y: 1}
      new TestNode([
        new Spread([
          [
            {x: 0}
            new TestNode([
              new Spread([
                [{}, new TestNode([], 2)]
              ])
            ])
          ]
          [
            {x: 1}
            new TestNode([
              new Spread([
                [{}, new TestNode([], 4)]
              ])
            ])
          ]
        ])
        new Spread([
          [
            {x: 0}
            new TestNode([
              new Spread([
                [{}, new TestNode([], 12)]
              ])
            ])
          ]
          [
            {x: 1}
            new TestNode([
              new Spread([
                [{}, new TestNode([], 14)]
              ])
            ])
          ]
        ])
      ], 21)
    ]
  ])

  t.deepEqual(spread.multimap2WithTreeObject({tree1, tree2}, func), expectedOutput)
  t.end()

test "Spreads work", (t) ->
  a = Spread.fromArray([0 ... 10])
  b = Spread.multimap({a}, ({a}) -> a * 2)
  c = Spread.multimap({a, b}, ({a, b}) -> a + b)
  t.deepEqual(a.toArray(), [0 ... 10])
  t.deepEqual(b.toArray(), [0, 2, 4, 6, 8, 10, 12, 14, 16, 18])
  t.deepEqual(c.toArray(), [0, 3, 6, 9, 12, 15, 18, 21, 24, 27])
  t.end()

test "Spreads cross product", (t) ->
  a = Spread.fromArray([0 ... 4])
  b = Spread.fromArray([10, 20])
  c = Spread.multimap({a, b}, ({a, b}) -> a * b)
  t.deepEqual(_.sortBy(c.toArray()), [0, 0, 10, 20, 20, 30, 40, 60])
  t.end()

test "Spreads tree", (t) ->
  a = Spread.fromArray([0 ... 4])
  b = Spread.multimap({a}, ({a}) -> Spread.fromArray([0 ... a])).join()
  c = Spread.multimap({a, b}, ({a, b}) -> a * b)
  t.deepEqual(_.sortBy(c.toArray()), [0, 0, 0, 2, 3, 6])
  t.end()

test "Spreads rejoin", (t) ->
  a = Spread.fromArray([0 ... 10])
  b = Spread.multimap({a}, ({a}) -> a * 2)
  c = Spread.multimap({a}, ({a}) -> a * 3)
  d = Spread.multimap({b, c}, ({b, c}) -> b + c)
  t.deepEqual(a.toArray(), [0 ... 10])
  t.deepEqual(b.toArray(), [0, 2, 4, 6, 8, 10, 12, 14, 16, 18])
  t.deepEqual(c.toArray(), [0, 3, 6, 9, 12, 15, 18, 21, 24, 27])
  t.deepEqual(d.toArray(), [0, 5, 10, 15, 20, 25, 30, 35, 40, 45])
  t.end()

test "All spreads should try to resolve as deep as possible", (t) ->
  a = Spread.fromArray([0, 1])
  b = Spread.multimap({a}, ({a}) -> a  * 2)
  c = Spread.multimap({a, b}, ({a, b}) -> {a: a, b: b})
  t.deepEqual(c.toArray(), [{a: 0, b: 0}, {a: 1, b: 2}])
  d = Spread.multimap({b}, ({b}) -> {b: b})
  t.deepEqual(d.toArray(), [{b: 0}, {b: 2}])
  # Keeping "b" out of the "multimap" stops the propagation of the spread upwards in the expression.
  e = {b: b}
  t.deepEqual(e.b.toArray(), [0, 2])
  t.end()
