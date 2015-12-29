export default {
  nodes: [
    {id: 'TodoList', label: 'TodoList', width: 100, height: 40},
    {id: 'TodoList_render', label: 'function', width: 80, height: 24, type: 'prop', style: {fontStyle: 'italic'}},
    {id: 'TodoList_render_ghost', label: 'function', width: 80, height: 24, type: 'prop', style: {fontStyle: 'italic'}, ghost: true},
    {id: 'TodoList_todos', label: '["Run", "Play"]', width: 80, height: 24, type: 'prop'},
    {id: 'TodoList2', label: 'TodoList2', width: 100, height: 40},
    {id: 'TodoList2_render', label: 'function', width: 80, height: 24, type: 'prop', style: {fontStyle: 'italic'}},
    {id: 'TodoList2_render_ghost', label: 'function', width: 80, height: 24, type: 'prop', style: {fontStyle: 'italic'}, ghost: true},
    {id: 'TodoList2_todos', label: '["Work", "Sleep"]', width: 80, height: 24, type: 'prop'},
    {id: 'TodoListProto', label: 'TodoListProto', width: 130, height: 40},
    {id: 'TodoListProto_render', label: 'function', width: 80, height: 24, type: 'prop', style: {fontStyle: 'italic'}},
  ],
  links: [
    {sourceId: 'TodoList_render', targetId: 'TodoList', type: 'parent1', label: 'render'},
    {sourceId: 'TodoList_render_ghost', targetId: 'TodoList', type: 'parent1', label: 'render', ghost: true},
    {sourceId: 'TodoList_todos', targetId: 'TodoList', type: 'parent2', label: 'todos'},
    {sourceId: 'TodoList2_render', targetId: 'TodoList2', type: 'parent1', label: 'render'},
    {sourceId: 'TodoList2_render_ghost', targetId: 'TodoList2', type: 'parent1', label: 'render', ghost: true},
    {sourceId: 'TodoList2_todos', targetId: 'TodoList2', type: 'parent2', label: 'todos'},
    {sourceId: 'TodoListProto_render', targetId: 'TodoListProto', type: 'parent1', label: 'render'},
    {sourceId: 'TodoList', targetId: 'TodoListProto', type: 'master-head'},
    {sourceId: 'TodoList2', targetId: 'TodoListProto', type: 'master-head'},
  ],
	groups: [
	],
  constraints: [
    {leftId: 'TodoList_render', rightId: 'TodoList', type: 'separation', axis: 'x', gap: 70},
    {leftId: 'TodoList_render_ghost', rightId: 'TodoList', type: 'separation', axis: 'x', gap: 70},
    {leftId: 'TodoList', rightId: 'TodoList_todos', type: 'separation', axis: 'x', gap: 70},
    {leftId: 'TodoList2_render', rightId: 'TodoList2', type: 'separation', axis: 'x', gap: 70},
    {leftId: 'TodoList2_render_ghost', rightId: 'TodoList2', type: 'separation', axis: 'x', gap: 70},
    {leftId: 'TodoList2', rightId: 'TodoList2_todos', type: 'separation', axis: 'x', gap: 70},
    {leftId: 'TodoList_render', rightId: 'TodoList2', type: 'separation', axis: 'y', gap: 90},
    {leftId: 'TodoList_todos', rightId: 'TodoList2', type: 'separation', axis: 'y', gap: 90},
    {leftId: 'TodoListProto_render', rightId: 'TodoListProto', type: 'separation', axis: 'x', gap: 70},
  ]
};
