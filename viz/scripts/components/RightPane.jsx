import React from 'react';

import ScriptFollower from './ScriptFollower';
import GenericRightPane from './GenericRightPane';
import ApparatusGraph from './ApparatusGraph';

import {initialState, steps} from '../script';

var RightPane = React.createClass({
  render() {
    const {breakpoint} = this.props;
    const curStepName = breakpoint && breakpoint.replace('#breakpoint-', '');

    return (
      <ScriptFollower initialState={initialState} steps={steps} curStepName={curStepName}>
        {({nodesToShow, svgHeight}) =>
          <GenericRightPane svgHeight={svgHeight}>
            <ApparatusGraph nodesToShow={nodesToShow} />
          </GenericRightPane>
        }
      </ScriptFollower>
    );
  }
});

export default RightPane;
