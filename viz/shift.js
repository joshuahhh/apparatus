/* global React, $, _, _gaq */
// from https://gist.github.com/jlongster/e1c5a2ee7644eb15cd49

// https://jsfiddle.net/tysy8pt3/

// util

function eachl(arr, func) {
  for(var i=arr.length-1; i>=0; i--) {
    if(func(arr[i])) {
      break;
    }
  }
}

function splitScreen(dx) {
  var wrapper = $('.main-wrapper');
  var rect = wrapper[0].getBoundingClientRect();
  var width = document.body.getBoundingClientRect().width;
  var padding = 32;
  var target = Math.min((width - rect.width) / -2 + padding, 0);

  return {
    content: target * dx,
    demo: Math.floor(width - rect.width - padding * 2)
  };
}

// components

var dom = React.DOM;

var Triggers = React.createClass({
  getInitialState: function() {
    return {
      pageY: $(window).scrollTop(),
      pageHeight: window.innerHeight,
      breakpoints: this.props.breakpoints
    };
  },

  componentDidMount: function() {
    $(window).on('resize', this.updatePageHeight);
    $(window).on('scroll', this.updatePageY);

    var editor = $('#state-settings textarea');
    var initialText = 'waiting on app state...';

    editor.on('keyup', _.debounce(function(e) {
      $('iframe.demo')[0].contentWindow.postMessage(
        e.target.value,
        window.location.protocol + '//' + window.location.host
      );
    }, 150));

    window.addEventListener('message', (msg) => {
      var data = JSON.parse(msg.data);

      if(data && data.from === 'shift') {
        // if(this.state.currentBreakpoint === BREAKPOINT_STATE_EDITOR) {
        //   var json = JSON.stringify(data.state, null, 2);
        //   var currentValue = editor.val();
        //   if(json !== currentValue) {
        //     editor.val(json);
        //   }
        // }
        if (false) {

        }
        else {
          editor.val(initialText);
        }
      }
    });

    this.setState({
      breakpoints: this.state.breakpoints.filter(function(bp) {
        var el = $(bp.start || bp.pos);
        if(el.length) {
          var top = el.offset().top + 30;
          if(bp.start) {
            bp.start = top;
            bp.end = bp.start + bp.length;
          }
          else {
            bp.pos = top;
          }
          return true;
        }
      })
    });
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
    var firstBreakpoint = s.breakpoints[0];

    if(currentY < (firstBreakpoint.start || firstBreakpoint.pos)) {
      // we haven't hit a breakpoint yet, so render the page as if the
      // initial breakpoint is at the starting point
      if(s.currentBreakpoint) {
        _gaq.push(['_trackEvent', 'React-Post', 'breakpoint-' + 1]);
        this.setState({ currentBreakpoint: null });
      }
      else {
        firstBreakpoint.apply(0);
      }
    }
    else {
      if(s.currentBreakpoint && s.currentBreakpoint !== firstBreakpoint) {
        firstBreakpoint.apply(1);
      }

      // iterate backwards over the breakpoints, and the stop when it
      // finds the first breakpoint to apply
      eachl(s.breakpoints, (bp) => {
        if(bp.start && bp.end &&
           bp.start < currentY &&
           bp.end > currentY) {
          if(s.currentBreakpoint !== bp) {
            _gaq.push(['_trackEvent', 'React-Post', 'breakpoint-' + (breakpoints.indexOf(bp)+1)]);
            this.setState({ currentBreakpoint: bp });
          }
          else {
            bp.apply(Math.min(1.0, (currentY - bp.start) / (bp.end - bp.start)));
          }
          return true;
        }

        if(currentY > (bp.pos || bp.start)) {
          if(s.currentBreakpoint !== bp) {
            _gaq.push(['_trackEvent', 'React-Post', 'breakpoint-' + (breakpoints.indexOf(bp)+1)]);
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
    var s = this.state;
    var currentItem;
    // var currentY = s.pageY + s.pageHeight / 2;
    var bp = s.currentBreakpoint;

    if(bp) {
      currentItem = DemoIframe({ url: bp.url });
    }

    return dom.div(
      null,
      dom.div(
        { className: 'breakpoint-container',
          style: { top: 0 }
        },
        s.breakpoints.map(function(bp) {
          return dom.div({ className: 'breakpoint-marker',
                           style: { top: (bp.start || bp.pos) + 'px',
                                    height: (bp.start ? (bp.end - bp.start) : 10) + 'px' }});
        })
      ),
      CurrentMarker(),
      currentItem
    );
  }
});

var DemoIframe = React.createClass({
  componentDidMount: function() {
    this.getDOMNode().contentWindow.location.replace(this.props.url);
  },

  componentDidUpdate: function(prevProps) {
    if(prevProps.url !== this.props.url) {
      this.getDOMNode().contentWindow.location.replace(this.props.url);
    }
  },

  render: function() {
    return dom.iframe({ className: 'demo' });
  }
});

var CurrentMarker = React.createClass({
  getInitialState: function() {
    return { tip: false };
  },

  toggleTip: function() {
    this.setState({ tip: !this.state.tip });
  },

  render: function() {
    return dom.div(
      { className: 'breakpoint-current' },
      dom.div({ className: 'marker',
                onMouseOver: this.toggleTip,
                onMouseOut: this.toggleTip }, '►'),
      this.state.tip ?
        dom.div({ className: 'tip' },
                'This marker will tell you when a page transition ' +
                'is about to happen.') : null
    );
  }
});

// setup

function slide(dx) {
  var info = splitScreen(dx);
  $('.main-wrapper').css({
    transform: 'translateX(' + info.content + 'px)'
  });

  $('iframe.demo').css({ width: info.demo * dx });
}

var breakpoints = [
  { start: '#breakpoint-initial',
    length: 200,
    apply: function(dx) {
      slide(dx * dx);

      var iframe = $('iframe.demo');
      var main = $('.main-wrapper');
      // Force a layout change
      iframe[0].clientWidth;

      if(dx === 1) {
        main.css({ transition: '-webkit-transform .6s' });
        main.css({ transition: 'transform .6s' });
        iframe.css({ transition: 'width .6s' });
      }
      else {
        main.css({ transition: 'none' });
        iframe.css({ transition: 'none' });
      }

    },
    url: "http://jlongster.com/s/bloop/initial"
  },

  { pos: '#breakpoint-app1',
    url: "http://jlongster.com/s/bloop/app1" },

  { pos: '#breakpoint-data-flow2',
    url: 'http://jlongster.com/s/bloop/app6/' },

  { pos: '#breakpoint-data-flow3',
    url: 'http://jlongster.com/s/bloop/app2/' },

  { pos: '#breakpoint-state1',
    url: 'http://jlongster.com/s/bloop/app2/?state' },

  { pos: '#breakpoint-state2',
    url: 'http://jlongster.com/s/bloop/app3/' },

  { pos: '#breakpoint-game-loop1',
    url: 'http://jlongster.com/s/bloop/app4/' },

  { pos: '#breakpoint-game-loop2',
    url: 'http://jlongster.com/s/bloop/initial/' },

  { pos: '#breakpoint-cortex1',
    url: 'http://jlongster.com/s/bloop/app7/' },

  { pos: '#breakpoint-finale',
    apply: function(_dx) {
      slide(0);
    },
    url: 'http://jlongster.com/s/bloop/app7/'
  }
];

const BREAKPOINT_STATE_EDITOR = breakpoints[4];

document.addEventListener('DOMContentLoaded', function() {
  var div = document.createElement('div');
  document.body.appendChild(div);
  React.renderComponent(Triggers({ breakpoints: breakpoints }), div);
});
