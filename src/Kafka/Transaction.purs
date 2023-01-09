module Kafka.Transaction
  ( Offsets
  , ProducerBatch
  , ProducerConfig
  , ProducerRecord
  , PartitionOffset
  , Transaction
  , TopicOffsets
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
import Kafka.Kafka as Kafka.Kafka
import Kafka.Producer as Kafka.Producer
import Record as Record

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L821
-- | `offsets: Offsets & { consumerGroupId: string }`
-- |
-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L660
-- | `Offsets`
-- | * `topics: TopicOffsets[]`
type Offsets =
  { topics :: Array TopicOffsets
  , consumerGroupId :: String
  }

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L650
-- |
-- | * `offset: string`
-- | * `partition: number`
type PartitionOffset =
  { offset :: String
  , partition :: Int
  }

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

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L655
-- |
-- | * `partitions: PartitionOffset[]`
-- | * `topic: string`
type TopicOffsets =
  { partitions :: Array PartitionOffset
  , topic :: String
  }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L820
foreign import data Transaction :: Type

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L823
-- |
-- | `abort(): Promise<void>`
foreign import _abort ::
  Effect.Uncurried.EffectFn1
    Transaction
    (Control.Promise.Promise Unit)

abort :: Transaction -> Effect.Aff.Aff Unit
abort transaction' =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn1 _abort transaction'

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L822
-- |
-- | `commit(): Promise<void>`
foreign import _commit ::
  Effect.Uncurried.EffectFn1
    Transaction
    (Control.Promise.Promise Unit)

commit :: Transaction -> Effect.Aff.Aff Unit
commit transaction' =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn1 _commit transaction'

producer ::
  Kafka.Kafka.Kafka ->
  ProducerConfig ->
  Effect.Effect Kafka.Producer.Producer
producer kafka producerConfig =
  Kafka.Producer.producer kafka
    $ (_ { transactionalId = Data.Maybe.Just producerConfig.transactionalId })
    $ Record.disjointUnion producerConfig
        { idempotent: Data.Maybe.Just true
        , maxInFlightRequests: Data.Maybe.Just 1
        }

send :: Kafka.Producer.Producer -> ProducerRecord -> Effect.Aff.Aff (Array Kafka.Producer.RecordMetadata)
send producer' producerRecord =
  Kafka.Producer.send producer'
    $ Record.disjointUnion producerRecord
        { acks: Data.Maybe.Just Kafka.Producer.AcksAll }

sendBatch :: Kafka.Producer.Producer -> ProducerBatch -> Effect.Aff.Aff (Array Kafka.Producer.RecordMetadata)
sendBatch producer' producerBatch =
  Kafka.Producer.sendBatch producer'
    $ Record.disjointUnion producerBatch
        { acks: Data.Maybe.Just Kafka.Producer.AcksAll }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L821
-- |
-- | `sendOffsets(offsets: Offsets & { consumerGroupId: string }): Promise<void>`
foreign import _sendOffsets ::
  Effect.Uncurried.EffectFn2
    Transaction
    Offsets
    (Control.Promise.Promise Unit)

-- | Commit topic-partition offsets to a Consumer Group if the transaction succeeds.
-- | See [Sending Offsets](https://kafka.js.org/docs/transactions#a-name-offsets-a-sending-offsets)
sendOffsets ::
  Transaction ->
  Offsets ->
  Effect.Aff.Aff Unit
sendOffsets transaction' offsets =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn2 _sendOffsets transaction' offsets

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L816
-- |
-- | `transaction(): Promise<Transaction>`
foreign import _transaction ::
  Effect.Uncurried.EffectFn1
    Kafka.Producer.Producer
    (Control.Promise.Promise Transaction)

transaction ::
  Kafka.Producer.Producer ->
  Effect.Aff.Aff Transaction
transaction producer' =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn1 _transaction producer'
