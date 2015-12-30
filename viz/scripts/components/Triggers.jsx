import React from 'react';
import $ from 'jquery';
import _ from 'underscore';

import CurrentMarker from './CurrentMarker';


// Props:
//   * breakpoints: breakpoint specs
//   * onBreakpointChange: callback
// State:
//   * windowHeight
//   * pageY
//   * currentBreakpoint
//   * positionedBreakpoints

const Triggers = React.createClass({
  getInitialState: function() {
    return {
      curBreakpointName: 'UNDEFINED',
      pageY: $(window).scrollTop(),
      windowHeight: window.innerHeight,
    };
  },

  componentDidMount: function() {
    $(window).on('resize', this.onResize);
    $(window).on('scroll', this.updatePageY);

    this.onResize();
    this.updatePageY();
  },

  componentWillUnmount: function(_e) {
    $(window).off('resize', this.onResize);
    $(window).off('scroll', this.updatePageY);
  },

  onResize: function(_e) {
    this.setState({windowHeight: window.innerHeight});

    const positionedBreakpoints =
      this.props.breakpoints.map((bp) => {
        var el = $(bp.start || bp.pos);
        if(el.length) {
          var top = el.offset().top;
          var toReturn = {breakpoint: bp};
          if(bp.start) {
            toReturn.start = top;
            toReturn.end = top + bp.length;
          } else {
            toReturn.pos = top;
          }
          return toReturn;
        }
      });

    window.positionedBreakpoints = positionedBreakpoints;
    this.setState({positionedBreakpoints});
  },

  updatePageY: function(e) {
    if(!e || e.target === document) {
      this.setState({pageY: $(window).scrollTop()});
    }
  },

  shouldComponentUpdate: function(nextProps, nextState) {
    return !_.isEqual(JSON.stringify(this.props), JSON.stringify(nextProps)) || !_.isEqual(this.state, nextState);
  },

  syncBreakpoint: function() {
    const {onBreakpointChange} = this.props;
    const {curBreakpointName, positionedBreakpoints, pageY, windowHeight} = this.state;

    const currentY = pageY + windowHeight / 3;

    // iterate backwards over the breakpoints, and the stop when it
    // finds the first breakpoint to apply
    const newPositionedBreakpointIndex = _.findLastIndex(
      positionedBreakpoints,
      (positionedBreakpoint) => currentY > positionedBreakpoint.pos
    );

    if (newPositionedBreakpointIndex === -1) {
      if (curBreakpointName) {
        onBreakpointChange(null);
        this.setState({curBreakpointName: null});
      }
    } else {
      const newBreakpointName = positionedBreakpoints[newPositionedBreakpointIndex].breakpoint.name;
      if (newBreakpointName !== curBreakpointName) {
        onBreakpointChange(newBreakpointName);
        this.setState({curBreakpointName: newBreakpointName});
      }
    }
  },

  componentDidRender: function() {
    this.syncBreakpoint();
  },

  componentDidUpdate: function() {
    this.syncBreakpoint();
  },

  render: function() {
    const {positionedBreakpoints} = this.state;

    return (
      <div>
        <div className='breakpoint-container' style={{top: 0}}>
          {positionedBreakpoints && positionedBreakpoints.map((bp) =>
            <div
              key={bp.pos}
              className='breakpoint-marker'
              style={{
                top: (bp.start || bp.pos) + 'px',
                height: (bp.start ? (bp.end - bp.start) : 10) + 'px'
              }}
            />
          )}
          <CurrentMarker />
        </div>
      </div>
    );
  }
});

export default Triggers;
