import React from 'react';
import _ from 'underscore';

import RightPane from './RightPane';
import Triggers from './Triggers';
import Stickyfill from './Stickyfill';
import {steps} from '../script';

const Breakpoint = ({name}) => <div id={'breakpoint-' + name}>BREAKPOINT</div>;

const Header = ({title, subtitle}) =>
  <div className="page-header">
    <h1>{title} {subtitle && <small>{subtitle}</small>}</h1>
  </div>;

const LeftColumn = ({children, rightColumn}) =>
  <div className="container row">
    <hr/>
    <div className="row">
      <div className="col-sm-6">
        {children}
      </div>
      <Stickyfill>
        <div className="col-sm-6" style={{position: 'sticky', top: 0}}>
          {rightColumn}
        </div>
      </Stickyfill>
    </div>
  </div>;

const JsObj = ({children, onHover}, {setHovered}) =>
  <span className="js-obj"
      onMouseOver={_.partial(setHovered, children)} onMouseOut={_.partial(setHovered, false)}>
    {children}
  </span>;
JsObj.contextTypes = {setHovered: React.PropTypes.any};

const MyArticle = React.createClass({
  getInitialState() {
    return {};
  },

  childContextTypes: {
    setHovered: React.PropTypes.any
  },

  getChildContext() {
    return {
      setHovered: (hovered) => this.setState({hovered})
    };
  },

  render() {
    const breakpoints =
      _.pluck(steps, 'name')
      .map((bp) => ({name: bp, pos: '#breakpoint-' + bp}));

    const onBreakpointChange = (breakpoint) => {
      console.log('onBreakpointChange', breakpoint);
      this.setState({breakpoint});
    };

    return (
      <div>
        <Triggers breakpoints={breakpoints} onBreakpointChange={onBreakpointChange} />
        <div className='container' style={{fontSize: 20, fontFamily: 'palatino,georgia,serif'}}>
          <Header title='Apparatus Internals' subtitle='Nodes, Masters, and Parents' />
          <div className="row">
            <div className="col-sm-6">
              <p><i><a href="http://aprt.us/">Apparatus</a> is a direct-manipulation
              editor for dynamic diagrams. In this series, we walk through the design
              and implementation of the systems that make Apparatus tick.</i></p>

              <h2>Spiritual background</h2>
                <p>The improvement of the producer-consumer problem has been widely studied. Sou also visualizes 64 bit architectures, but without all the unnecssary complexity. Similarly, A. Taylor et al. [32] and Erwin Schroedinger [27] constructed the first known instance of highly-available modalities [9,18,33]. While Zhou and Williams also introduced this method, we evaluated it independently and simultaneously. Further, we had our approach in mind before H. Zheng et al. published the recent well-known work on the study of Moore's Law [29,30,1]. Complexity aside, Sou develops even more accurately. Along these same lines, W. Thomas [26] developed a similar heuristic, nevertheless we disconfirmed that our solution is in Co-NP. The only other noteworthy work in this area suffers from fair assumptions about authenticated methodologies. Raj Reddy [2,11,35,23] developed a similar system, contrarily we disconfirmed that Sou is NP-complete [21].</p>

              {this.renderPrototypesPart()}

              <LeftColumn>
                <h2>Bittersweet ending</h2>
                <p>The improvement of the producer-consumer problem has been widely studied. Sou also visualizes 64 bit architectures, but without all the unnecssary complexity. Similarly, A. Taylor et al. [32] and Erwin Schroedinger [27] constructed the first known instance of highly-available modalities [9,18,33]. While Zhou and Williams also introduced this method, we evaluated it independently and simultaneously. Further, we had our approach in mind before H. Zheng et al. published the recent well-known work on the study of Moore's Law [29,30,1]. Complexity aside, Sou develops even more accurately. Along these same lines, W. Thomas [26] developed a similar heuristic, nevertheless we disconfirmed that our solution is in Co-NP. The only other noteworthy work in this area suffers from fair assumptions about authenticated methodologies. Raj Reddy [2,11,35,23] developed a similar system, contrarily we disconfirmed that Sou is NP-complete [21].</p>
                <p>The improvement of the producer-consumer problem has been widely studied. Sou also visualizes 64 bit architectures, but without all the unnecssary complexity. Similarly, A. Taylor et al. [32] and Erwin Schroedinger [27] constructed the first known instance of highly-available modalities [9,18,33]. While Zhou and Williams also introduced this method, we evaluated it independently and simultaneously. Further, we had our approach in mind before H. Zheng et al. published the recent well-known work on the study of Moore's Law [29,30,1]. Complexity aside, Sou develops even more accurately. Along these same lines, W. Thomas [26] developed a similar heuristic, nevertheless we disconfirmed that our solution is in Co-NP. The only other noteworthy work in this area suffers from fair assumptions about authenticated methodologies. Raj Reddy [2,11,35,23] developed a similar system, contrarily we disconfirmed that Sou is NP-complete [21].</p>
              </LeftColumn>
          </div>
          </div>
        </div>
      </div>
    );
  },

  renderPrototypesPart() {
    const {breakpoint, hovered} = this.state;
    const rightColumn = <RightPane breakpoint={breakpoint} nodeToHighlight={hovered}/>;

    const a = 3;
    const test = <a />;

    window.test = test;

    return (
      <LeftColumn rightColumn={rightColumn}>
        <h2>Prototypes in Javascript</h2>

        <p>As most folk know, objects in Javascript have these mysterious things
        called "prototypes". Apparatus's node system starts with prototypal
        inheritance. So before we get to Apparatus's system, let's reinvent
        Javascript's prototypes.</p>

        <p>On the right is a Javascript object <JsObj>TodoList</JsObj>. It
        represents a todo list UI element in some hip new todo webapp.</p>

        <Breakpoint name='props' />

        <p>Our object represents a bundle of data and behaviors. These are
        attached using properties. Here are some properties of <JsObj>TodoList</JsObj>:</p>

        <ul>
          <li>
            <b><code><JsObj>TodoList</JsObj>.render</code> = <code>function() {'{...}'}</code></b>
            <p>This is a function which renders the list to the screen. The
            function can refer to <code>this.todos</code>, which, when
            <code><JsObj>TodoList</JsObj>.render()</code> is called, will refer to
            {' '}<code><JsObj>TodoList</JsObj>.todos</code>.</p>
          </li>
          <li>
            <b><code><JsObj>TodoList</JsObj>.todos</code> = <code>["Run", "Play"]</code></b>
            <p>This is the data backing the UI element: a simple list of todo
            tasks as strings.</p>
          </li>
        </ul>

        <Breakpoint name='object2' />

        <p>But later in the development of the hip webapp, we decide that there
        should be two todo lists on the screen. We add a second object,
        {' '}<JsObj>TodoList2</JsObj>. It has a very similar structure to
        {' '}<JsObj>TodoList</JsObj>.</p>

        <p>Now is a good time to make clear that, so far, there are no classes
        or prototypes or anything. All we have are simple objects, representing
        bundles of properties.</p>

        <p>But this is clearly a messy situation. <JsObj>TodoList</JsObj> and
        {' '}<JsObj>TodoList2</JsObj> have different data (<code>.todos</code>), but
        they share the same behavior (<code>.render</code>). What we would like
        is some way to take the shared behavior and store it in just one place.</p>

        <Breakpoint name="proto" />

        That is exactly what prototypes let us do. Here
        we introduce a new object called <JsObj>TodoListProto</JsObj>. It will
        serve as the "prototype" for TODO

        <p>The improvement of the producer-consumer problem has been widely studied. Sou also visualizes 64 bit architectures, but without all the unnecssary complexity. Similarly, A. Taylor et al. [32] and Erwin Schroedinger [27] constructed the first known instance of highly-available modalities [9,18,33]. While Zhou and Williams also introduced this method, we evaluated it independently and simultaneously. Further, we had our approach in mind before H. Zheng et al. published the recent well-known work on the study of Moore's Law [29,30,1]. Complexity aside, Sou develops even more accurately. Along these same lines, W. Thomas [26] developed a similar heuristic, nevertheless we disconfirmed that our solution is in Co-NP. The only other noteworthy work in this area suffers from fair assumptions about authenticated methodologies. Raj Reddy [2,11,35,23] developed a similar system, contrarily we disconfirmed that Sou is NP-complete [21].</p>

        <Breakpoint name="ghosts" />

        <h2 id="stuff">Stuff</h2>
        <p>The improvement of the producer-consumer problem has been widely studied. Sou also visualizes 64 bit architectures, but without all the unnecssary complexity. Similarly, A. Taylor et al. [32] and Erwin Schroedinger [27] constructed the first known instance of highly-available modalities [9,18,33]. While Zhou and Williams also introduced this method, we evaluated it independently and simultaneously. Further, we had our approach in mind before H. Zheng et al. published the recent well-known work on the study of Moore's Law [29,30,1]. Complexity aside, Sou develops even more accurately. Along these same lines, W. Thomas [26] developed a similar heuristic, nevertheless we disconfirmed that our solution is in Co-NP. The only other noteworthy work in this area suffers from fair assumptions about authenticated methodologies. Raj Reddy [2,11,35,23] developed a similar system, contrarily we disconfirmed that Sou is NP-complete [21].</p>
        <h2 id="more-stuff">More stuff</h2>
        <p>The improvement of the producer-consumer problem has been widely studied. Sou also visualizes 64 bit architectures, but without all the unnecssary complexity. Similarly, A. Taylor et al. [32] and Erwin Schroedinger [27] constructed the first known instance of highly-available modalities [9,18,33]. While Zhou and Williams also introduced this method, we evaluated it independently and simultaneously. Further, we had our approach in mind before H. Zheng et al. published the recent well-known work on the study of Moore's Law [29,30,1]. Complexity aside, Sou develops even more accurately. Along these same lines, W. Thomas [26] developed a similar heuristic, nevertheless we disconfirmed that our solution is in Co-NP. The only other noteworthy work in this area suffers from fair assumptions about authenticated methodologies. Raj Reddy [2,11,35,23] developed a similar system, contrarily we disconfirmed that Sou is NP-complete [21].</p>
      </LeftColumn>
    );
  }
});

export default MyArticle;
