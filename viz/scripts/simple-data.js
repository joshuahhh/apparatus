export default {
  nodes: [
    {id: 'Fluffy', label: 'Fluffy', width: 80, height: 60},
    {id: 'Fluffy_mood', label: '"happy"', width: 80, height: 24, type: 'prop'},
    {id: 'Fluffy_mew', label: '[func]', width: 80, height: 24, type: 'prop'},
    {id: 'Whiskers', label: 'Whiskers', width: 80, height: 60},
    {id: 'Whiskers_mood', label: '"happy"', width: 80, height: 24, type: 'prop'},
    {id: 'Whiskers_mew', label: '[func]', width: 80, height: 24, type: 'prop'},
  ],
  links: [
    {sourceId: 'Fluffy_mood', targetId: 'Fluffy', type: 'parent1', label: 'mood'},
    {sourceId: 'Fluffy_mew', targetId: 'Fluffy', type: 'parent2', label: 'mew'},
    {sourceId: 'Whiskers_mood', targetId: 'Whiskers', type: 'parent1', label: 'mood'},
    {sourceId: 'Whiskers_mew', targetId: 'Whiskers', type: 'parent2', label: 'mew'},
  ],
	groups: [
	],
  constraints: [
    {leftId: 'Fluffy_mood', rightId: 'Fluffy_mew', type: 'separation', axis: 'x', gap: 100},
    {leftId: 'Whiskers_mood', rightId: 'Whiskers_mew', type: 'separation', axis: 'x', gap: 100}
  ]
};
