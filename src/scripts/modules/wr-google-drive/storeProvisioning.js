import {Map, List} from 'immutable';
import InstalledComponentStore from '../components/stores/InstalledComponentsStore';
import _ from 'underscore';
import OauthStore from '../oauth-v2/Store';

export const storeMixins = [InstalledComponentStore, OauthStore];

export default function(COMPONENT_ID, configId) {
  const localState = () => InstalledComponentStore.getLocalState(COMPONENT_ID, configId) || Map();
  const configData =  InstalledComponentStore.getConfigData(COMPONENT_ID, configId) || Map();
  const oauthCredentialsId = configData.getIn(['authorization', 'oauth_api', 'id'], configId);
  const parameters = configData.get('parameters', Map());

  return {
    configData: configData,
    parameters: parameters,
    oauthCredentials: OauthStore.getCredentials(COMPONENT_ID, oauthCredentialsId) || Map(),
    oauthCredentialsId: oauthCredentialsId,

    // local state stuff
    getLocalState(path) {
      if (_.isEmpty(path)) {
        return localState() || Map();
      }
      return localState().getIn([].concat(path), Map());
    },
    getEditPath: (what) => what ? editPath.concat(what) : editPath,
    isEditing: (what) => editData.hasIn([].concat(what)),
    getPendingPath(what) {
      return pendingPath.concat(what);
    },
    isPending(what) {
      return localState().getIn(pendingPath.concat(what), null);
    },
    isAuthorized() {
      const creds = this.oauthCredentials;
      return creds && creds.has('id');
    }
  };
}
