import React from 'react';
import $ from 'jquery';

const _gaq = {push: (x) => {
  console.log('gaq', x);
  // window.doit();
}};

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
      // positionedBreakpoints: this.props.breakpoints
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

    console.log('positionedBreakpoints', positionedBreakpoints);

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
    var s = this.state;
    var currentY = s.pageY + s.pageHeight / 3;
    var firstBreakpoint = s.positionedBreakpoints[0];

    if(currentY < (firstBreakpoint.start || firstBreakpoint.pos)) {
      // we haven't hit a breakpoint yet, so render the page as if the
      // initial breakpoint is at the starting point
      if(s.currentBreakpoint) {
        _gaq.push(['_trackEvent', 'React-Post', 'breakpoint-' + 1]);
        window.doit(1);
        this.setState({ currentBreakpoint: null });
      }
      else {
        window.doit(1);
        firstBreakpoint.apply && firstBreakpoint.apply(0);
      }
    }
    else {
      if(s.currentBreakpoint && s.currentBreakpoint !== firstBreakpoint) {
        firstBreakpoint.apply && firstBreakpoint.apply(1);
      }

      // iterate backwards over the breakpoints, and the stop when it
      // finds the first breakpoint to apply
      eachl(s.positionedBreakpoints, (bp) => {
        if(bp.start && bp.end &&
           bp.start < currentY &&
           bp.end > currentY) {
          if(s.currentBreakpoint !== bp) {
            _gaq.push(['_trackEvent', 'React-Post', 'breakpoint-' + (this.props.breakpoints.indexOf(bp.breakpoint)+1)]);
            window.doit(this.props.breakpoints.indexOf(bp.breakpoint)+1);
            this.setState({ currentBreakpoint: bp });
          }
          else {
            bp.apply(Math.min(1.0, (currentY - bp.start) / (bp.end - bp.start)));
          }
          return true;
        }

        if(currentY > (bp.pos || bp.start)) {
          if(s.currentBreakpoint !== bp) {
            _gaq.push(['_trackEvent', 'React-Post', 'breakpoint-' + (this.props.breakpoints.indexOf(bp.breakpoint)+1)]);
            window.doit(this.props.breakpoints.indexOf(bp.breakpoint)+1);
            // callback()
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
