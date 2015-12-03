/* global React, $ */
// from https://gist.github.com/jlongster/e1c5a2ee7644eb15cd49

// https://jsfiddle.net/tysy8pt3/

// util

import Triggers from './components/Triggers.jsx';
import React from 'react';
import ReactDOM from 'react-dom';

import './shift.css';


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
  ReactDOM.render(
    <Triggers breakpoints={breakpoints} breakpointStateEditor={BREAKPOINT_STATE_EDITOR} />, div);
});
