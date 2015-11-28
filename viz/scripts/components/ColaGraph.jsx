import React from 'react';
import d3 from 'd3';
import _ from 'underscore';
import rectConnect from 'rect-connect';

const color = d3.scale.category20();

var markerHtml = `
  <marker
      id='end-arrow' viewBox='0 -5 10 10' refX='6'
      markerWidth='3' markerHeight='3' orient='auto'>
    <path d='M0,-5L10,0L0,5' fill='#7a4e4e' />
  </marker>
`;

var ColaGraph = React.createClass({
  propTypes: {
    width: React.PropTypes.number.isRequired,
    height: React.PropTypes.number.isRequired,
    colaOptions: React.PropTypes.object,
  },

  getInitialState() {
    // TODO: this is gonna become a sophisticated diffing thing someday
    return {
      colaGraph: undefined,
    };
  },

  render() {
    const {colaGraph} = this.state;

    return (
      <g>
        <g dangerouslySetInnerHTML={{__html: markerHtml}} />
        {colaGraph && this.renderGraph()}
      </g>
    );
  },

  renderGraph() {
    const {colaGraph} = this.state;
    const groups = colaGraph.groups();
    const nodes = colaGraph.nodes();
    const links = colaGraph.links();
    window.groups = groups;
    window.colaGraph = colaGraph;

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

  componentDidMount() {
    this.hellaFunction();
  },

  // componentWillReceiveProps: function(nextProps) {
  //   this.setState({graph: nextProps.graph});
  // },

  hellaFunction() {
    const {width, height, colaOptions, graph} = this.props;
    // const {graph} = this.state;

    var colaGraph = window.cola.d3adaptor();
    colaGraph.size([width, height]);
    _(colaOptions || {}).each((value, key) => colaGraph[key](value));
        // .linkDistance(80)
        // .avoidOverlaps(true)
        // .size

    colaGraph
      .nodes(graph.nodes)
      .links(graph.links)
      .groups(graph.groups)
      .constraints(graph.constraints)
      .start(20, 20)
      .on("tick", () => this.setState({colaGraph: colaGraph}));
    window.colaGraph = colaGraph;
  },
});


export default ColaGraph;
