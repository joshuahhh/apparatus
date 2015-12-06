import React from 'react';

import ElasticSvg from './ElasticSvg';
import StickyExpander from './StickyExpander';
import ColaGraph from './ColaGraph';
import graph from '../data';


var ApparatusGraph = React.createClass({
  getInitialState() {
    return {
      graph: this.getGraph(),
    };
  },

  getGraph() {
    const realNodes = graph.nodes;
    realNodes.forEach(function (v) {
        // console.log(JSON.stringify(v));
        // v.width = v.height = nodeSize;
        v.width *= 1.4;
        v.height *= 1.4;
    });
    graph.groups.forEach(function (g) { g.padding = 10; });

    graph.constraints = [];

    graph.links.forEach(function (e) {
      if (e.type === 'parent1') {
        graph.constraints.push({"axis":"y", "leftId":e.targetId, "rightId":e.sourceId, "gap":150,
          type: 'separation'});
      } else if (e.type === 'parent2') {
        graph.constraints.push({"axis":"y", "leftId":e.targetId, "rightId":e.sourceId, "gap":250,
          type: 'separation'});
      } else if (e.type === 'master' || e.type === 'master-head') {
        graph.constraints.push({"axis":"x", "leftId":e.targetId, "rightId":e.sourceId, "gap":200,
          type: 'separation'});
      }
    });
    graph.constraints.push({"axis":"x", "leftId":"Rect-w", "rightId":"Rect-h", "gap":100,
      type: 'separation'});
    graph.constraints.push({"axis":"x", "leftId":"MyRect-w", "rightId":"MyRect-h", "gap":100,
      type: 'separation'});
    graph.constraints.push({"axis":"x", "leftId":12, "rightId":"MyRect", "gap":100,
      type: 'separation'});
    graph.constraints.push({"axis":"x", "leftId":14, "rightId":8, "gap":100,
      type: 'separation'});

    window.doit = (i) => {
      graph.nodes = realNodes.slice(0, i);
      this.setState({graph: graph});
    };
  },

  render() {
    const {graph} = this.state;

    return (
      <StickyExpander minHeight={500}>
        {({height}) =>
          <ElasticSvg height={height}>
            {({width}) => graph &&
              <g>
                <rect width={width} height={height/2} fill='blue' />
                <rect width={width} height={height/2} y={height/2} fill='red' />
              </g>
              // <ColaGraph width={width} height={height} graph={graph}
              //   colaOptions={{
              //     linkDistance: 10,
              //     avoidOverlaps: true,
              //   }} />
            }
          </ElasticSvg>
        }
      </StickyExpander>
    );
  },

});


export default ApparatusGraph;
