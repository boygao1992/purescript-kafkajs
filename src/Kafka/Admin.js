"use strict";

exports._admin = function _admin(kafka, config) {
  return kafka.admin(config);
};
