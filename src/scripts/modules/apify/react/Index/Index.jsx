import React from 'react';
import {Map} from 'immutable';
import ComponentEmptyState from '../../../components/react/components/ComponentEmptyState';
// stores
import storeProvisioning, {storeMixins} from '../../storeProvisioning';
import ComponentStore from '../../../components/stores/ComponentsStore';
import RoutesStore from '../../../../stores/RoutesStore';
import LatestJobsStore from '../../../jobs/stores/LatestJobsStore';
import createStoreMixin from '../../../../react/mixins/createStoreMixin';
import storageTablesStore from '../../../components/stores/StorageTablesStore';

// actions
import actionsProvisioning from '../../actionsProvisioning';

// ui components
import ComponentDescription from '../../../components/react/components/ComponentDescription';
import SapiTableLinkEx from '../../../components/react/components/StorageApiTableLinkEx';
import ComponentMetadata from '../../../components/react/components/ComponentMetadata';
import RunComponentButton from '../../../components/react/components/RunComponentButton';
import DeleteConfigurationButton from '../../../components/react/components/DeleteConfigurationButton';
import LatestJobs from '../../../components/react/components/SidebarJobs';
import LatestVersions from '../../../components/react/components/SidebarVersionsWrapper';
import SetupModal from './SetupModal';

import CodeMirror from 'react-code-mirror';
/* global require */
require('codemirror/addon/lint/lint');
require('../../../../utils/codemirror/json-lint');


// import {Button} from 'react-bootstrap';

const COMPONENT_ID = 'apify.apify';

export default React.createClass({
  mixins: [createStoreMixin(...storeMixins, LatestJobsStore)],

  getStateFromStores() {
    const configId = RoutesStore.getCurrentRouteParam('config');
    const store = storeProvisioning(configId);
    const actions = actionsProvisioning(configId);
    const component = ComponentStore.getComponent(COMPONENT_ID);

    return {
      allTables: storageTablesStore.getAll(),
      latestJobs: LatestJobsStore.getJobs(COMPONENT_ID, configId),
      store: store,
      actions: actions,
      component: component,
      configId: configId,
      localState: store.getLocalState()
    };
  },

  render() {
    return (
      <div className="container-fluid">
        <div className="col-md-9 kbc-main-content">
          <div className="kbc-header kbc-header-without-row-fix">
            <div className="col-sm-12">
              <ComponentDescription
                componentId={COMPONENT_ID}
                configId={this.state.configId}
              />
            </div>
          </div>
          <div className="kbc-header kbc-header-without-row-fix">
            {this.renderSetupModal()}
            {this.isConfigured() ?
             this.renderStatic()
             :
             this.renderStartSetup()
            }
          </div>
        </div>

        <div className="col-md-3 kbc-main-sidebar">
          <ComponentMetadata
            configId={this.state.configId}
            componentId={COMPONENT_ID}
          />
          <ul className="nav nav-stacked">
            <li className={!!this.invalidToRun() ? 'disabled' : null}>
              <RunComponentButton
                title="Run"
                component={COMPONENT_ID}
                mode="link"
                runParams={this.runParams()}
                disabled={!!this.invalidToRun()}
                disabledReason={this.invalidToRun()}
              >
                You are about to run an extraction.
              </RunComponentButton>
            </li>
            <li>
              <DeleteConfigurationButton
                componentId={COMPONENT_ID}
                configId={this.state.configId}
              />
            </li>
          </ul>
          <LatestJobs jobs={this.state.latestJobs} limit={3} />
          <LatestVersions
            limit={3}
            componentId={COMPONENT_ID}
          />
        </div>
      </div>
    );
  },

  isConfigured() {
    const params = this.state.store.parameters;
    const hasAuth = (!!params.get('userId') && !!params.get('#token')) || !!params.get('executionId');
    const hasCrawler = !!params.get('crawlerId') || !!params.get('executionId');
    return hasAuth && hasCrawler;
  },

  renderSetupModal() {
    const {localState, actions, store} = this.state;
    const path = ['SetupModal'];
    const showPath = path.concat('show');
    const closeFn = () => {
      this.updateLocalState(showPath, false);
    };
    return (
      <SetupModal
        parameters={store.parameters}
        show={localState.getIn(showPath, false)}
        onHideFn={closeFn}
        {...actions.prepareLocalState(path.concat('data'))}
        loadCrawlers={actions.loadCrawlers}
        onSave={(params) => actions.saveParams(params).then(closeFn)}
        isSaving={localState.get('saving') || false}
      />
    );
  },

  showSetupModal() {
    this.updateLocalState('SetupModal', Map());
    this.updateLocalState(['SetupModal', 'show'], true);
  },

  renderStartSetup() {
    return (
      <ComponentEmptyState>
        <p> No Crawler configured.</p>
        <button className="btn btn-success" onClick={this.showSetupModal}>
          Configure Crawler
        </button>
      </ComponentEmptyState>
    );
  },

  renderStatic() {
    const parameters = this.state.store.parameters;
    const crawler = this.renderCrawlerStatic(parameters);
    const crawlerSettings = parameters.get('crawlerSettings', Map()) || Map();
    const user = <p className="form-control-static">{parameters.get('userId')}</p>;
    const settings = <div className="form-control-static"> {this.renderStaticCralwerSettings(crawlerSettings.toJS())}</div>;
    const bucketId = this.state.store.outputBucket;
    const tableId = `${bucketId}.crawlerResult`;
    const resultsTable = <p className="form-control-static"><SapiTableLinkEx tableId={tableId} /></p>;
    const executionId = parameters.get('executionId');
    return (
      <div className="form-horizontal">
        {executionId ? this.renderStaticFormGroup('Execution ID', <p className="form-control-static">{executionId}</p>)
         :
         <span>
           {this.renderStaticFormGroup('User ID', user)}
           {this.renderStaticFormGroup('Crawler', crawler)}
           {this.renderStaticFormGroup('Crawler Settings', settings)}
         </span>

        }
        <div className="col-md-12">
          <span className="pull-right">
            <button className="btn btn-link" onClick={this.showSetupModal}>
              <span className="kbc-icon-pencil" />
              {' '}
              Edit Configuration
            </button>
          </span>
        </div>
        <br />
        {this.renderStaticFormGroup('Results table', resultsTable)}
      </div>
    );
  },

  renderCrawlerStatic(parameters) {
    const cname = parameters.get('customId', parameters.get('crawlerId'));
    return (
      <p className="form-control-static">
        {parameters.get('settingsLink') ?
         <a target="_blank" href={parameters.get('settingsLink')}>
           {cname}
         </a>
         : <span> {cname} </span>
        }
      </p>
    );
  },

  renderStaticFormGroup(controlLabel, control, helpText) {
    return (
      <div className={'form-group'}>
        <label className="col-xs-3 control-label">
          {controlLabel}
        </label>
        <div className="col-xs-9">
          {control}
          <span className="help-block">
            {helpText}
          </span>
        </div>
      </div>
    );
  },

  renderStaticCralwerSettings(data) {
    let value = '{}';
    if (data) {
      value = JSON.stringify(data, null, '  ');
    }
    return (
      <CodeMirror
        theme="solarized"
        lineNumbers={false}
        value={value}
        readOnly={true}
        cursorHeight={0}
        mode="application/json"
        lineWrapping={true}
      />
    );
  },

  invalidToRun() {
    return this.isConfigured() ? '' : 'No crawler configured';
  },

  runParams() {
    return () => ({config: this.state.configId});
  },

  updateLocalState(path, data) {
    this.state.actions.updateLocalState(path, data);
  }

});
