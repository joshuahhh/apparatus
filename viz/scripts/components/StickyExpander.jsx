import React from 'react';
import _ from 'underscore';


const StickyExpander = React.createClass({
  getInitialState: function() {
    return {
      divHeight: this.props.minHeight,
    };
  },

  handleResize() {
    const divNode = React.findDOMNode(this.refs.div);
    const parentNode = divNode.parentNode;
    const parentParentNode = parentNode.parentNode;
    console.log('bound', JSON.stringify(
      _.pick(parentParentNode.getBoundingClientRect(), 'top', 'bottom', 'left', 'right', 'height', 'width')
    ));
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
    const {divHeight} = this.state;

    return (
      <div ref='div' width='100%' height={divHeight} {...otherProps}>
        {children({height: divHeight})}
      </div>
    );
  }
});

export default StickyExpander;
