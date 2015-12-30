import React from 'react';
import ReactDOM from 'react-dom';
import StickyfillLib from 'stickyfill';

const Stickyfill = React.createClass({
  render() {
    return this.props.children;
  },

  componentDidMount() {
    this.stickyfill = StickyfillLib();
    this.stickyfill.add(ReactDOM.findDOMNode(this));
  },

  componentDidUpdate() {
    this.stickyfill.kill();
    this.stickyfill.add(ReactDOM.findDOMNode(this));
  },

  componentWillUnmount() {
    this.stickyfill.kill();
  }
});

export default Stickyfill;
