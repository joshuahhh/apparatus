const initialState = {
  nodesToShow: {TodoList: true},
  svgHeight: 650,
};

const steps = [
  {
    name: 'props',
    stateUpdater: {
      nodesToShow: {
        TodoList_render: {$set: true}, TodoList_todos: {$set: true}
      },
      svgHeight: {$set: 650},
    },
  },
  {
    name: 'object2',
    stateUpdater: {
      nodesToShow: {
        TodoList2: {$set: true}, TodoList2_render: {$set: true}, TodoList2_todos: {$set: true}
      },
      svgHeight: {$set: 650},
    },
  },
  {
    name: 'proto',
    stateUpdater: {
      nodesToShow: {
        TodoListProto: {$set: true}, TodoListProto_render: {$set: true},
        TodoList_render: {$set: false}, TodoList2_render: {$set: false}
      },
    },
  },
  {
    name: 'ghosts',
    stateUpdater: {
      nodesToShow: {
        TodoList_render_ghost: {$set: true}, TodoList2_render_ghost: {$set: true},
      },
    },
  }
];

export {initialState, steps};
