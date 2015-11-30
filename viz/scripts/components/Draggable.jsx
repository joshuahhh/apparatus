import React from 'react';
import d3 from 'd3';

var Draggable = React.createClass({
  getInitialState() {
    return {
      isDragging: false,
      xInit: undefined,
      yInit: undefined,
    };
  },

  render() {
    return <g ref='g' style={{cursor: 'move'}}>{this.props.children}</g>;
  },

  componentDidMount() {
    this.update();
  },

  componentDidUpdate() {
    this.update();
  },

  update() {
    const {xScale, yScale} = this.context;

    var dragBehavior = d3.behavior.drag()
      .on('dragstart', () => {
        this.props.onDragStart && this.props.onDragStart();
        document.body.style.cursor = 'move';
      })
      .on('drag', () => {
        if (!this.state.isDragging) {
          var toSet = {
            xInit: d3.event.x,
            yInit: d3.event.y,
          };
          if (xScale) { toSet.xInitD = xScale.invert(d3.event.x); }
          if (yScale) { toSet.yInitD = yScale.invert(d3.event.y); }
          this.setState(toSet);
        }

        d3.event.xInit = this.state.xInit;
        d3.event.yInit = this.state.yInit;
        if (xScale) {
          d3.event.xD = xScale.invert(d3.event.x);
          d3.event.xInitD = this.state.xInitD;
        }
        if (yScale) {
          d3.event.yD = yScale.invert(d3.event.y);
          d3.event.yInitD = this.state.yInitD;
        }

        // console.log(JSON.stringify(d3.event));

        if (this.state.isDragging) {
          this.props.onLaterDrag && this.props.onLaterDrag(d3.event);
        } else {
          this.props.onFirstDrag && this.props.onFirstDrag(d3.event);
          this.setState({ isDragging: true });
        }
        this.props.onDrag && this.props.onDrag(d3.event);
      })
      .on('dragend', () => {
        document.body.style.cursor = '';
        this.props.onDragEnd && this.props.onDragEnd();
        this.setState({
          isDragging: false,
          xInit: undefined,
          yInit: undefined,
          xInitD: undefined,
          yInitD: undefined,
        });
      });

    d3.select(this.refs.g).call(dragBehavior);
  },

});

export default Draggable;
