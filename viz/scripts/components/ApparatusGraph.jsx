import React from 'react';
import d3 from 'd3';

import ColaGraph from './ColaGraph';

const width = 1100;
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
      graph.groups.forEach(function (g) { g.padding = 20; });

      graph.constraints = [];

      graph.links.forEach(function (e) {
        if (e.type === 'parent1') {
          graph.constraints.push({"axis":"y", "left":e.target, "right":e.source, "gap":150,
            type: 'separation'});
        } else if (e.type === 'parent2') {
          graph.constraints.push({"axis":"y", "left":e.target, "right":e.source, "gap":250,
            type: 'separation'});
        } else if (e.type === 'master' || e.type === 'master-head') {
          graph.constraints.push({"axis":"x", "left":e.target, "right":e.source, "gap":300,
            type: 'separation'});
        }
      });
      graph.constraints.push({"axis":"x", "left":1, "right":2, "gap":100,
        type: 'separation'});
      graph.constraints.push({"axis":"x", "left":4, "right":5, "gap":100,
        type: 'separation'});
      graph.constraints.push({"axis":"x", "left":12, "right":3, "gap":100,
        type: 'separation'});
      graph.constraints.push({"axis":"x", "left":14, "right":8, "gap":100,
        type: 'separation'});

      this.setState({graph: graph});
    });
  },
});


export default ApparatusGraph;
