"use strict";

exports._connect = function _connect(consumer) {
  return consumer.connect();
};

exports._consumer = function _consumer(kafka, config) {
  return kafka.consumer(config);
};

exports._disconnect = function _connect(consumer) {
  return consumer.disconnect();
};

exports._onGroupJoin = function _onGroupJoin(consumer, listener) {
  return consumer.on(consumer.events.GROUP_JOIN, listener);
};

exports._run = function _run(consumer, config) {
  return consumer.run(config);
};

exports._seek = function _seek(consumer, topicPartitionOffset) {
  return consumer.seek(topicPartitionOffset);
};

exports._subscribe = function _subscribe(consumer, subscription) {
  return consumer.subscribe(subscription);
};
