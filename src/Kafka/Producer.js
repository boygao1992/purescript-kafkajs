"use strict";

exports._producer = function _producer(kafka, config) {
  return kafka.producer(config);
};
