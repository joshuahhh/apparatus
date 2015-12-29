import React from 'react';

import ElasticSvg from './ElasticSvg';
import StickyExpander from './StickyExpander';


var GenericRightPane = React.createClass({
  render() {
    const {svgHeight} = this.props;

    return (
      <StickyExpander minHeight={svgHeight}>
        {({height}) =>
          <ElasticSvg height={svgHeight} style={{position: 'relative', top: (height - svgHeight) / 2}}>
            {({width}) => width &&
              React.cloneElement(this.props.children, {width, height: svgHeight})
            }
          </ElasticSvg>
        }
      </StickyExpander>
    );
  },

});


export default GenericRightPane;
