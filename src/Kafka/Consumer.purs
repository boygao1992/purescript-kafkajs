module Kafka.Consumer
  ( Consumer
  , ConsumerConfig
  , Topic(..)
  , connect
  , consumer
  , disconnect
  , run
  , subscribe
  ) where

import Prelude

import Control.Promise as Control.Promise
import Data.Maybe as Data.Maybe
import Data.Nullable as Data.Nullable
import Data.String.Regex as Data.String.Regex
import Effect as Effect
import Effect.Aff as Effect.Aff
import Effect.Uncurried as Effect.Uncurried
import Kafka.FFI as Kafka.FFI
import Kafka.Kafka as Kafka.Kafka
import Kafka.Type as Kafka.Type
import Node.Buffer as Node.Buffer
import Untagged.Union as Untagged.Union

type Batch =
  { firstOffset :: Effect.Effect (Data.Maybe.Maybe String)
  , highWatermark :: String
  , isEmpty :: Effect.Effect Boolean
  , lastOffset :: Effect.Effect String
  , messages :: Array KafkaMessage
  , offsetLag :: Effect.Effect String
  , offsetLagLow :: Effect.Effect String
  , partition :: Int
  , topic :: String
  }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L876
-- |
-- | see comments in https://github.com/tulios/kafkajs/blob/v2.2.3/src/consumer/batch.js
-- |
-- | * `firstOffset(): string | null`
-- |   * `null` when `broker.fetch` returns stale messages from a partition, see https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/src/consumer/batch.js#L20-L25
-- | * `highWatermark: string`
-- |   * LEO (end-of-log offset) vs HW (high watermark), see https://stackoverflow.com/a/67806069
-- | * `isEmpty(): boolean`
-- | * `lastOffset(): string`
-- | * `messages: KafkaMessage[]`
-- | * `offsetLag(): string`
-- |   * returns the lag based on the last offset in the batch (also known as "high")
-- | * `offsetLagLow(): string`
-- |   * returns the lag based on the first offset in the batch
-- | * `partition: number`
-- | * `topic: string`
-- |
type BatchImpl =
  { firstOffset :: Effect.Effect (Data.Nullable.Nullable String)
  , highWatermark :: String
  , isEmpty :: Effect.Effect Boolean
  , lastOffset :: Effect.Effect String
  , messages :: Array KafkaMessageImpl
  , offsetLag :: Effect.Effect String
  , offsetLagLow :: Effect.Effect String
  , partition :: Int
  , topic :: String
  }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1032
foreign import data Consumer :: Type

type ConsumerConfig =
  { groupId :: String }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L152
-- |
-- | Required
-- | * `groupId: string`
-- |
-- | Unsupported
-- | * `allowAutoTopicCreation?: boolean`
-- | * `heartbeatInterval?: number`
-- | * `maxBytes?: number`
-- | * `maxBytesPerPartition?: number`
-- | * `maxInFlightRequests?: number`
-- | * `maxWaitTimeInMs?: number`
-- | * `metadataMaxAge?: number`
-- | * `minBytes?: number`
-- | * `partitionAssigners?: PartitionAssigner[]`
-- | * `rackId?: string`
-- | * `readUncommitted?: boolean`
-- | * `rebalanceTimeout?: number`
-- | * `retry?: RetryOptions & { restartOnFailure?: (err: Error) => Promise<boolean> }`
-- | * `sessionTimeout?: number`
type ConsumerConfigImpl =
  { groupId :: String }

type ConsumerRunConfig =
  { autoCommit ::
      Data.Maybe.Maybe
        { autoCommitInterval :: Data.Maybe.Maybe Number
        , autoCommitThreshold :: Data.Maybe.Maybe Number
        }
  , eachBatch :: EachBatchHandler
  , eachBatchAutoResolve :: Data.Maybe.Maybe Boolean
  , partitionsConsumedConcurrently :: Data.Maybe.Maybe Int
  }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1016
-- |
-- | Optional
-- | * `autoCommit?: boolean`
-- |   * see https://kafka.js.org/docs/consuming#a-name-auto-commit-a-autocommit
-- | * `autoCommitInterval?: number | null`
-- |   * in milliseconds
-- | * `autoCommitThreshold?: number | null`
-- |   * in milliseconds
-- | * `eachBatch?: EachBatchHandler`
-- |   * see https://kafka.js.org/docs/consuming#a-name-each-batch-a-eachbatch
-- | * `eachBatchAutoResolve?: boolean`
-- |   * auto commit after successful `eachBatch`
-- |   * default to `true`
-- | * `partitionsConsumedConcurrently?: number`
-- |
-- | Unsupported
-- | * `eachMessage?: EachMessageHandler`
type ConsumerRunConfigImpl =
  Kafka.FFI.Object
    ()
    ( autoCommit :: Boolean
    , autoCommitInterval :: Number
    , autoCommitThreshold :: Number
    , eachBatch :: EachBatchHandlerImpl
    , eachBatchAutoResolve :: Boolean
    , partitionsConsumedConcurrently :: Int
    )

type ConsumerSubscribeTopics =
  { fromBeginning :: Data.Maybe.Maybe Boolean
  , topics :: Array Topic
  }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1030
-- |
-- | Required
-- | * `topics: (string | RegExp)[]`
-- |
-- | Optional
-- | * `fromBeginning?: boolean`
-- |   * default to `false`, see https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/src/consumer/index.js#L134
type ConsumerSubscribeTopicsImpl =
  Kafka.FFI.Object
    ( topics :: Array ConsumerSubscribeTopicImpl
    )
    ( fromBeginning :: Boolean
    )

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1030
-- |
-- | `(string | RegExp)`
type ConsumerSubscribeTopicImpl =
  String
    Untagged.Union.|+| Data.String.Regex.Regex

type EachBatchHandler =
  EachBatchPayload -> Effect.Aff.Aff Unit

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1013
-- |
-- | `(payload: EachBatchPayload) => Promise<void>`
type EachBatchHandlerImpl =
  Effect.Uncurried.EffectFn1
    EachBatchPayloadImpl
    (Control.Promise.Promise Unit)

type EachBatchPayload =
  { batch :: Batch
  , commitOffsetsIfNecessary :: Data.Maybe.Maybe Offsets -> Effect.Aff.Aff Unit
  , heartbeat :: Effect.Aff.Aff Unit
  , isRunning :: Effect.Effect Boolean
  , isStale :: Effect.Effect Boolean
  , pause :: Effect.Effect { resume :: Effect.Effect Unit }
  , resolveOffset :: { offset :: String } -> Effect.Effect Unit
  , uncommittedOffsets :: Effect.Effect Offsets
  }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L990
-- |
-- | * `batch: Batch`
-- | * `commitOffsetsIfNecessary(offsets?: Offsets): Promise<void>`
-- | * `heartbeat(): Promise<void>`
-- | * `isRunning(): boolean`
-- | * `isStale(): boolean`
-- | * `pause(): () => void`
-- | * `resolveOffset(offset: string): void`
-- | * `uncommittedOffsets(): OffsetsByTopicPartition`
type EachBatchPayloadImpl =
  { batch :: BatchImpl
  , commitOffsetsIfNecessary ::
      Effect.Uncurried.EffectFn1
        (Data.Nullable.Nullable OffsetsImpl)
        (Control.Promise.Promise Unit)
  , heartbeat :: Effect.Effect (Control.Promise.Promise Unit)
  , isRunning :: Effect.Effect Boolean
  , isStale :: Effect.Effect Boolean
  , pause :: Effect.Effect (Effect.Effect Unit)
  , resolveOffset :: Effect.Uncurried.EffectFn1 String Unit
  , uncommittedOffsets :: Effect.Effect OffsetsImpl
  }

type KafkaMessage =
  { attributes :: Int
  , headers :: Data.Maybe.Maybe Kafka.Type.MessageHeaders
  , key :: Data.Maybe.Maybe Node.Buffer.Buffer
  , offset :: String
  , size :: Data.Maybe.Maybe Int
  , timestamp :: String
  , value :: Data.Maybe.Maybe Node.Buffer.Buffer
  }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L727
-- |
-- | `type KafkaMessage = MessageSetEntry | RecordBatchEntry`
-- | * `MessageSetEntry` https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L707
-- |   * `size: number`
-- |   * `headers?: never`
-- | * `RecordBatchEntry` https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L717
-- |   * `headers: IHeaders`
-- |   * `size?: never`
-- |
-- | NOTE The only difference between `MessageSetEntry` and `RecordBatchEntry`
-- | is that they either has `headers` or `size` but not both.
-- |
-- | `kafkajs` decoder decides to decode `messages` as `MessageSetEntry`
-- | or `RecordBatchEntry` based off a `magicByte` in the `messages` Buffer.
-- | See https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/src/protocol/requests/fetch/v4/decodeMessages.js#L22
-- |
-- | Required
-- | * `attributes: number`
-- |   * `integer`, see https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/src/protocol/message/v1/decoder.js#L2
-- | * `key: Buffer | null`
-- | * `offset: string`
-- | * `timestamp: string`
-- | * `value: Buffer | null`
-- |
-- | Optional
-- | * `headers: IHeaders` or `headers?: never`
-- | * `size: number` or `size?: never`
-- |   * `integer`, see https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/src/protocol/messageSet/decoder.js#L89
type KafkaMessageImpl =
  Kafka.FFI.Object
    ( attributes :: Int
    , key :: Data.Nullable.Nullable Node.Buffer.Buffer
    , offset :: String
    , timestamp :: String
    , value :: Data.Nullable.Nullable Node.Buffer.Buffer
    )
    ( headers :: Kafka.Type.MessageHeadersImpl
    , size :: Int
    )

type Offsets =
  { topics :: Array TopicOffsets
  }

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L660
-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L843
-- |
-- | NOTE `Offsets` and `OffsetsByTopicPartition` are exactly the same
-- |
-- | `topics: TopicOffsets[]`
type OffsetsImpl =
  { topics :: Array TopicOffsetsImpl
  }

type PartitionOffset =
  { offset :: String
  , partition :: Int
  }

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L650
-- |
-- | * `offset: string`
-- | * `partition: number`
type PartitionOffsetsImpl =
  { offset :: String
  , partition :: Int
  }

data Topic
  = TopicName String
  | TopicRegex Data.String.Regex.Regex

type TopicOffsets =
  { partitions :: Array PartitionOffset
  , topic :: String
  }

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L655
-- |
-- | * `partitions: PartitionOffset[]`
-- | * `topic: string`
type TopicOffsetsImpl =
  { partitions :: Array PartitionOffsetsImpl
  , topic :: String
  }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1033
-- |
-- | `connect(): Promise<void>`
foreign import _connect ::
  Effect.Uncurried.EffectFn1
    Consumer
    (Control.Promise.Promise Unit)

connect :: Consumer -> Effect.Aff.Aff Unit
connect consumer' =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn1 _connect consumer'

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L12
-- |
-- | `consumer(config: ConsumerConfig): Consumer`
foreign import _consumer ::
  Effect.Uncurried.EffectFn2
    Kafka.Kafka.Kafka
    ConsumerConfigImpl
    Consumer

consumer :: Kafka.Kafka.Kafka -> ConsumerConfig -> Effect.Effect Consumer
consumer kafka config =
  Effect.Uncurried.runEffectFn2 _consumer kafka
    $ toConsumerConfigImpl config
  where
  toConsumerConfigImpl :: ConsumerConfig -> ConsumerConfigImpl
  toConsumerConfigImpl x = x

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1034
-- |
-- | `disconnect(): Promise<void>`
foreign import _disconnect ::
  Effect.Uncurried.EffectFn1
    Consumer
    (Control.Promise.Promise Unit)

disconnect :: Consumer -> Effect.Aff.Aff Unit
disconnect consumer' =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn1 _disconnect consumer'

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1037
-- |
-- | `run(config?: ConsumerRunConfig): Promise<void>`
foreign import _run ::
  Effect.Uncurried.EffectFn2
    Consumer
    ConsumerRunConfigImpl
    (Control.Promise.Promise Unit)

run ::
  Consumer ->
  ConsumerRunConfig ->
  Effect.Aff.Aff Unit
run consumer' consumerRunConfig =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn2 _run consumer'
    $ toConsumerRunConfigImpl consumerRunConfig
  where
  fromBatchImpl :: BatchImpl -> Batch
  fromBatchImpl x =
    { firstOffset: Data.Nullable.toMaybe <$> x.firstOffset
    , highWatermark: x.highWatermark
    , isEmpty: x.isEmpty
    , lastOffset: x.lastOffset
    , messages: fromKafkaMessageImpl <$> x.messages
    , offsetLag: x.offsetLag
    , offsetLagLow: x.offsetLagLow
    , partition: x.partition
    , topic: x.topic
    }

  fromEachBatchPayloadImpl :: EachBatchPayloadImpl -> EachBatchPayload
  fromEachBatchPayloadImpl x =
    { batch: fromBatchImpl x.batch
    , commitOffsetsIfNecessary: \maybeOffsets ->
        Control.Promise.toAffE
          $ Effect.Uncurried.runEffectFn1 x.commitOffsetsIfNecessary
          $ Data.Nullable.toNullable maybeOffsets
    , heartbeat: Control.Promise.toAffE x.heartbeat
    , isRunning: x.isRunning
    , isStale: x.isStale
    , pause: { resume: _ } <$> x.pause
    , resolveOffset: \({ offset }) ->
        Effect.Uncurried.runEffectFn1 x.resolveOffset offset
    , uncommittedOffsets: x.uncommittedOffsets
    }

  fromKafkaMessageImpl :: KafkaMessageImpl -> KafkaMessage
  fromKafkaMessageImpl kafkaMessageImpl =
    record
      { key = Data.Nullable.toMaybe record.key
      , value = Data.Nullable.toMaybe record.value
      }
    where
    record = Kafka.FFI.objectToRecord kafkaMessageImpl

  toConsumerRunConfigImpl :: ConsumerRunConfig -> ConsumerRunConfigImpl
  toConsumerRunConfigImpl x = Kafka.FFI.objectFromRecord
    { autoCommit: Data.Maybe.isJust x.autoCommit
    , autoCommitInterval: x.autoCommit >>= _.autoCommitInterval
    , autoCommitThreshold: x.autoCommit >>= _.autoCommitThreshold
    , eachBatch: toEachBatchHandlerImpl x.eachBatch
    , eachBatchAutoResolve: x.eachBatchAutoResolve
    , partitionsConsumedConcurrently: x.partitionsConsumedConcurrently
    }

  toEachBatchHandlerImpl :: EachBatchHandler -> EachBatchHandlerImpl
  toEachBatchHandlerImpl eachBatchHandler =
    Effect.Uncurried.mkEffectFn1 \eachBatchPayloadImpl ->
      Control.Promise.fromAff
        $ eachBatchHandler
        $ fromEachBatchPayloadImpl eachBatchPayloadImpl

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1035
-- |
-- | `subscribe(subscription: ConsumerSubscribeTopics | ConsumerSubscribeTopic): Promise<void>`
-- |  * NOTE `ConsumerSubscribeTopic` is deprecated, see https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1027
foreign import _subscribe ::
  Effect.Uncurried.EffectFn2
    Consumer
    ConsumerSubscribeTopicsImpl
    (Control.Promise.Promise Unit)

subscribe ::
  Consumer ->
  ConsumerSubscribeTopics ->
  Effect.Aff.Aff Unit
subscribe consumer' consumerSubscribeTopics =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn2 _subscribe consumer'
    $ toConsumerSubscribeTopicsImpl consumerSubscribeTopics
  where
  toConsumerSubscribeTopicsImpl ::
    ConsumerSubscribeTopics ->
    ConsumerSubscribeTopicsImpl
  toConsumerSubscribeTopicsImpl x = Kafka.FFI.objectFromRecord
    { fromBeginning: x.fromBeginning
    , topics: toConsumerSubscribeTopicImpl <$> x.topics
    }

  toConsumerSubscribeTopicImpl ::
    Topic ->
    ConsumerSubscribeTopicImpl
  toConsumerSubscribeTopicImpl topic = case topic of
    TopicName string -> Untagged.Union.asOneOf string
    TopicRegex regex -> Untagged.Union.asOneOf regex
