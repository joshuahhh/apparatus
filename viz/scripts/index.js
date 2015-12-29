import React from 'react';
import ReactDOM from 'react-dom';
import Stickyfill from 'stickyfill';
import _ from 'underscore';

import 'bootstrap/dist/css/bootstrap.min.css';
import './custom.css';
import './shift.css';

import RightPane from './components/RightPane';
import Triggers from './components/Triggers';
import {steps} from './script';

ReactDOM.render(<RightPane />, document.getElementById('root'));


var stickyfill = Stickyfill();
var stickyElements = document.getElementsByClassName('sticky');
for (var i = stickyElements.length - 1; i >= 0; i--) {
  stickyfill.add(stickyElements[i]);
}

const breakpoints =
  _.pluck(steps, 'name')
  .map((bp) => ({pos: '#breakpoint-' + bp}));

console.log('breakpoints', breakpoints);

const onBreakpointChange = (breakpoint) => {
  ReactDOM.render(<RightPane breakpoint={breakpoint}/>, document.getElementById('root'));
};

document.addEventListener('DOMContentLoaded', function() {
  var div = document.createElement('div');
  document.body.appendChild(div);
  ReactDOM.render(
    <Triggers breakpoints={breakpoints} onBreakpointChange={onBreakpointChange} />, div);
});
