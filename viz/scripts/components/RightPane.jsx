import React from 'react';

import ElasticSvg from './ElasticSvg';
import StickyExpander from './StickyExpander';
import ApparatusGraph from './ApparatusGraph';

const svgHeight = 400;


var RightPane = React.createClass({
  render() {
    return (
      <StickyExpander minHeight={svgHeight}>
        {({height}) =>
          <ElasticSvg height={svgHeight} style={{position: 'relative', top: (height - svgHeight) / 2}}>
            {({width}) => width &&
              <ApparatusGraph width={width} height={svgHeight} />
              // <g>
              //   <rect width={width} height={height/2} fill='blue' />
              //   <rect width={width} height={height/2} y={height/2} fill='red' />
              // </g>
            }
          </ElasticSvg>
        }
      </StickyExpander>
    );
  },

});


export default RightPane;
