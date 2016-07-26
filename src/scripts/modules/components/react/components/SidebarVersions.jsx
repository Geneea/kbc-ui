import React from 'react';
import {addons} from 'react/addons';
import SidebarVersionsRow from './SidebarVersionsRow';
import {Link} from 'react-router';
import './SidebarVersions.less';

module.exports = React.createClass({
  displayName: 'LatestVersions',
  mixins: [addons.PureRenderMixin],
  propTypes: {
    versions: React.PropTypes.object.isRequired,
    isLoading: React.PropTypes.bool.isRequired,
    bucketId: React.PropTypes.string.isRequired,
    limit: React.PropTypes.number
  },
  getDefaultProps: function() {
    return {
      limit: 5
    };
  },

  renderVersions: function() {
    const props = this.props;
    if (this.props.versions.count() || this.props.isLoading) {
      return this.props.versions.slice(0, 3).map(function(version) {
        return (
          <SidebarVersionsRow
            version={version}
            bucketId={props.bucketId}
          />);
      }).toArray();
    } else {
      return (<div><small className="text-muted">No versions found.</small></div>);
    }
  },

  render: function() {
    const linkParams = {
      bucketId: this.props.bucketId
    };
    return (
      <div>
        <h4>Last updates</h4>
        <div className="kbc-sidebar-versions">
          {this.renderVersions()}
          <div className="versions-link">
            <Link

              to="transformation-versions"
              params={linkParams}
            >
              Show all versions
            </Link>
          </div>
        </div>
      </div>
    );
  }
});
