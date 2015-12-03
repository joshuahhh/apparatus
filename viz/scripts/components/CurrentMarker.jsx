import React from 'react';

const CurrentMarker = React.createClass({
  getInitialState: function() {
    return { tip: false };
  },

  toggleTip: function() {
    this.setState({ tip: !this.state.tip });
  },

  render: function() {
    return (
      <div className='breakpoint-current'>
        <div className='marker'
          onMouseOver={this.toggleTip} onMouseOut={this.toggleTip}>
          ►
        </div>
        {this.state.tip &&
          <div className='tip'>
            This marker will tell you when a page transition
            is about to happen.
          </div>
        }
      </div>
    );
  }
});

export default CurrentMarker;
