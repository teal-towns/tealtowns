import yaml

import mongo_db
import os

_configPartial = {}

def get_config():
    config_file = "config.yml"
    with open(config_file, 'r') as ymlfile:
        config = yaml.load(ymlfile, Loader=yaml.FullLoader)
    return updateWithEnvironmentVars(config)

def updateWithEnvironmentVars(config):
    if 'WEB_SERVER_INDEX_FILES' in os.environ:
        config['web_server']['index']['files'] = os.environ['WEB_SERVER_INDEX_FILES']
    if 'WEB_SERVER_STATIC_FILES' in os.environ:
        config['web_server']['static']['files'] = os.environ['WEB_SERVER_STATIC_FILES']
    if 'PORT' in os.environ:
        config['web_server']['port'] = os.environ['PORT']
    return config

def get_db(config):
    if 'mongodb' in config and 'url' in config['mongodb'] and 'db_name' in config['mongodb']:
        db = mongo_db.connect_to_db(config['mongodb']['url'], config['mongodb']['db_name'])
        return db
    return None

def setValues(config):
    global _configPartial
    keys = ['log_tracker']
    for key in keys:
        if key in config:
            _configPartial[key] = config[key]

def getValue(key):
    global _configPartial
    if key in _configPartial:
        return _configPartial[key]
    return None
