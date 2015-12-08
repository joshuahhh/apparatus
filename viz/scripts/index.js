import React from 'react';
import ReactDOM from 'react-dom';
import Stickyfill from 'stickyfill';
import _ from 'underscore';

import 'bootstrap/dist/css/bootstrap.min.css';
import './custom.css';
import './shift.css';

import RightPane from './components/RightPane';
import Triggers from './components/Triggers';
import graph from './simple-data.js';

ReactDOM.render(<RightPane />, document.getElementById('root'));


var stickyfill = Stickyfill();
var stickyElements = document.getElementsByClassName('sticky');
for (var i = stickyElements.length - 1; i >= 0; i--) {
  stickyfill.add(stickyElements[i]);
}

const breakpoints =
  _.uniq(_.compact(_.pluck(graph.nodes, 'introduceOn')))
  .map((bp) => ({pos: '#' + bp}));


document.addEventListener('DOMContentLoaded', function() {
  var div = document.createElement('div');
  document.body.appendChild(div);
  ReactDOM.render(
    <Triggers breakpoints={breakpoints} />, div);
});
