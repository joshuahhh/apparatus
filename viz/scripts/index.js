import React from 'react';
import ReactDOM from 'react-dom';
import Stickyfill from 'stickyfill';

import 'bootstrap/dist/css/bootstrap.min.css';
import './custom.css';
import './shift.css';

import App from './components/App';
import Triggers from './components/Triggers';

ReactDOM.render(<App />, document.getElementById('root'));


var stickyfill = Stickyfill();
var stickyElements = document.getElementsByClassName('sticky');
for (var i = stickyElements.length - 1; i >= 0; i--) {
  console.log(stickyElements[i]);
  stickyfill.add(stickyElements[i]);
}

const breakpoints = [
  { pos: '#breakpoint-stuff' },

  { pos: '#breakpoint-more-stuff' },

  { pos: '#breakpoint-even-more-stuff' },

  { pos: '#breakpoint-keep' },

  { pos: '#breakpoint-it' },

  { pos: '#breakpoint-coming' },
];


document.addEventListener('DOMContentLoaded', function() {
  var div = document.createElement('div');
  document.body.appendChild(div);
  ReactDOM.render(
    <Triggers breakpoints={breakpoints} />, div);
});
