import React from 'react';
import update from 'react-addons-update';
import _ from 'underscore';

import ColaGraph from './ColaGraph';
import graph from '../simple-data';


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

    graph.constraints = graph.constraints || [];

    graph.links.forEach(function (e) {
      if (e.type === 'parent1') {
        graph.constraints.push({"axis":"y", "leftId":e.targetId, "rightId":e.sourceId, "gap":150,
          type: 'separation'});
      } else if (e.type === 'parent2') {
        graph.constraints.push({"axis":"y", "leftId":e.targetId, "rightId":e.sourceId, "gap":200,
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
      console.log(i);
      const goodNodes = realNodes.filter((node) => !node.introduceOn || _.contains(_.pluck(i, 'pos'), '#' + node.introduceOn));
      // console.log('doin it', i, goodNodes);
      const newGraph = update(graph, {nodes: {$set: goodNodes}});
      this.setState({graph: newGraph});
    };
  },

  shouldComponentUpdate(nextProps, nextState) {
    return !(
      nextProps.width === this.props.width
      && nextProps.height === this.props.height
      && nextState.graph === this.state.graph
    );
  },

  render() {
    const {width, height} = this.props;
    const {graph} = this.state;

    return (
      graph
      ? <ColaGraph width={width} height={height} graph={graph}
          colaOptions={{
            linkDistance: 10,
            avoidOverlaps: true,
          }} />
      : <g/>
    );
  },

});


export default ApparatusGraph;
