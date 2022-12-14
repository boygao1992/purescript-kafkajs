"use strict";

const kafkajs = require('kafkajs');

exports._newKafka = function _newKafka(config) {
  return new kafkajs.Kafka(config);
};
