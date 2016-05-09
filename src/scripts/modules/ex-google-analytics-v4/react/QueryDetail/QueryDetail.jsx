import React from 'react';

// stores
import createStoreMixin from '../../../../react/mixins/createStoreMixin';
import storeProvisioning, {storeMixins} from '../../storeProvisioning';
import RoutesStore from '../../../../stores/RoutesStore';

// actions
import actionsProvisioning from '../../actionsProvisioning';

// ui components
import QueryEditor from '../QueryEditor';

// CONSTS
// const COMPONENT_ID = 'keboola.ex-google-analytics-v4';


export default React.createClass({

  mixins: [createStoreMixin(...storeMixins)],

  getStateFromStores() {
    const configId = RoutesStore.getCurrentRouteParam('config');
    const queryId = RoutesStore.getCurrentRouteParam('queryId');
    const store = storeProvisioning(configId);
    const actions = actionsProvisioning(configId);
    const query = store.getConfigQuery(queryId);
    const editingQuery = store.getEditingQuery(queryId);

    return {
      query: query,
      queryId: queryId,
      editingQuery: editingQuery,
      store: store,
      actions: actions,
      configId: configId,
      localState: store.getLocalState()
    };
  },

  componentDidMount() {
    this.state.actions.startEditingQuery(this.state.queryId);
  },

  render() {
    const contentClassName = 'col-md-9 kbc-main-content-with-nav';
    const isEditing = !!this.state.editingQuery;
    return (
      <div className="container-fluid kbc-main-content">
        <div className="col-md-3 kbc-main-nav">
          <div className="kbc-container">

          </div>
        </div>
        {(isEditing ?
          <QueryEditor divClassName={contentClassName}
            outputBucket={this.state.store.outputBucket}
            onChangeQuery={this.state.actions.onChangeEditingQueryFn(this.state.queryId)}

            query={this.state.editingQuery}
            {...this.state.actions.prepareLocalState('QueryDetail' + this.state.queryId)}/>
         :
          <div className={contentClassName}>
            Query Static Detail TODO
          </div>)}

      </div>

    );
  }
});
