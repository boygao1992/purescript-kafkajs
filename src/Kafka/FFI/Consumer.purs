module Kafka.FFI.Consumer
  ( BatchImpl
  , Consumer
  , ConsumerConfigImpl
  , ConsumerCrashEventImpl
  , ConsumerCrashEventListenerImpl
  , ConsumerGroupJoinEventImpl
  , ConsumerGroupJoinEventListenerImpl
  , ConsumerGroupJoinEventMemberAssignment
  , ConsumerRunConfigImpl
  , ConsumerSubscribeTopicImpl
  , ConsumerSubscribeTopicsImpl
  , EachBatchHandlerImpl
  , EachBatchPayloadImpl
  , EachMessageHandlerImpl
  , EachMessagePayloadImpl
  , InstrumentationEventImpl
  , KafkaMessageImpl
  , OffsetsByTopicParition
  , OffsetsImpl
  , PartitionOffset
  , RemoveInstrumentationEventListener
  , TopicOffsets
  , TopicPartitionOffset
  , _connect
  , _consumer
  , _disconnect
  , _onCrash
  , _onGroupJoin
  , _run
  , _seek
  , _subscribe
  ) where

import Prelude

import Control.Promise as Control.Promise
import Data.Nullable as Data.Nullable
import Data.String.Regex as Data.String.Regex
import Effect as Effect
import Effect.Aff as Effect.Aff
import Effect.Uncurried as Effect.Uncurried
import Foreign.Object as Foreign.Object
import Kafka.FFI as Kafka.FFI
import Kafka.FFI.Kafka as Kafka.FFI.Kafka
import Kafka.Type as Kafka.Type
import Node.Buffer as Node.Buffer
import Untagged.Union as Untagged.Union

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

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L152
-- |
-- | Required
-- | * `groupId: string`
-- |
-- | Optional
-- | * `allowAutoTopicCreation?: boolean`
-- | * `heartbeatInterval?: number`
-- | * `maxBytes?: number`
-- | * `maxBytesPerPartition?: number`
-- | * `maxInFlightRequests?: number`
-- | * `maxWaitTimeInMs?: number`
-- | * `metadataMaxAge?: number`
-- | * `minBytes?: number`
-- | * `readUncommitted?: boolean`
-- | * `rebalanceTimeout?: number`
-- | * `sessionTimeout?: number`
-- |
-- | Unsupported
-- | * `partitionAssigners?: PartitionAssigner[]`
-- | * `rackId?: string`
-- | * `retry?: RetryOptions & { restartOnFailure?: (err: Error) => Promise<boolean> }`
type ConsumerConfigImpl =
  Kafka.FFI.Object
    ( groupId :: String
    )
    ( allowAutoTopicCreation :: Boolean
    , heartbeatInterval :: Number
    , maxBytes :: Number
    , maxBytesPerPartition :: Number
    , maxInFlightRequests :: Int
    , maxWaitTimeInMs :: Number
    , metadataMaxAge :: Number
    , minBytes :: Number
    , readUncommitted :: Boolean
    , rebalanceTimeout :: Number
    , sessionTimeout :: Number
    )

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L960
-- |
-- | `type ConsumerCrashEvent = InstrumentationEvent<{...}>`
-- |  * `error: Error`
-- |  * `groupId: string`
-- |  * `restart: boolean`
type ConsumerCrashEventImpl =
  InstrumentationEventImpl
    { error :: Effect.Aff.Error
    , groupId :: String
    , restart :: Boolean
    }

type ConsumerCrashEventListenerImpl =
  Effect.Uncurried.EffectFn1
    ConsumerCrashEventImpl
    Unit

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L931
-- |
-- | `type ConsumerGroupJoinEvent = InstrumentationEvent<{...}>`
-- | * `duration: number`
-- | * `groupId: string`
-- | * `groupProtocol: string`
-- | * `isLeader: boolean`
-- | * `leaderId: string`
-- | * `memberAssignment: IMemberAssignment`
-- | * `memberId: string`
-- |
-- | https://github.com/tulios/kafkajs/blob/1ab72f2c3925685b730937dd34481a4faa0ddb03/src/consumer/consumerGroup.js#L338-L353
type ConsumerGroupJoinEventImpl =
  InstrumentationEventImpl
    { duration :: Number
    , groupId :: String
    , groupProtocol :: String
    , isLeader :: Boolean
    , leaderId :: String
    , memberAssignment :: ConsumerGroupJoinEventMemberAssignment
    , memberId :: String
    }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1054
-- |
-- | `(event: ConsumerGroupJoinEvent) => void`
type ConsumerGroupJoinEventListenerImpl =
  Effect.Uncurried.EffectFn1
    ConsumerGroupJoinEventImpl
    Unit

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L928
-- |
-- | ```
-- | export interface IMemberAssignment {
-- |   [key: string]: number[]
-- | }
-- | ```
type ConsumerGroupJoinEventMemberAssignment =
  Foreign.Object.Object
    (Array Int)

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
-- | * `eachMessage?: EachMessageHandler`
-- | * `partitionsConsumedConcurrently?: number`
type ConsumerRunConfigImpl =
  Kafka.FFI.Object
    ()
    ( autoCommit :: Boolean
    , autoCommitInterval :: Number
    , autoCommitThreshold :: Int
    , eachBatch :: EachBatchHandlerImpl
    , eachBatchAutoResolve :: Boolean
    , eachMessage :: EachMessageHandlerImpl
    , partitionsConsumedConcurrently :: Int
    )

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

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1013
-- |
-- | `(payload: EachBatchPayload) => Promise<void>`
type EachBatchHandlerImpl =
  Effect.Uncurried.EffectFn1
    EachBatchPayloadImpl
    (Control.Promise.Promise Unit)

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
  , uncommittedOffsets :: Effect.Effect OffsetsByTopicParition
  }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1014
-- |
-- | `(payload: EachMessagePayload) => Promise<void>`
type EachMessageHandlerImpl =
  Effect.Uncurried.EffectFn1
    EachMessagePayloadImpl
    (Control.Promise.Promise Unit)

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L982
-- |
-- | * `heartbeat(): Promise<void>`
-- | * `message: KafkaMessage`
-- | * `partition: number`
-- | * `pause(): () => void`
-- | * `topic: string`
type EachMessagePayloadImpl =
  { heartbeat :: Effect.Effect (Control.Promise.Promise Unit)
  , message :: KafkaMessageImpl
  , partition :: Int
  , pause :: Effect.Effect (Effect.Effect Unit)
  , topic :: String
  }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L382
-- |
-- | `interface InstrumentationEvent<T>`
-- | * `id: string`
-- |   * globally incremental ID, see https://github.com/tulios/kafkajs/blob/4246f921f4d66a95f32f159c890d0a3a83803713/src/instrumentation/event.js#L16
-- | * `payload: T`
-- | * `timestamp: number`
-- | * `type: string`
type InstrumentationEventImpl payload =
  { id :: String
  , payload :: payload
  , timestamp :: Number
  , type :: String
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

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L660
-- |
-- | `topics: TopicOffsets[]`
-- |
-- | NOTE `topics` is optional implementation-wise but marked as required in TS definition
-- | see comments above `EachBatchPayloadImpl` on `commitOffsetsIfNecessary`
type OffsetsImpl =
  Kafka.FFI.Object
    ()
    ( topics :: Array TopicOffsets
    )

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L843
-- |
-- | `topics: TopicOffsets[]`
type OffsetsByTopicParition =
  { topics :: Array TopicOffsets
  }

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L650
-- |
-- | * `offset: string`
-- | * `partition: number`
type PartitionOffset =
  { offset :: String
  , partition :: Int
  }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L389
-- | `type RemoveInstrumentationEventListener<T> = () => void`
type RemoveInstrumentationEventListener = Effect.Effect Unit

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L655
-- |
-- | * `partitions: PartitionOffset[]`
-- | * `topic: string`
type TopicOffsets =
  { partitions :: Array PartitionOffset
  , topic :: String
  }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L869
-- | 
-- | `TopicPartition & { offset: string }`
-- |
-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L865
-- | 
-- | `TopicPartition`
-- | * `topic: string`
-- | * `partition: number`
type TopicPartitionOffset =
  { offset :: String
  , partition :: Int
  , topic :: String
  }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1033
-- |
-- | `connect(): Promise<void>`
foreign import _connect ::
  Effect.Uncurried.EffectFn1
    Consumer
    (Control.Promise.Promise Unit)

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L12
-- |
-- | `consumer(config: ConsumerConfig): Consumer`
foreign import _consumer ::
  Effect.Uncurried.EffectFn2
    Kafka.FFI.Kafka.Kafka
    ConsumerConfigImpl
    Consumer

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1034
-- |
-- | `disconnect(): Promise<void>`
foreign import _disconnect ::
  Effect.Uncurried.EffectFn1
    Consumer
    (Control.Promise.Promise Unit)

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1084-L1087
-- |
-- | ```
-- | on(
-- |   eventName: ConsumerEvents['CRASH'],
-- |   listener: (event: ConsumerCrashEvent) => void
-- | ): RemoveInstrumentationEventListener<typeof eventName>
-- | ```
foreign import _onCrash ::
  Effect.Uncurried.EffectFn2
    Consumer
    ConsumerCrashEventListenerImpl
    RemoveInstrumentationEventListener

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1052-L1055
-- |
-- | ```
-- | on(
-- |   eventName: ConsumerEvents['GROUP_JOIN'],
-- |   listener: (event: ConsumerGroupJoinEvent) => void
-- | ): RemoveInstrumentationEventListener<typeof eventName>
-- | ```
foreign import _onGroupJoin ::
  Effect.Uncurried.EffectFn2
    Consumer
    ConsumerGroupJoinEventListenerImpl
    RemoveInstrumentationEventListener

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1037
-- |
-- | `run(config?: ConsumerRunConfig): Promise<void>`
foreign import _run ::
  Effect.Uncurried.EffectFn2
    Consumer
    ConsumerRunConfigImpl
    (Control.Promise.Promise Unit)

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1039
-- |
-- | `seek(topicPartitionOffset: TopicPartitionOffset): void`
foreign import _seek ::
  Effect.Uncurried.EffectFn2
    Consumer
    TopicPartitionOffset
    Unit

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1035
-- |
-- | `subscribe(subscription: ConsumerSubscribeTopics | ConsumerSubscribeTopic): Promise<void>`
-- |  * NOTE `ConsumerSubscribeTopic` is deprecated, see https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1027
foreign import _subscribe ::
  Effect.Uncurried.EffectFn2
    Consumer
    ConsumerSubscribeTopicsImpl
    (Control.Promise.Promise Unit)
