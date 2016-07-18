import React from 'react';
import {DropdownButton, MenuItem} from 'react-bootstrap';
import {Map} from 'immutable';
import RollbackVersionMenuItem from './RollbackVersionMenuItem';
import CopyVersionMenuItem from './CopyVersionMenuItem';
import DiffMenuItem from './DiffMenuItem';
import createStoreMixin from '../mixins/createStoreMixin';
import InstalledComponentStore from '../../modules/components/stores/InstalledComponentsStore';
import VersionsStore from '../../modules/components/stores/VersionsStore';
import moment from 'moment';
import createVersionOnRollback from '../../utils/createVersionOnRollback';
import createVersionOnCopy from '../../utils/createVersionOnCopy';
import VersionsActionCreators from '../../../scripts/modules/components/VersionsActionCreators';
import {Loader} from 'kbc-react-components';
import RoutesStore from '../../stores/RoutesStore';

export default React.createClass({
  mixins: [createStoreMixin(VersionsStore, InstalledComponentStore)],

  propTypes: {
    componentId: React.PropTypes.string.isRequired,
    configIdParam: React.PropTypes.string
  },

  getDefaultProps() {
    return {
      configIdParam: 'config'
    };
  },

  getStateFromStores() {
    const router = RoutesStore.getRouter();
    const configId = RoutesStore.getCurrentRouteParam(this.props.configIdParam);
    return {
      versions: VersionsStore.getVersions(this.props.componentId, configId),
      newVersionNames: VersionsStore.getNewVersionNames(this.props.componentId, configId),
      isPending: VersionsStore.isPendingConfig(this.props.componentId, configId),
      pendingActions: VersionsStore.getPendingVersions(this.props.componentId, configId),
      router: router,
      configId: configId,
      currentConfigData: InstalledComponentStore.getConfigData(this.props.componentId, configId)
    };
  },

  getVersions() {
    return this.state.versions.slice(0, 5);
  },

  createOnChangeName(componentId, configId, version) {
    return function(name) {
      VersionsActionCreators.changeNewVersionName(componentId, configId, version, name);
    };
  },

  renderMenuItems(version, previousVersion, i) {
    var items = [];
    items.push(
      (<MenuItem header eventKey={version.get('version')}>
        #{version.get('version')} ({moment(version.get('created')).fromNow()} by {version.getIn(['creatorToken', 'description'], 'unknown')})
      </MenuItem>)
    );
    items.push(
      (
        <MenuItem header>{version.get('changeDescription') || 'No description.'}</MenuItem>
      )
    );

    if (i === 0) {
      items.push(
        (
          <CopyVersionMenuItem
            version={version}
            onCopy={createVersionOnCopy(this.props.componentId, this.state.configId, version.get('version'), this.state.newVersionNames.get(version.get('version')))}
            onChangeName={this.createOnChangeName(this.props.componentId, this.state.configId, version.get('version'))}
            newVersionName={this.state.newVersionNames.get(version.get('version'))}
            isDisabled={this.state.isPending}
            isPending={this.state.pendingActions.getIn([version.get('version'), 'copy'])}
          />
        )
      );
    } else {
      items.push(
        (<RollbackVersionMenuItem
           version={version}
           onRollback={createVersionOnRollback(this.props.componentId, this.state.configId, version.get('version'))}
           isDisabled={this.state.isPending}
           isPending={this.state.pendingActions.getIn([version.get('version'), 'rollback'])}
         />)
      );
    }
    // if it is not the first version show compare diff menu item
    if (version.get('version') > 1) {
      items.push(this.renderDiffMenuItem(version, previousVersion));
    }
    items.push(
      (<MenuItem divider/>)
    );
    return items;
  },

  prepareVersionsDiffData(version, previousVersion) {
    VersionsActionCreators.loadComponentConfigByVersion(this.props.componentId, this.state.configId, version.get('version'));
    return VersionsActionCreators.loadComponentConfigByVersion(this.props.componentId, this.state.configId, previousVersion.get('version'));
  },

  renderDiffMenuItem(version, previousVersion) {
    return (
      <DiffMenuItem
        isDisabled={this.state.isPending}
        isPending={this.state.pendingActions.getIn([version.get('version'), 'config'])}
        onLoadVersionConfig={() => this.prepareVersionsDiffData(version, previousVersion)}
        version={version}
        previousVersion={previousVersion}

      />
    );
  },

  dropdownTitle() {
    if (this.state.isPending) {
      return (
        <span>
          <Loader />&nbsp;
          Versions
        </span>
      );
    } else {
      return (
        'Versions'
      );
    }
  },

  render() {
    const allVersions = this.state.versions;
    return (
      <span>
        <DropdownButton title={this.dropdownTitle()} pullRight className="kbcVersionsButton">
          {
            this.getVersions().map(function(version, i) {
              const previousVersion = allVersions.find((v) => v.get('version') === version.get('version') - 1) || Map();
              return this.renderMenuItems(version, previousVersion, i);
            }, this).toArray()
          }
          {this.renderAllVersionsLink()}
        </DropdownButton>
      </span>
    );
  },

  renderAllVersionsLink() {
    const routeName = `${this.props.componentId}Versions`;
    let params = {};
    params[this.props.configIdParam] = this.state.configId;
    var href = this.state.router.makeHref(routeName, params);
    return (
      <MenuItem href={href}>
        Show all versions
      </MenuItem>
    );
  }
});
