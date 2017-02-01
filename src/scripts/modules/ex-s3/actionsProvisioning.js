import Immutable from 'immutable';

import componentsActions from '../components/InstalledComponentsActionCreators';
import installedComponentsStore from '../components/stores/InstalledComponentsStore';

// utils
import {createConfiguration, parseConfiguration} from './utils';

const COMPONENT_ID = 'keboola.ex-s3';

function getConfiguration(configId) {
  var configuration = installedComponentsStore.getConfigData(COMPONENT_ID, configId).toJS();
  if (!configuration) {
    configuration = {};
  }
  return configuration;
}

export default function(configId) {
  function updateLocalState(path, data) {
    const ls = installedComponentsStore.getLocalState(COMPONENT_ID, configId);
    const newLocalState = ls.setIn([].concat(path), data);
    componentsActions.updateLocalState(COMPONENT_ID, configId, newLocalState, path);
  }

  function removeFromLocalState(path) {
    const ls = installedComponentsStore.getLocalState(COMPONENT_ID, configId);
    const newLocalState = ls.deleteIn([].concat(path));
    componentsActions.updateLocalState(COMPONENT_ID, configId, newLocalState, path);
  }

  function getLocalState() {
    return installedComponentsStore.getLocalState(COMPONENT_ID, configId);
  }

  function editStart() {
    updateLocalState(['settings'], Immutable.fromJS(parseConfiguration(getConfiguration(configId), configId)));
    updateLocalState(['isEditing'], true);
  }

  function editCancel() {
    updateLocalState(['isEditing'], false);
    removeFromLocalState(['settings']);
  }

  function editChange(field, newSettings) {
    const localState = getLocalState();
    componentsActions.updateLocalState(COMPONENT_ID, configId,
      localState.setIn(['settings', field], newSettings)
    );
  }

  function editSave() {
    const localState = getLocalState();
    const config = Immutable.fromJS(createConfiguration(localState.get('settings', Immutable.Map()), configId));

    return componentsActions.saveComponentConfigData(COMPONENT_ID, configId, config).then(() => {
      updateLocalState(['isEditing'], false);
      removeFromLocalState(['settings']);
    });
  }

  return {
    editStart,
    editCancel,
    editSave,
    editChange
  };
}
