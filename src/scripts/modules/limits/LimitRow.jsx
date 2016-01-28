import React, {PropTypes} from 'react';
import MetricGraph from './MetricGraph';
import AlarmIndicator from './AlarmIndicator';
import classnames from 'classnames';

export default React.createClass({
  propTypes: {
    limit: PropTypes.object.isRequired,
    isKeenReady: PropTypes.bool.isRequired,
    keenClient: PropTypes.object.isRequired
  },

  render() {
    return (
      <div className={classnames('tr', {'danger': this.props.limit.get('isAlarm')})}>
        <span className="td">
          <AlarmIndicator isAlarm={this.props.limit.get('isAlarm')} />
        </span>
        <span className="td">
          <h3>{this.props.limit.get('name')}</h3>
        </span>
        <span className="td">
          {this.props.limit.get('metricValue')} / {this.props.limit.get('limitValue')}
        </span>
        <span className="td" style={{width: '50%'}}>
          {this.renderGraph()}
        </span>
      </div>
    );
  },

  renderGraph() {
    const graph = this.props.limit.get('graph');
    if (!graph) {
      return null;
    }
    if (!this.props.isKeenReady) {
      return (
        <span>Loading ... </span>
      );
    }
    return React.createElement(MetricGraph, {
      query: {
        eventCollection: graph.get('eventCollection'),
        targetProperty: graph.get('targetProperty'),
        timeframe: 'this_30_days',
        interval: 'daily'
      },
      isAlarm: this.props.limit.get('isAlarm'),
      client: this.props.keenClient
    });
  }

});