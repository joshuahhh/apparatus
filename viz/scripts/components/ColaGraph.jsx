import React from 'react';
import d3 from 'd3';
import _ from 'underscore';
import rectConnect from 'rect-connect';
import {Motion, spring} from 'react-motion';


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
  // const oldNodesById = _.indexBy(oldNodes, 'id');
  const oldGroupsById = _.indexBy(oldGroups, 'id');

  const outNodes = nodes.map(({id, label, ...other}) => {
    // const oldNode = _.pick(oldNodesById[id] || {}, 'x', 'y');
    const oldNode = {};
    return _.defaults({
      id,
      label,
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

    const gClassName =
      (node.hovered ? 'node-g hovered' : 'node-g')
      + ' ' + (node.className || '')
      + ' ' + (node.type == 'prop' ? 'prop' : '');

    return (
      <Motion style={{x: spring(node.x), y: spring(node.y)}}>
        {({x, y}) =>
          <g className={gClassName} style={{opacity: node.ghost && 0.3}}>
            {!(node.type == 'prop') &&
              <rect className='node' width={node.width} height={node.height}
                rx={5} ry={5}
                x={x - node.width / 2} y={y - node.height / 2}/>
            }
            <text className='g-label' x={x} y={y}>
              {node.label}
            </text>
          </g>
        }
      </Motion>
    );
  },
});

const ColaGraphLink = ({link}) => {
  const connection = rectConnect(link.source, link.source, link.target, link.target);
  const sourceX = connection.source.x, sourceY = connection.source.y;
  const targetX = connection.target.x, targetY = connection.target.y;

  if (_.isNaN(sourceX)) {
    console.log('bad!', link);
  }

  const backgroundWidth = 100;
  const backgroundHeight = 30;

  return (
    <Motion style={{sourceX: spring(sourceX), sourceY: spring(sourceY), targetX: spring(targetX), targetY: spring(targetY)}}>
      {({sourceX, sourceY, targetX, targetY}) =>
        <g style={{opacity: link.ghost && 0.3}}>
          <g dangerouslySetInnerHTML={{__html: markerHtml}} />
          <path className={'link type-' + link.type} d={'M' + sourceX + ',' + sourceY + 'L' + targetX + ',' + targetY} />
          {link.label &&
            [
              <rect className='g-link-label-background'
                x={(sourceX + targetX - backgroundWidth) / 2} y={(sourceY + targetY - backgroundHeight) / 2}
                width={backgroundWidth} height={backgroundHeight} />
            ,
              <text className='g-link-label'
                x={(sourceX + targetX) / 2} y={(sourceY + targetY) / 2} >
                {link.label}
              </text>
            ]
          }
        </g>
      }
    </Motion>
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
    return {
      colaGraphAdaptor: this.makeColaGraphAdaptor(this.props),
    };
  },

  componentWillReceiveProps(nextProps) {
    if (true || nextProps.graph !== this.props.graph) {
      const colaGraphAdaptor = this.makeColaGraphAdaptor(nextProps);
      this.setState({colaGraphAdaptor});
      this.state.colaGraphAdaptor.resume();
    }
  },

  makeColaGraphAdaptor(props)  {
    const {width, height, colaOptions, graph} = props;

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
      .start(20, 20)
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
      <Motion key={group.id} defaultStyle={{opacity: 0}} style={{opacity: spring(1, [120, 100])}}>
        {({opacity}) =>
          <g style={{opacity}}>
            <GroupClass key={group.id} order={i} group={group} colaGraphAdaptor={colaGraphAdaptor} relayout={this.relayout} />
          </g>
        }
      </Motion>
    );

    const renderedNodes = nodes.map((node, i) => node.x && node.y &&
      <Motion key={node.id} defaultStyle={{opacity: 0}} style={{opacity: spring(1, [120, 56])}}>
        {({opacity}) =>
          <g style={{opacity}}>
            <NodeClass order={i} node={node} colaGraphAdaptor={colaGraphAdaptor} relayout={this.relayout} />
          </g>
        }
      </Motion>
    );

    const renderedLinks = links.map((link, i) => link.source.bounds && link.target.bounds &&
      <LinkClass key={link.source.id + '_' + link.target.id} order={i} link={link} colaGraphAdaptor={colaGraphAdaptor} relayout={this.relayout} />
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
