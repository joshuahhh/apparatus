export default {
  nodes: [
    {id: 'Fluffy', name: 'Fluffy', width: 80, height: 60},  // introduceOn: 'breakpoint-object'},
    {id: 'Fluffy.mood', name: '"happy"', width: 80, height: 24, type: 'prop', introduceOn: 'breakpoint-props'},
    {id: 'Fluffy.mew', name: '[func]', width: 80, height: 24, type: 'prop', introduceOn: 'breakpoint-props'},
    {id: 'Whiskers', name: 'Whiskers', width: 80, height: 60, introduceOn: 'breakpoint-object2'},
    {id: 'Whiskers.mood', name: '"happy"', width: 80, height: 24, type: 'prop', introduceOn: 'breakpoint-object2'},
    {id: 'Whiskers.mew', name: '[func]', width: 80, height: 24, type: 'prop', introduceOn: 'breakpoint-object2'},
  ],
  links: [
    {sourceId: 'Fluffy.mood', targetId: 'Fluffy', type: 'parent1', label: 'mood'},
    {sourceId: 'Fluffy.mew', targetId: 'Fluffy', type: 'parent2', label: 'mew'},
    {sourceId: 'Whiskers.mood', targetId: 'Whiskers', type: 'parent1', label: 'mood'},
    {sourceId: 'Whiskers.mew', targetId: 'Whiskers', type: 'parent2', label: 'mew'},
  ],
	groups: [
	],
  constraints: [
    {leftId: 'Fluffy.mood', rightId: 'Fluffy.mew', type: 'separation', axis: 'x', gap: 100},
    {leftId: 'Whiskers.mood', rightId: 'Whiskers.mew', type: 'separation', axis: 'x', gap: 100}
  ]
};
