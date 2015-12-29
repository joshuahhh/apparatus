import React from 'react';
import ReactDOM from 'react-dom';

const ElasticSvg = React.createClass({
  getInitialState: function() {
    return {
      svgWidth: undefined,
    };
  },

  handleResize() {
    const svgNode = ReactDOM.findDOMNode(this.refs.svg);
    const newSvgWidth = svgNode.offsetWidth;
    if (newSvgWidth != this.state.svgWidth) {
      this.setState({svgWidth: newSvgWidth});
    }
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
    const {children, height, ...otherProps} = this.props;
    const {svgWidth} = this.state;

    return (
      <svg ref='svg' width='100%' height={height} {...otherProps}>
        {children({width: svgWidth})}
      </svg>
    );
  }
});

export default ElasticSvg;
