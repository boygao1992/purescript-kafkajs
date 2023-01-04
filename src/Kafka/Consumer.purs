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
import Foreign.Object as Foreign.Object
import Kafka.FFI as Kafka.FFI
import Kafka.Kafka as Kafka.Kafka
import Kafka.Type as Kafka.Type
import Node.Buffer as Node.Buffer
import Untagged.Union as Untagged.Union

-- | see comments in https://github.com/tulios/kafkajs/blob/v2.2.3/src/consumer/batch.js
-- |
-- | * `firstOffset`
-- |   * offset of the first message in the batch
-- |   * `Nothing` if there is no message in the batch (within the requested offset)
-- | * `highWatermark`
-- |   * is the last committed offset within the topic partition. It can be useful for calculating lag.
-- |   * [LEO (end-of-log offset) vs HW (high watermark)](https://stackoverflow.com/a/67806069)
-- | * `isEmpty`
-- |   * if there is no message in the batch
-- | * `lastOffset`
-- |   * offset of the last message in the batch
-- | * `messages`
-- | * `offsetLag`
-- |   * returns the lag based on the last offset in the batch (also known as "high")
-- | * `offsetLagLow`
-- |   * returns the lag based on the first offset in the batch
-- | * `partition`
-- |   * partition ID
-- | * `topic`
-- |   * topic name
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
-- | * `firstOffset(): string | null`
-- |   * `null` when `broker.fetch` returns stale messages from a partition, see https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/src/consumer/batch.js#L20-L25
-- | * `highWatermark: string`
-- | * `isEmpty(): boolean`
-- | * `lastOffset(): string`
-- |   * when `messages` is empty, see https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/src/consumer/batch.js#L77
-- | * `messages: KafkaMessage[]`
-- | * `offsetLag(): string`
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

-- | * `groupId`
-- |   * consumer group ID
-- |   * Consumer groups allow a group of machines or processes to coordinate access to a list of topics, distributing the load among the consumers. When a consumer fails the load is automatically distributed to other members of the group. Consumer groups __must have__ unique group ids within the cluster, from a kafka broker perspective.
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

-- | * `autoCommit`
-- |   * auto commit offsets periodically during a batch
-- |   * see [autoCommit](https://kafka.js.org/docs/consuming#a-name-auto-commit-a-autocommit)
-- | * `eachBatch`
-- |   * see [eachBatch](https://kafka.js.org/docs/consuming#a-name-each-batch-a-eachbatch)
-- | * `eachBatchAutoResolve`
-- |   * auto commit offsets after successful `eachBatch`
-- |   * default: `true`
-- | * `partitionsConsumedConcurrently`
-- |   * concurrently instead of sequentially invoke `eachBatch`/`eachMessage` for multiple partitions if count is greater than `1`. Messages in the same partition are still guaranteed to be processed in order, but messages from multiple partitions can be processed at the same time.
-- |   * should not be larger than the number of partitions consumed
-- |   * default: `1`
-- |   * see [Partition-aware concurrency](https://kafka.js.org/docs/consuming#a-name-concurrent-processing-a-partition-aware-concurrency)
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
-- | * `autoCommitInterval?: number | null`
-- |   * in milliseconds
-- | * `autoCommitThreshold?: number | null`
-- |   * in milliseconds
-- | * `eachBatch?: EachBatchHandler`
-- | * `eachBatchAutoResolve?: boolean`
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

-- | * `fromBeginning`
-- |   * if `true` use the earliest offset, otherwise use the latest offset.
-- |   * default: `false`
-- |   * see [fromBeginning](https://kafka.js.org/docs/consuming#a-name-from-beginning-a-frombeginning)
-- | * `topics`
-- |   * a list of topic names or regex for fuzzy match
-- |   * if a regex is included, `kafkajs` will fetch all topics currently (the moment `subscribe` is invoked but not in the future) exists from cluster metadata. See https://github.com/tulios/kafkajs/blob/196105c224353113ae3e7f8ef54ac9bad9951143/src/consumer/index.js#L158
-- |   * see [Consuming Messages](https://kafka.js.org/docs/consuming)
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

-- | see [Each Batch](https://kafka.js.org/docs/consuming#a-name-each-batch-a-eachbatch)
-- |
-- | * `commitOffsets`
-- |   * commits offsets if provided, otherwise commits most recently resolved offsets ignoring [autoCommit](https://kafka.js.org/docs/consuming#auto-commit) configurations (`autoCommitInterval` and `autoCommitThreshold`)
-- | * `commitOffsetsIfNecessary`
-- |   * is used to commit most recently resolved offsets based on the [autoCommit](https://kafka.js.org/docs/consuming#auto-commit) configurations (`autoCommitInterval` and `autoCommitThreshold`). Note that auto commit won't happen in `eachBatch` if `commitOffsetsIfNecessary` is not invoked. Take a look at [autoCommit](https://kafka.js.org/docs/consuming#auto-commit) for more information.
-- | * `heartbeat`
-- |   * can be used to send heartbeat to the broker according to the set `heartbeatInterval` value in consumer [configuration](https://kafka.js.org/docs/consuming#options).
-- | * `isRunning`
-- |   * returns `true` if consumer is in running state, else it returns `false`.
-- | * `isStale`
-- |   * returns whether the messages in the batch have been rendered stale through some other operation and should be discarded. For example, when calling [`consumer.seek`](https://kafka.js.org/docs/consuming#seek) the messages in the batch should be discarded, as they are not at the offset we seeked to.
-- | * `pause`
-- |   * can be used to pause the consumer for the current topic-partition. All offsets resolved up to that point will be committed (subject to `eachBatchAutoResolve` and [autoCommit](https://kafka.js.org/docs/consuming#auto-commit)). Throw an error to pause in the middle of the batch without resolving the current offset. Alternatively, disable eachBatchAutoResolve. The returned function can be used to resume processing of the topic-partition. See [Pause & Resume](https://kafka.js.org/docs/consuming#pause-resume) for more information about this feature.
-- | * `resolveOffset`
-- |   * is used to mark a message in the batch as processed. In case of errors, the consumer will automatically commit the resolved offsets.
-- |   * use `offset` on `KafkaMessage`
-- |   * there's no need to explicitly specify `topic` and `partition` because each batch of messages comes from the same partition and they are implicitly tracked by `consumerGroup`
-- | * `uncommittedOffsets`
-- |   * returns all offsets by topic-partition which have not yet been committed.
type EachBatchPayload =
  { batch :: Batch
  , commitOffsets :: Data.Maybe.Maybe Offsets -> Effect.Aff.Aff Unit
  , commitOffsetsIfNecessary :: Effect.Aff.Aff Unit
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
-- |   * `null` - `commitOffsetsIfNecessary()`
-- |     * see https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/src/consumer/runner.js#L308
-- |   * `{}` - `commitOffsets({})`
-- |     * commit all `uncommittedOffsets()`
-- |     * see https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/src/consumer/offsetManager/index.js#L248
-- |   * `{ topics: _ }` - `commitOffsets({ topics: _ })`
-- |     * commit the specified topic-partition offsets
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
  , uncommittedOffsets :: Effect.Effect OffsetsByTopicParitionImpl
  }

-- | * `headers`
-- | * `key`
-- | * `offset`
-- |   * `Int64` in `String`
-- | * `timestamp`
-- |   * `Data.DateTime.Instant.Instant` in `String`
-- | * `value`
type KafkaMessage =
  { headers :: Kafka.Type.MessageHeaders
  , key :: Data.Maybe.Maybe Node.Buffer.Buffer
  , offset :: String
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
-- | `MessageSet` was renamed to `RecordBatch` since `Kafka 0.11` with
-- | significantly structural changes.
-- | See [Message sets | A Guide To The Kafka Protocol](https://cwiki.apache.org/confluence/display/KAFKA/A+Guide+To+The+Kafka+Protocol#AGuideToTheKafkaProtocol-Messagesets)
-- |
-- | Required
-- | * `key: Buffer | null`
-- | * `offset: string`
-- | * `timestamp: string`
-- | * `value: Buffer | null`
-- |
-- | Optional
-- | * `headers: IHeaders` or `headers?: never`
-- |
-- | Unsupported
-- | * `attributes: number`
-- |   * `integer`, see https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/src/protocol/message/v1/decoder.js#L2
-- | * `size: number` or `size?: never`
-- |   * `integer`, see https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/src/protocol/messageSet/decoder.js#L89
-- |
-- | Undocumented
-- | * `batchContext: object`
-- |   ```
-- |   batchContext: {
-- |     firstOffset: '0',
-- |     firstTimestamp: '1670985665652',
-- |     partitionLeaderEpoch: 0,
-- |     inTransaction: false,
-- |     isControlBatch: false,
-- |     lastOffsetDelta: 2,
-- |     producerId: '-1',
-- |     producerEpoch: 0,
-- |     firstSequence: 0,
-- |     maxTimestamp: '1670985665652',
-- |     timestampType: 0,
-- |     magicByte: 2
-- |   }
-- |   ```
-- | * `isControlRecord: boolean`
-- | * `magicByte: int`
type KafkaMessageImpl =
  Kafka.FFI.Object
    ( key :: Data.Nullable.Nullable Node.Buffer.Buffer
    , offset :: String
    , timestamp :: String
    , value :: Data.Nullable.Nullable Node.Buffer.Buffer
    )
    ( headers :: Kafka.Type.MessageHeadersImpl
    )

type Offsets =
  { topics :: Array TopicOffsets
  }

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L660
-- |
-- | `topics: TopicOffsets[]`
-- |
-- | NOTE `topics` is optional implementation-wise but marked as required in TS definition
-- | see comments above `EachBatchPayloadImpl` on `commitOffsetsIfNecessary`
type OffsetsImpl =
  Kafka.FFI.Object
    ()
    ( topics :: Array TopicOffsetsImpl
    )

type OffsetsByTopicParition =
  { topics :: Array TopicOffsets
  }

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L843
-- |
-- | `topics: TopicOffsets[]`
type OffsetsByTopicParitionImpl =
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
    , commitOffsetsIfNecessary:
        Control.Promise.toAffE
          $ Effect.Uncurried.runEffectFn1 x.commitOffsetsIfNecessary
          $ Data.Nullable.null
    , commitOffsets: \maybeOffsets ->
        Control.Promise.toAffE
          $ Effect.Uncurried.runEffectFn1 x.commitOffsetsIfNecessary
          $ Data.Nullable.notNull
          $ case maybeOffsets of
              Data.Maybe.Nothing -> Kafka.FFI.objectFromRecord {}
              Data.Maybe.Just offsets -> Kafka.FFI.objectFromRecord offsets
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
      { headers = Data.Maybe.fromMaybe Foreign.Object.empty record.headers
      , key = Data.Nullable.toMaybe record.key
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
