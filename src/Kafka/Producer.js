"use strict";

exports._connect = function _connect(producer) {
  return producer.connect();
};

exports._disconnect = function _connect(producer) {
  return producer.disconnect();
};

exports._producer = function _producer(kafka, config) {
  return kafka.producer(config);
};

exports._sendBatch = function _sendBatch(producer, record) {
  return producer.sendBatch(record);
};
