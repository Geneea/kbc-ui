import storeProvisioning from './storeProvisioning';
import * as common from './common';
import componentsActions from '../components/InstalledComponentsActionCreators';
import _ from 'underscore';
const COMPONENT_ID = 'keboola.ex-google-analytics-v4';

// PROPTYPES HELPER:
/*
  localState: PropTypes.object.isRequired,
  updateLocalState: PropTypes.func.isRequired,
  prepareLocalState: PropTypes.func.isRequired
*/
export default function(configId) {
  const store = storeProvisioning(configId);

  function updateLocalState(path, data) {
    const ls = store.getLocalState();
    const newLocalState = ls.setIn([].concat(path), data);
    componentsActions.updateLocalState(COMPONENT_ID, configId, newLocalState);
  }

  function saveConfigData(data, waitingPath) {
    let dataToSave = data;
    // check default output bucket and save default if non set
    const ob = dataToSave.getIn(['parameters', 'outputBucket']);
    if (!ob) {
      dataToSave = dataToSave.setIn(['parameters', 'outputBucket'], common.getDefaultBucket(COMPONENT_ID, configId));
    }

    updateLocalState(waitingPath, true);
    return componentsActions.saveComponentConfigData(COMPONENT_ID, configId, dataToSave)
      .then(() => updateLocalState(waitingPath, false));
  }


  // returns localState for @path and function to update local state
  // on @path+@subPath
  function prepareLocalState(path) {
    const ls = store.getLocalState(path);
    const updateLocalSubstateFn = (subPath, newData)  =>  {
      if (_.isEmpty(subPath)) {
        return updateLocalState([].concat(path), newData);
      } else {
        return updateLocalState([].concat(path).concat(subPath), newData);
      }
    };
    return {
      localState: ls,
      updateLocalState: updateLocalSubstateFn,
      prepareLocalState: (newSubPath) => prepareLocalState([].concat(path).concat(newSubPath))
    };
  }

  return {
    prepareLocalState: prepareLocalState,
    updateLocalState: updateLocalState,
    saveProfiles(newProfiles) {
      const waitingPath = store.getSavingPath('profiles');
      const newData = store.configData.setIn(['parameters', 'profiles'], newProfiles);
      return saveConfigData(newData, waitingPath);
    },

    onChangeEditingQueryFn(queryId) {
      const path = store.getEditingQueryPath(queryId);
      return (newQuery) => updateLocalState(path, newQuery);
    },

    startEditingQuery(queryId) {
      const path = store.getEditingQueryPath(queryId);
      const query = store.getConfigQuery(queryId);
      updateLocalState(path, query);
    },

    saveEditingQuery(queryId) {
      let query = store.getEditingQuery(queryId);
      if (!query.get('outputTable')) {
        const name = query.get('name');
        query = query.set('outputTable', common.sanitizeTableName(name));
      }
      const queries = store.queries.map((q) => q.get('id') === queryId ? query : q);
      const data = store.configData.setIn(['parameters', 'queries'], queries);
      const savingPath = store.getSavingPath(['queries', queryId]);
      return saveConfigData(data, savingPath);
    }

  };
}
