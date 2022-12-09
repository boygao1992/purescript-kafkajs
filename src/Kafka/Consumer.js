"use strict";

exports._consumer = function _consumer(kafka, config) {
  return kafka.consumer(config);
};
