"use strict";

exports._abort = function _abort(transaction) {
  return transaction.abort();
};

exports._commit = function _commit(transaction) {
  return transaction.commit();
};

exports._sendOffsets = function _sendOffsets(transaction, offsets) {
  return transaction.sendOffsets(offsets);
};

exports._transaction = function _transaction(producer) {
  return producer.transaction();
};
