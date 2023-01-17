module Kafka.Transaction
  ( ProducerBatch
  , ProducerConfig
  , ProducerRecord
  , abort
  , commit
  , producer
  , send
  , sendBatch
  , sendOffsets
  , transaction
  ) where

import Prelude

import Control.Promise as Control.Promise
import Data.Maybe as Data.Maybe
import Data.Time.Duration as Data.Time.Duration
import Effect as Effect
import Effect.Aff as Effect.Aff
import Effect.Uncurried as Effect.Uncurried
import Kafka.FFI.Kafka as Kafka.FFI.Kafka
import Kafka.FFI.Producer as Kafka.FFI.Producer
import Kafka.FFI.Transaction as Kafka.FFI.Transaction
import Kafka.Producer as Kafka.Producer
import Record as Record

-- | `Kafka.Producer.ProducerBatch` with the following defaults
-- | * `acks` set to `AcksAll`
-- |
-- | see [Transactions](https://kafka.js.org/docs/transactions)
type ProducerBatch =
  { compression :: Data.Maybe.Maybe Kafka.Producer.CompressionType
  , timeout :: Data.Maybe.Maybe Data.Time.Duration.Milliseconds
  , topicMessages :: Array Kafka.Producer.TopicMessages
  }

-- | `Kafka.Producer.ProducerConfig` with following defaults
-- | * `idempotent` set to `true`
-- |   * Retries will default to `MAX_SAFE_INTEGER`. See https://github.com/tulios/kafkajs/blob/ddf4f64923245ce2cf5716d5babd7e05eb890030/src/producer/index.js#L43
-- | * `maxInFlightRequests` set to `1`
-- |
-- | Required
-- | * `transactionalId`
-- |
-- | see [Transactions](https://kafka.js.org/docs/transactions)
type ProducerConfig =
  { allowAutoTopicCreation :: Data.Maybe.Maybe Boolean
  , metadataMaxAge :: Data.Maybe.Maybe Data.Time.Duration.Milliseconds
  , transactionTimeout :: Data.Maybe.Maybe Data.Time.Duration.Milliseconds
  , transactionalId :: String
  }

-- | `Kafka.Producer.ProducerRecord` with the following defaults
-- | * `acks` set to `AcksAll`
-- |
-- | see [Transactions](https://kafka.js.org/docs/transactions)
type ProducerRecord =
  { compression :: Data.Maybe.Maybe Kafka.Producer.CompressionType
  , messages :: Array Kafka.Producer.Message
  , timeout :: Data.Maybe.Maybe Data.Time.Duration.Milliseconds
  , topic :: String
  }

abort :: Kafka.FFI.Transaction.Transaction -> Effect.Aff.Aff Unit
abort transaction' =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn1 Kafka.FFI.Transaction._abort transaction'

commit :: Kafka.FFI.Transaction.Transaction -> Effect.Aff.Aff Unit
commit transaction' =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn1 Kafka.FFI.Transaction._commit transaction'

producer ::
  Kafka.FFI.Kafka.Kafka ->
  ProducerConfig ->
  Effect.Effect Kafka.FFI.Producer.Producer
producer kafka producerConfig =
  Kafka.Producer.producer kafka
    $ (_ { transactionalId = Data.Maybe.Just producerConfig.transactionalId })
    $ Record.disjointUnion producerConfig
        { idempotent: Data.Maybe.Just true
        , maxInFlightRequests: Data.Maybe.Just 1
        }

send :: Kafka.FFI.Producer.Producer -> ProducerRecord -> Effect.Aff.Aff (Array Kafka.Producer.RecordMetadata)
send producer' producerRecord =
  Kafka.Producer.send producer'
    $ Record.disjointUnion producerRecord
        { acks: Data.Maybe.Just Kafka.Producer.AcksAll }

sendBatch :: Kafka.FFI.Producer.Producer -> ProducerBatch -> Effect.Aff.Aff (Array Kafka.Producer.RecordMetadata)
sendBatch producer' producerBatch =
  Kafka.Producer.sendBatch producer'
    $ Record.disjointUnion producerBatch
        { acks: Data.Maybe.Just Kafka.Producer.AcksAll }

-- | Commit topic-partition offsets to a Consumer Group if the transaction succeeds.
-- | See [Sending Offsets](https://kafka.js.org/docs/transactions#a-name-offsets-a-sending-offsets)
sendOffsets ::
  Kafka.FFI.Transaction.Transaction ->
  Kafka.FFI.Transaction.Offsets ->
  Effect.Aff.Aff Unit
sendOffsets transaction' offsets =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn2 Kafka.FFI.Transaction._sendOffsets transaction' offsets

transaction ::
  Kafka.FFI.Producer.Producer ->
  Effect.Aff.Aff Kafka.FFI.Transaction.Transaction
transaction producer' =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn1 Kafka.FFI.Transaction._transaction producer'
