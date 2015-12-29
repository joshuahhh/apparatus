import React from 'react';
import ReactDOM from 'react-dom';


const StickyExpander = React.createClass({
  getInitialState: function() {
    return {
      divHeight: this.props.minHeight,
    };
  },

  handleResize() {
    const divNode = ReactDOM.findDOMNode(this.refs.div);
    const parentNode = divNode.parentNode;
    const parentParentNode = parentNode.parentNode;
    const screenAvailableTop = Math.max(0, parentParentNode.getBoundingClientRect().top);
    const screenAvailableBottom = Math.min(window.innerHeight, parentParentNode.getBoundingClientRect().bottom);
    const screenAvailable = screenAvailableBottom - screenAvailableTop;
    const correctHeight = Math.max(this.props.minHeight, screenAvailable);
    this.setState({divHeight: correctHeight});
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
