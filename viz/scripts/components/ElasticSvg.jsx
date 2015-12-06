import React from 'react';
import _ from 'underscore';


const ElasticSvg = React.createClass({
  getInitialState: function() {
    return {
      svgWidth: undefined,
    };
  },

  handleResize() {
    const svgNode = React.findDOMNode(this.refs.svg);
    const parentNode = svgNode.parentNode;
    const newSvgWidth = svgNode.offsetWidth;
    console.log('bound', JSON.stringify(_.pick(parentNode.getBoundingClientRect(), 'top', 'bottom', 'left', 'right', 'height', 'width')));
    var newState = {};
    if (newSvgWidth != this.state.svgWidth) {
      newState.svgWidth = newSvgWidth;
    }
    this.setState(newState);
  },

  componentDidMount() {
    window.addEventListener('resize', this.handleResize);
    window.addEventListener('scroll', this.handleResize);
    this.handleResize();
  },

  componentWillUnmount() {
    window.removeEventListener('resize', this.handleResize);
    window.removeEventListener('scroll', this.handleResize);
  },

  render: function() {
    const {children, ...otherProps} = this.props;
    const {svgWidth} = this.state;
    const {svgHeight} = this.state;

    return (
      <svg ref='svg' width='100%' height={svgHeight} {...otherProps}>
        {children({width: svgWidth})}
      </svg>
    );
  }
});

export default ElasticSvg;
