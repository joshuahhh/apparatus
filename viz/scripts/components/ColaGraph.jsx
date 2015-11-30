import React from 'react';
import d3 from 'd3';
import _ from 'underscore';
import rectConnect from 'rect-connect';

import Draggable from './Draggable';

/* Data flow:
 *
 *   myKindaGraph  --->  colaGraph  --->  colaGraphAdaptor
 *                                   ^           |
 *                                   |           |
 *                                   +-----------+
 *                            (once there's an adaptor already)
 */


const color = d3.scale.category20();

const markerHtml = `
  <marker
      id='end-arrow' viewBox='0 -5 10 10' refX='6'
      markerWidth='3' markerHeight='3' orient='auto'>
    <path d='M0,-5L10,0L0,5' fill='#7a4e4e' />
  </marker>
`;

const myKindaGraphToColaGraph = function(myKindaGraph, oldColaGraph) {
  // FORMAT FOR MY KINDA GRAPH
  //   Node:
  //     id
  //     label
  //     ...
  //   Link:
  //     sourceId
  //     targetId
  //     type
  //   Group:
  //     id
  //     memberIds
  //   Constraints:
  //     leftId
  //     rightId
  //     ...

  const {nodes, links, groups, constraints} = myKindaGraph;

  const {nodes: oldNodes, groups: oldGroups} = oldColaGraph;
  const oldNodesById = _.indexBy(oldNodes, 'id');
  const oldGroupsById = _.indexBy(oldGroups, 'id');

  const outNodes = nodes.map(({id, label, ...other}) => {
    // const oldNode = _.pick(oldNodesById[id] || {}, 'x', 'y');
    const oldNode = {};
    return _.defaults({
      id,
      name: label,
      x: oldNode.x,
      y: oldNode.x,
      ...other
    }, oldNode);
  });
  const outNodesById = _.indexBy(outNodes, 'id');

  const outLinks = _.compact(links.map(({sourceId, targetId, type, ...other}) => {
    const source = outNodesById[sourceId];
    const target = outNodesById[targetId];
    if (source && target) {  // objects or undefineds
      return {
        source,
        target,
        type,
        ...other
      };
    }
  }));

  const outGroups = _.compact(groups.map(({id, memberIds, ...other}) => {
    // Filter out references to missing nodes
    const leavesMaybeMissing = memberIds.map((id) => outNodes.indexOf(outNodesById[id]));
    const leaves = _.without(leavesMaybeMissing, -1);
    if (leaves.length > 0) {
      const oldGroup = _.pick(oldGroupsById[id] || {}, 'bounds');
      // const oldGroup = {};
      return _.defaults({
        id,
        leaves,
        ...other
      }, oldGroup);
    }
  }));

  const outConstraints = _.compact(constraints.map(({leftId, rightId, ...other}) => {
    const left = outNodes.indexOf(outNodesById[leftId]);
    const right = outNodes.indexOf(outNodesById[rightId]);
    if ((left !== -1) && (right !== -1)) {
      return {
        left,
        right,
        ...other
      };
    }
  }));

  const colaGraph = {
    nodes: outNodes,
    links: outLinks,
    groups: outGroups,
    constraints: outConstraints
  };

  return colaGraph;
};

const extractColaGraphFromColaGraphAdaptor = function(colaGraphAdaptor) {
  return {
    nodes: colaGraphAdaptor.nodes(),
    links: colaGraphAdaptor.links(),
    groups: colaGraphAdaptor.groups(),
    constraints: colaGraphAdaptor.constraints(),
  };
};


const ColaGraphGroup = ({group, order}) =>
  <rect className='group' rx={8} ry={8} fill={color(order)}
    x={group.bounds.x} y={group.bounds.y} width={group.bounds.width()} height={group.bounds.height()}
  />;

const ColaGraphNode = React.createClass({
  // TODO: Deep mutation of props? Really?
  // (should probably be handled by ColaGraph)

  onDragStart() {
    var {node} = this.props;
    node.fixed = true;
    node.px = node.x;
    node.py = node.y;
  },

  onDrag() {
    this.props.node.px += d3.event.dx;
    this.props.node.py += d3.event.dy;
    this.props.relayout();
  },

  onDragEnd() {
    this.props.node.fixed = false;
  },

  render() {
    const {node} = this.props;

    return (
      <Draggable onDragStart={this.onDragStart} onDrag={this.onDrag} onDragEnd={this.onDragEnd}>
        <g className='node-g'>
          <rect className='node' width={node.width} height={node.height}
            rx={5} ry={5}
            x={node.x - node.width / 2} y={node.y - node.height / 2}/>
          <text className='g-label' x={node.x} y={node.y}>{node.name}</text>
        </g>
      </Draggable>
    );
  },
});

const ColaGraphLink = ({link}) => {
  const connection = rectConnect(link.source, link.source, link.target, link.target);
  const sourceX = connection.source.x, sourceY = connection.source.y;
  const targetX = connection.target.x, targetY = connection.target.y;
  const pathD = 'M' + sourceX + ',' + sourceY + 'L' + targetX + ',' + targetY;

  if (_.isNaN(sourceX)) {
    console.log('bad!', link);
  }

  return (
    <g>
      <g dangerouslySetInnerHTML={{__html: markerHtml}} />
      <path className={'link type-' + link.type} d={pathD} />
    </g>
  );
};

const ColaGraph = React.createClass({
  propTypes: {
    width: React.PropTypes.number.isRequired,
    height: React.PropTypes.number.isRequired,
    colaOptions: React.PropTypes.object,
  },

  getDefaultProps() {
    return {
      GroupClass: ColaGraphGroup,
      NodeClass: ColaGraphNode,
      LinkClass: ColaGraphLink,
    };
  },

  getInitialState() {
    const {width, height, colaOptions, graph} = this.props;

    var colaGraphAdaptor = window.cola.d3adaptor();
    colaGraphAdaptor.size([width, height]);
    _(colaOptions || {}).each((value, key) => colaGraphAdaptor[key](value));

    loadMyKindaGraphIntoColaGraphAdaptor(graph, colaGraphAdaptor);

    colaGraphAdaptor
      .start(2, 2000, 2000)
      .on("tick", this.rerender);
    window.colaGraphAdaptor = colaGraphAdaptor;

    return {
      colaGraphAdaptor: colaGraphAdaptor,
    };
  },

  componentWillReceiveProps(nextProps) {
    if (true || nextProps.graph !== this.props.graph) {
      const {colaGraphAdaptor} = this.state;
      makeColaGraphAdaptor(nextProps.graph, colaGraphAdaptor);
      this.setState({colaGraphAdaptor});
      // this.state.colaGraphAdaptor.start(2, 2000, 2000);
      this.state.colaGraphAdaptor.resume();
    }
  },

  makeColaGraphAdaptor()  {
    const {width, height, colaOptions, graph} = this.props;

    var colaGraphAdaptor = window.cola.d3adaptor();
    colaGraphAdaptor.size([width, height]);
    _(colaOptions || {}).each((value, key) => colaGraphAdaptor[key](value));

    const oldColaGraph = extractColaGraphFromColaGraphAdaptor(colaGraphAdaptor);
    const colaGraph = myKindaGraphToColaGraph(graph, oldColaGraph);
    colaGraphAdaptor
      .nodes(colaGraph.nodes)
      .links(colaGraph.links)
      .groups(colaGraph.groups)
      .constraints(colaGraph.constraints);

    colaGraphAdaptor
      .start(2, 2000, 2000)
      .on("tick", this.rerender);
    window.colaGraphAdaptor = colaGraphAdaptor;

    return colaGraphAdaptor;
  },

  relayout() {
    this.state.colaGraphAdaptor.resume();
  },

  rerender() {
    this.setState({colaGraphAdaptor: this.state.colaGraphAdaptor});
  },

  render() {
    const {GroupClass, NodeClass, LinkClass} = this.props;
    const {colaGraphAdaptor} = this.state;
    const groups = colaGraphAdaptor.groups();
    const nodes = colaGraphAdaptor.nodes();
    const links = colaGraphAdaptor.links();
    window.groups = groups;
    window.colaGraphAdaptor = colaGraphAdaptor;

    const renderedGroups = groups.map((group, i) => group.bounds &&
      <GroupClass key={group.id} order={i} group={group} colaGraphAdaptor={colaGraphAdaptor} relayout={this.relayout} />
    );

    console.log('x', _.findWhere(nodes, {id: "MyRect"}));
    const renderedNodes = nodes.map((node, i) => node.x && node.y &&
      <NodeClass key={node.id} order={i} node={node} colaGraphAdaptor={colaGraphAdaptor} relayout={this.relayout} />
    );

    const renderedLinks = links.map((link, i) => link.source.bounds && link.target.bounds &&
      <LinkClass key={i} order={i} link={link} colaGraphAdaptor={colaGraphAdaptor} relayout={this.relayout} />
    );

    return (
      <g>
        {renderedGroups}
        {renderedNodes}
        {renderedLinks}
      </g>
    );
  },
});

export default ColaGraph;
