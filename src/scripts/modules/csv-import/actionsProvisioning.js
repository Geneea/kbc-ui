import {Map, List} from 'immutable';

import storeProvisioning from './storeProvisioning';
import componentsActions from '../components/InstalledComponentsActionCreators';
import storageApi from '../components/StorageApi';
import storageApiActions from '../components/StorageActionCreators';
import bucketsStore from '../components/stores/StorageBucketsStore';
import tablesStore from '../components/stores/StorageTablesStore';
import installedComponentsStore from '../components/stores/InstalledComponentsStore';

// via https://github.com/aws/aws-sdk-js/issues/603#issuecomment-228233113
import 'aws-sdk/dist/aws-sdk';
const AWS = window.AWS;

// utils
import {getDefaultTable} from './utils';

const COMPONENT_ID = 'keboola.csv-import';

// PROPTYPES HELPER:
/*
  localState: PropTypes.object.isRequired,
  updateLocalState: PropTypes.func.isRequired,
*/

function createConfigurationFromSettings(settings, configId) {
  let config = Map();

  if (settings.get('destination') && settings.get('destination') !== '') {
    config = config.set('destination', settings.get('destination'));
  } else {
    config = config.set('destination', getDefaultTable(configId));
  }

  config = config.set('incremental', settings.get('incremental', false));

  if (settings.get('primaryKey') && settings.get('primaryKey').count() > 0) {
    config = config.set('primaryKey', settings.get('primaryKey'));
  } else {
    config = config.set('primaryKey', List());
  }

  if (settings.get('delimiter') && settings.get('delimiter') !== '') {
    config = config.set('delimiter', settings.get('delimiter'));
  } else {
    config = config.set('delimiter', ',');
  }

  if (settings.get('enclosure') && settings.get('enclosure') !== '') {
    config = config.set('enclosure', settings.get('enclosure'));
  } else {
    config = config.set('enclosure', '"');
  }
  return config;
}


export default function(configId) {
  const store = storeProvisioning(configId);

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
    var settings = installedComponentsStore.getConfigData(COMPONENT_ID, configId);
    if (!settings) {
      settings = Map();
    }
    updateLocalState(['settings'], settings);
    updateLocalState(['isEditing'], true);
  }

  function editCancel() {
    updateLocalState(['isEditing'], false);
    removeFromLocalState(['settings']);
  }

  function setFile(file) {
    updateLocalState(['file'], file);
  }

  function resetFileInput() {
    updateLocalState(['fileInputKey'], getLocalState().get('fileInputKey', 0) + 1);
  }

  function editChange(newSettings) {
    const localState = getLocalState();
    componentsActions.updateLocalState(COMPONENT_ID, configId,
      localState.set('settings', newSettings)
    );
  }

  function editSave() {
    const localState = getLocalState();
    const config = createConfigurationFromSettings(localState.get('settings', Map()), configId);

    return componentsActions.saveComponentConfigData(COMPONENT_ID, configId, config).then(() => {
      updateLocalState(['isEditing'], false);
      removeFromLocalState(['settings']);
    });
  }

  function resetForm() {
    resetFileInput();
    removeFromLocalState(['file']);
  }

  function resetUploadState() {
    removeFromLocalState(['uploadingMessage']);
    updateLocalState(['isUploading'], false);
  }

  function resultSuccess(message) {
    updateLocalState(['resultState'], 'success');
    updateLocalState(['resultMessage'], message);
  }

  function resultError(message) {
    updateLocalState(['resultState'], 'error');
    updateLocalState(['resultMessage'], message);
  }

  function dismissResult() {
    removeFromLocalState(['resultState']);
    removeFromLocalState(['resultMessage']);
  }

  function startUpload() {
    var params = {
      federationToken: true,
      notify: false,
      name: getLocalState().get('file').name,
      sizeBytes: getLocalState().get('file').size
    };

    updateLocalState(['isUploading'], true);
    updateLocalState(['uploadingMessage'], 'Preparing upload');
    updateLocalState(['uploadingProgress'], 5);

    storageApi.prepareFileUpload(params).then(function(response) {
      var fileId = response.id;
      // one retry, 10 minutes timeout
      const awsParams = {
        maxRetries: 1,
        httpOptions: {
          timeout: 10 * 60 * 1000
        }
      };
      const s3params = {
        Key: response.uploadParams.key,
        Bucket: response.uploadParams.bucket,
        ACL: response.uploadParams.acl,
        Body: getLocalState().get('file')
      };
      const credentials = response.uploadParams.credentials;
      AWS.config.credentials = new AWS.Credentials({
        accessKeyId: credentials.AccessKeyId,
        secretAccessKey: credentials.SecretAccessKey,
        sessionToken: credentials.SessionToken
      });

      updateLocalState(['uploadingMessage'], 'Uploading to S3');
      updateLocalState(['uploadingProgress'], 30);

      new AWS.S3(awsParams)
        .putObject(s3params)
        .on('httpUploadProgress', function(progress) {
          var addition = 0;
          if (progress.loaded && progress.total) {
            addition = 30 * (progress.loaded / progress.total);
          }
          updateLocalState(['uploadingProgress'], 30 + addition);
        })
        .send(function(err) {
          if (err) {
            resetUploadState();
            resultError(err.toString());
          } else {
            var tableId = store.destination;
            var bucketId = tableId.substr(0, tableId.lastIndexOf('.'));
            var tableName = tableId.substr(tableId.lastIndexOf('.') + 1);

            var createTable = function() {
              updateLocalState(['uploadingMessage'], 'Creating table ' + tableId);
              updateLocalState(['uploadingProgress'], 75);
              var createTableParams = {
                name: tableName,
                dataFileId: fileId
              };
              if (store.primaryKey) {
                createTableParams.primaryKey = store.primaryKey.toJS().join(',');
              }
              if (store.delimiter) {
                createTableParams.delimiter = store.delimiter;
              }
              if (store.enclosure) {
                createTableParams.enclosure = store.enclosure;
              }

              storageApiActions.createTable(bucketId, createTableParams).then(function() {
                resetUploadState();
                resetForm();
                resultSuccess('CSV file successfully imported.');
              }).catch(function(e) {
                resetUploadState();
                resultError(e);
              });
            };

            if (!bucketsStore.hasBucket(bucketId)) {
              // create bucket and table

              updateLocalState(['uploadingMessage'], 'Creating bucket ' + bucketId);
              updateLocalState(['uploadingProgress'], 60);

              var createBucketParams = {
                name: bucketId.substr(bucketId.indexOf('-') + 1),
                stage: bucketId.substr(0, bucketId.lastIndexOf('.'))
              };
              storageApiActions.createBucket(createBucketParams)
                .then(createTable)
                .catch(function(e) {
                  resetUploadState();
                  resultError(e);
                });
            } else if (tablesStore.hasTable(tableId)) {
              // table exist? load
              var loadTableParams = {
                dataFileId: fileId
              };

              store.incremental && (loadTableParams.incremental = store.incremental);
              store.delimiter && (loadTableParams.delimiter = store.delimiter);
              store.enclosure && (loadTableParams.enclosure = store.enclosure);

              updateLocalState(['uploadingMessage'], 'Loading into table ' + tableId);
              updateLocalState(['uploadingProgress'], 90);
              storageApiActions.loadTable(tableId, loadTableParams).then(function() {
                resetUploadState();
                resetForm();
                resultSuccess('CSV file successfully imported.');
              }).catch(function(e) {
                resetUploadState();
                resultError(e);
              });
            } else {
              createTable();
            }
          }
        });
    });
  }

  return {
    startUpload,
    editStart,
    editCancel,
    editSave,
    setFile,
    editChange,
    dismissResult
  };
}
