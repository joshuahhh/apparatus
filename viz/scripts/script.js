const initialState = {
  nodesToShow: {'Fluffy': true},
  svgHeight: 200,
};

const steps = [
  {
    name: 'props',
    stateUpdater: {
      nodesToShow: {Fluffy_mood: {$set: true}, Fluffy_mew: {$set: true}},
      svgHeight: {$set: 400},
    },
  },
  {
    name: 'object2',
    stateUpdater: {
      nodesToShow: {Whiskers: {$set: true}, Whiskers_mood: {$set: true}, Whiskers_mew: {$set: true}},
      svgHeight: {$set: 600},
    },
  }
];

export {initialState, steps};
