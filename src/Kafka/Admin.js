"use strict";

exports._admin = function _admin(kafka, config) {
  return kafka.admin(config);
};

exports._connect = function _connect(admin) {
  return admin.connect();
};
