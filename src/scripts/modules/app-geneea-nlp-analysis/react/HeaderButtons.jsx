import React from 'react';

import * as actions from '../actions';

import createStoreMixin from '../../../react/mixins/createStoreMixin';
import RoutesStore from '../../../stores/RoutesStore';
import InstalledComponentStore from '../../components/stores/InstalledComponentsStore';
import storageTablesStore from '../../components/stores/StorageTablesStore';
import EditButtons from '../../../react/common/EditButtons';

const componentId = 'geneea-nlp-analysis';

export default React.createClass({

  mixins: [createStoreMixin(InstalledComponentStore, storageTablesStore)],
  getStateFromStores() {
    const configId = RoutesStore.getCurrentRouteParam('config');
    const localState = InstalledComponentStore.getLocalState(componentId, configId);

    return {
      localState: localState,
      editing: localState.get('editing'),
      configId: configId,
      isSaving: InstalledComponentStore.getSavingConfigData(componentId, configId),
      allTables: storageTablesStore.getAll()
    };
  },

  render() {
    return (
      <EditButtons
        editLabel="Setup"
        isEditing={this.state.editing}
        isSaving={this.state.isSaving}
        isDisabled={!actions.isValid(this.state.configId)}
        onCancel={ () => actions.cancel(this.state.configId)}
        onSave={ () => actions.save(this.state.configId, this.state.allTables)}
        onEditStart={ () => actions.startEditing(this.state.configId)}/>
    );
  }

});
