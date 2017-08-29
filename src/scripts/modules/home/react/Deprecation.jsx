import React, {PropTypes} from 'react';
import StringUtils from '../../../utils/string';
// import {Link} from 'react-router';
// import ComponentIndexLink from '../../../modules/components/react/components/ComponentIndexLink';
import ComponentDetailLink from '../../../react/common/ComponentDetailLink';

export default React.createClass({
  propTypes: {
    components: PropTypes.object
  },

  render() {
    const deprecatedComponents = this.props.components.filter(function(component) {
      return !!component.get('flags', []).contains('deprecated');
    });

    if (deprecatedComponents.isEmpty()) {
      return null;
    }

    const grouped = deprecatedComponents.groupBy(function(component) {
      return component.get('type');
    });

    return (
      <div className="row kbc-header kbc-expiration">
        <div className="alert alert-warning">
          <h3>
            <span className="fa fa-exclamation-triangle"/> Project contains deprecated components
          </h3>
          {grouped.map(function(components, type) {
            return (
              <div>
                <h4>{StringUtils.capitalize(type)}s</h4>
                <ul>
                  {components.map(function(component) {
                    return (
                      <li>
                        <ComponentDetailLink
                          type={component.get('type')}
                          componentId={component.get('id')}
                        >
                          {component.get('name')}
                        </ComponentDetailLink>
                      </li>
                    );
                  })}
                </ul>
              </div>
            );
          })}
        </div>
      </div>
    );
  }
});