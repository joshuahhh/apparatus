import React from 'react';
import update from 'react-addons-update';
import _ from 'underscore';


var ScriptFollower = React.createClass({
  propTypes: {
    initialState: React.PropTypes.object.isRequired,
    steps: React.PropTypes.arrayOf(
      React.PropTypes.shape({
        name: React.PropTypes.string.isRequired,
        stateUpdater: React.PropTypes.object.isRequired,
      }).isRequired
    ).isRequired,
    curStepName: React.PropTypes.string,  // if elided, initial state
    children: React.PropTypes.any,
  },

  computeCurState() {
    const {initialState, steps, curStepName} = this.props;

    if (!curStepName) {
      return _.clone(initialState);
    }
    const curStepIndex = _.findIndex(steps, (step) => step.name == curStepName);
    if (curStepIndex === -1) {
      return undefined;
    }
    const stepsToPerform = steps.slice(0, curStepIndex + 1);

    var state = initialState;
    // const setState = (nextState) => {
    //   if (_.isFunction(nextState)) {
    //     nextState = nextState(state);
    //   }
    //   _.extend(state, nextState);
    // };
    // stepsToPerform.each((step) => step.onStep(setState));
    stepsToPerform.forEach((step) => {
      state = update(state, step.stateUpdater);
    });
    // todo: state transformer? state mutator?
    return _.clone(state);
  },

  render() {
    const {children} = this.props;
    const curState = this.computeCurState();

    return children(curState);
  },

});


export default ScriptFollower;
