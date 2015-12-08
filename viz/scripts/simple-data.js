export default {
  nodes: [
    {id: 'Fluffy', name: 'Fluffy', width: 80, height: 60, introduceOn: 'breakpoint-object'},
    {id: 'mood', name: '"happy"', width: 80, height: 24, type: 'prop', introduceOn: 'breakpoint-props'},
    {id: 'mew', name: '[func]', width: 80, height: 24, type: 'prop', introduceOn: 'breakpoint-props'},
  ],
  links: [
    {sourceId: 'mood', targetId: 'Fluffy', type: 'parent1', label: 'mood'},
    {sourceId: 'mew', targetId: 'Fluffy', type: 'parent2', label: 'mew'},
  ],
	groups: [
	],
  constraints: [
    {leftId: 'mood', rightId: 'mew', type: 'separation', axis: 'x', gap: 100}
  ]
};
