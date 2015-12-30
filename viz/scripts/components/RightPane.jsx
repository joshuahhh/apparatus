import React from 'react';

import ScriptFollower from './ScriptFollower';
import GenericRightPane from './GenericRightPane';
import ApparatusGraph from './ApparatusGraph';

import {initialState, steps} from '../script';

var RightPane = React.createClass({
  render() {
    const {breakpoint, nodeToHighlight} = this.props;
    const curStepName = breakpoint && breakpoint.replace('#breakpoint-', '');

    return (
      <ScriptFollower initialState={initialState} steps={steps} curStepName={curStepName}>
        {({nodesToShow, svgHeight}) =>
          <GenericRightPane svgHeight={svgHeight}>
            <ApparatusGraph nodesToShow={nodesToShow} nodeToHighlight={nodeToHighlight}/>
          </GenericRightPane>
        }
      </ScriptFollower>
    );
  }
});

export default RightPane;
