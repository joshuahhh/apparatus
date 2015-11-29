import React from 'react';
import d3 from 'd3';
import _ from 'underscore';
import rectConnect from 'rect-connect';

const color = d3.scale.category20();

const markerHtml = `
  <marker
      id='end-arrow' viewBox='0 -5 10 10' refX='6'
      markerWidth='3' markerHeight='3' orient='auto'>
    <path d='M0,-5L10,0L0,5' fill='#7a4e4e' />
  </marker>
`;

const myKindaGraphToColaGraph = function(myKindaGraph) {
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
  //     memberIds
  //   Constraints:
  //     leftId
  //     rightId
  //     ...

  const {nodes, links, groups, constraints} = myKindaGraph;

  const outNodes = nodes.map(({id, label, ...other}) => ({
    id,
    name: label,
    ...other
  }));
  const outNodesById = _.indexBy(outNodes, 'id');

  const outLinks = links.map(({sourceId, targetId, type, ...other}) => ({
    source: outNodesById[sourceId],
    target: outNodesById[targetId],
    type,
    ...other
  }));

  const outGroups = groups.map(({memberIds, ...other}) => ({
    leaves: memberIds.map((id) => outNodes.indexOf(outNodesById[id])),
    ...other
  }));

  const outConstraints = constraints.map(({leftId, rightId, ...other}) => {
    return {
      left: outNodes.indexOf(outNodesById[leftId]),
      right: outNodes.indexOf(outNodesById[rightId]),
      ...other
    };
  });

  const colaGraph = {
    nodes: outNodes,
    links: outLinks,
    groups: outGroups,
    constraints: outConstraints
  };

  return colaGraph;
};


var ColaGraph = React.createClass({
  propTypes: {
    width: React.PropTypes.number.isRequired,
    height: React.PropTypes.number.isRequired,
    colaOptions: React.PropTypes.object,
  },

  getInitialState() {
    const {width, height, colaOptions, graph} = this.props;

    const colaGraph = myKindaGraphToColaGraph(graph);

    var colaGraphAdaptor = window.cola.d3adaptor();
    colaGraphAdaptor.size([width, height]);
    _(colaOptions || {}).each((value, key) => colaGraphAdaptor[key](value));

    colaGraphAdaptor
      .nodes(colaGraph.nodes)
      .links(colaGraph.links)
      .groups(colaGraph.groups)
      .constraints(colaGraph.constraints)
      .start(20, 20)
      .on("tick", () => this.setState({colaGraphAdaptor: colaGraphAdaptor}));
    window.colaGraph = colaGraph;

    return {
      colaGraphAdaptor: colaGraphAdaptor,
    };
  },

  render() {
    const {colaGraphAdaptor} = this.state;

    return (
      <g>
        <g dangerouslySetInnerHTML={{__html: markerHtml}} />
        {colaGraphAdaptor && this.renderGraph()}
      </g>
    );
  },

  renderGraph() {
    const {colaGraphAdaptor} = this.state;
    const groups = colaGraphAdaptor.groups();
    const nodes = colaGraphAdaptor.nodes();
    const links = colaGraphAdaptor.links();
    window.groups = groups;
    window.colaGraphAdaptor = colaGraphAdaptor;

    const renderedGroups = groups.map((group, i) => group.bounds &&
      <rect key={i} className='group' rx={8} ry={8} fill={i === 0 ? 'none' : color(i)}
        x={group.bounds.x} y={group.bounds.y} width={group.bounds.width()} height={group.bounds.height()}
        />
    );

    const renderedNodes = nodes.map((node, i) =>
      <g className='node-g'>
        <rect key={'rect' + i} className='node' width={node.width} height={node.height}
          rx={5} ry={5} fill={color(groups.length)}
          x={node.x - node.width / 2} y={node.y - node.height / 2}/>
        <text key={'text' + i} className='g-label' x={node.x} y={node.y}>{node.name}</text>
      </g>
    );

    const renderedLinks = links.map((link, i) => {
      const connection = rectConnect(link.source, link.source, link.target, link.target);
      const sourceX = connection.source.x, sourceY = connection.source.y;
      const targetX = connection.target.x, targetY = connection.target.y;
      const pathD = 'M' + sourceX + ',' + sourceY + 'L' + targetX + ',' + targetY;

      if (_.isNaN(sourceX)) {
        console.log('bad!', link);
      }

      return (
        <path key={i} className={'link type-' + link.type} d={pathD} />
      );
    });

    return [renderedGroups, renderedNodes, renderedLinks];
  },
});


export default ColaGraph;
