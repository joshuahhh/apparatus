import React from 'react';

import ApparatusGraph from './ApparatusGraph';

var App = React.createClass({
  getInitialState() {
    return {
      clicks: 0
    };
  },

  render() {
    return (
      <div>
        <h1 onClick={this.onClick}>Hello, world! {this.state.clicks} clicks!</h1>
        <ApparatusGraph />
      </div>
    );
  },

  onClick() {
    this.setState({clicks: this.state.clicks + 1});
  }
});

export default App;
