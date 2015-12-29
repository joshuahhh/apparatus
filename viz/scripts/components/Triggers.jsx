import React from 'react';
import $ from 'jquery';

import CurrentMarker from './CurrentMarker';


function eachl(arr, func) {
  for(var i=arr.length-1; i>=0; i--) {
    if(func(arr[i])) {
      break;
    }
  }
}

const Triggers = React.createClass({
  getInitialState: function() {
    return {
      pageY: $(window).scrollTop(),
      pageHeight: window.innerHeight,
    };
  },

  componentDidMount: function() {
    $(window).on('resize', this.updatePageHeight);
    $(window).on('scroll', this.updatePageY);

    const positionedBreakpoints =
      this.props.breakpoints.map((bp) => {
        var el = $(bp.start || bp.pos);
        if(el.length) {
          var top = el.offset().top + 30;
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

    this.setState({positionedBreakpoints});
  },

  componentWillUnmount: function(_e) {
    $(window).off('resize', this.updatePageHeight);
    $(window).off('scroll', this.updatePageY);
  },

  updatePageHeight: function(_e) {
    this.setState({ pageHeight: $(window).height() });
  },

  updatePageY: function(e) {
    if(e.target === document) {
      this.setState({ pageY: $(window).scrollTop() });
    }
  },

  syncBreakpoint: function() {
    const {onBreakpointChange} = this.props;
    const {currentBreakpoint, positionedBreakpoints, pageY, pageHeight} = this.state;
    const currentY = pageY + pageHeight / 3;
    const firstBreakpoint = positionedBreakpoints[0];

    if(currentY < (firstBreakpoint.start || firstBreakpoint.pos)) {
      // we haven't hit a breakpoint yet, so render the page as if the
      // initial breakpoint is at the starting point
      if(currentBreakpoint) {
        onBreakpointChange(undefined);
        this.setState({ currentBreakpoint: null });
      }
      else {
        onBreakpointChange(undefined);
        firstBreakpoint.apply && firstBreakpoint.apply(0);
      }
    }
    else {
      if(currentBreakpoint && currentBreakpoint !== firstBreakpoint) {
        firstBreakpoint.apply && firstBreakpoint.apply(1);
      }

      // iterate backwards over the breakpoints, and the stop when it
      // finds the first breakpoint to apply
      eachl(positionedBreakpoints, (bp) => {
        if(bp.start && bp.end &&
           bp.start < currentY &&
           bp.end > currentY) {
          if(currentBreakpoint !== bp) {
            onBreakpointChange(bp.breakpoint.pos);
            this.setState({ currentBreakpoint: bp });
          }
          else {
            bp.apply(Math.min(1.0, (currentY - bp.start) / (bp.end - bp.start)));
          }
          return true;
        }

        if(currentY > (bp.pos || bp.start)) {
          if(currentBreakpoint !== bp) {
            onBreakpointChange(bp.breakpoint.pos);
            this.setState({ currentBreakpoint: bp });
          }
          else {
            if(bp.apply) {
              bp.apply(1);
            }
          }
          return true;
        }
      });
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
