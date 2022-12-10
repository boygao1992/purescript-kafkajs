"use strict";

exports._producer = function _producer(kafka, config) {
  return kafka.producer(config);
};

exports._sendBatch = function _sendBatch(producer, record) {
  return producer.sendBatch(record);
};
