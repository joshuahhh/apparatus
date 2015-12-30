import React from 'react';
import update from 'react-addons-update';
import _ from 'underscore';

import ColaGraph from './ColaGraph';
import graph from '../simple-data';


var ApparatusGraph = React.createClass({
  getInitialState() {
    return {
      baseGraph: this.getBaseGraph(),
    };
  },

  getBaseGraph() {
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
        graph.constraints.push({
          axis: "y",
          leftId: e.sourceId, rightId: e.targetId,
          type: 'separation', gap: 150});
      } else if (e.type === 'parent2') {
        graph.constraints.push({
          axis: "y",
          leftId: e.sourceId, rightId: e.targetId,
          type: 'separation', gap: 200});
      } else if (e.type === 'master' || e.type === 'master-head') {
        graph.constraints.push({
          axis: "x",
          leftId: e.targetId, rightId: e.sourceId,
          type: 'separation', gap: 200});
      }
    });

    return graph;
  },

  getGraph() {
    const {nodesToShow, nodeToHighlight} = this.props;
    const {baseGraph} = this.state;

    const goodNodes = baseGraph.nodes.filter((node) => nodesToShow[node.id]);
    const newGraph = update(baseGraph, {nodes: {$set: goodNodes}});

    newGraph.nodes.forEach((node) =>
      node.hovered = (node.id === nodeToHighlight)
    );

    return newGraph;
  },

  shouldComponentUpdate(nextProps, _nextState) {
    const toReturn = !(
      nextProps.width === this.props.width
      && nextProps.height === this.props.height
      && nextProps.nodeToHighlight === this.props.nodeToHighlight
      && _.isEqual(nextProps.nodesToShow, this.props.nodesToShow)
    );
    return toReturn;
  },

  render() {
    const {width, height} = this.props;
    const graph = this.getGraph();

    console.log('ApparatusGraph::render', this.props.breakpoint);

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
