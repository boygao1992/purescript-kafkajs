"use strict";

exports._admin = function _admin(kafka, config) {
  return kafka.admin(config);
};

exports._connect = function _connect(admin) {
  return admin.connect();
};

exports._createTopics = function _createTopics(admin, options) {
  return admin.createTopics(options);
};

exports._disconnect = function _disconnect(admin) {
  return admin.connnect();
};
