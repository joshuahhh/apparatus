import React from 'react';
import d3 from 'd3';

import ColaGraph from './ColaGraph';

const width = 1300;
const height = 900;

var ApparatusGraph = React.createClass({
  getInitialState() {
    return {
      graph: undefined,
    };
  },

  render() {
    const {graph} = this.state;

    return (
      <div>
        <svg width={width} height={height}>
          {graph &&
            <ColaGraph width={width} height={height} graph={graph}
              colaOptions={{
                linkDistance: 10,
                avoidOverlaps: true,
              }} />
          }
        </svg>
      </div>
    );
  },

  componentDidMount() {
    d3.json("apparatus.json", (error, graph) => {
      graph.nodes.forEach(function (v) {
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
      graph.constraints.push({"axis":"x", "leftId":1, "rightId":2, "gap":100,
        type: 'separation'});
      graph.constraints.push({"axis":"x", "leftId":4, "rightId":5, "gap":100,
        type: 'separation'});
      graph.constraints.push({"axis":"x", "leftId":12, "rightId":3, "gap":100,
        type: 'separation'});
      graph.constraints.push({"axis":"x", "leftId":14, "rightId":8, "gap":100,
        type: 'separation'});

      this.setState({graph: graph});
    });
  },
});


export default ApparatusGraph;
