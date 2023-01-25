module Kafka.Consumer
  ( Assigner
  , AssignerAssignGroup
  , Batch
  , Cluster
  , Consume(..)
  , ConsumerConfig
  , ConsumerCrashEvent
  , ConsumerCrashEventListener
  , ConsumerGroupJoinEvent
  , ConsumerGroupJoinEventListener
  , ConsumerRunConfig
  , ConsumerSubscribeTopics
  , EachBatchHandler
  , EachBatchPayload
  , EachMessageHandler
  , EachMessagePayload
  , GroupMember
  , GroupMemberAssignment
  , GroupState
  , KafkaMessage
  , Offsets
  , MemberAssignment
  , MemberMetadata
  , PartitionAssigner(..)
  , PartitionAssignerConfig
  , PartitionAssignerCustom
  , Topic(..)
  , connect
  , consumer
  , disconnect
  , onCrash
  , onGroupJoin
  , roundRobin
  , run
  , seek
  , subscribe
  ) where

import Prelude

import Control.Promise as Control.Promise
import Data.Array as Data.Array
import Data.Maybe as Data.Maybe
import Data.Nullable as Data.Nullable
import Data.String.Regex as Data.String.Regex
import Data.Time.Duration as Data.Time.Duration
import Effect as Effect
import Effect.Aff as Effect.Aff
import Effect.Uncurried as Effect.Uncurried
import Foreign.Object as Foreign.Object
import Kafka.FFI as Kafka.FFI
import Kafka.FFI.AssignerProtocol as Kafka.FFI.AssignerProtocol
import Kafka.FFI.Consumer as Kafka.FFI.Consumer
import Kafka.FFI.Kafka as Kafka.FFI.Kafka
import Kafka.Type as Kafka.Type
import Node.Buffer as Node.Buffer
import Untagged.Union as Untagged.Union

-- | * `assign`
-- |   * builds an assignment plan with partitions per topic
-- | * `name`
-- |   * assigner/protocol name
-- | * `protocol`
-- |   * builds metadata for the Consumer Group which is accessible through `Admin.describeGroups` or `Consumer.describeGroup`
-- | * `version`
type Assigner =
  { assign ::
      AssignerAssignGroup ->
      Effect.Aff.Aff (Array GroupMemberAssignment)
  , name :: String
  , protocol ::
      { topics :: Array String } ->
      Effect.Effect GroupState
  , version :: Int
  }

type AssignerAssignGroup =
  { members :: Array GroupMember
  , topics :: Array String
  }

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

-- | * `findTopicPartitionMetadata`
-- |   * returns the partition metadata of a topic
type Cluster =
  { findTopicPartitionMetadata ::
      { topic :: String } ->
      Effect.Effect (Array Kafka.Type.PartitionMetadata)
  }

-- | * `EachBatch`
-- |   * see [Each Batch](https://kafka.js.org/docs/consuming#a-name-each-batch-a-eachbatch)
-- | * `EachMessage`
-- |   * see [Each Message](https://kafka.js.org/docs/consuming#a-name-each-message-a-eachmessage)
data Consume
  = EachBatch
      { autoResolve :: Data.Maybe.Maybe Boolean
      , handler :: EachBatchHandler
      }
  | EachMessage EachMessageHandler

-- | See [Options](https://kafka.js.org/docs/consuming#a-name-options-a-options)
-- |
-- | * `allowAutoTopicCreation`
-- |   * Allow topic creation when querying metadata for non-existent topics
-- |   * default: `true`
-- | * `groupId`
-- |   * consumer group ID
-- |   * Consumer groups allow a group of machines or processes to coordinate access to a list of topics, distributing the load among the consumers. When a consumer fails the load is automatically distributed to other members of the group. Consumer groups __must have__ unique group ids within the cluster, from a kafka broker perspective.
-- | * `heartbeatInterval`
-- |   * The expected time in milliseconds between heartbeats to the consumer coordinator. Heartbeats are used to ensure that the consumer's session stays active. The value must be set lower than session timeout
-- |   * default: `Milliseconds 3000`
-- | * `maxBytes`
-- |   * Maximum amount of bytes to accumulate in the response.
-- |   * default: `10485760` (10MB)
-- | * `maxBytesPerPartition`
-- |   * The maximum amount of data per-partition the server will return. This size must be at least as large as the maximum message size the server allows or else it is possible for the producer to send messages larger than the consumer can fetch. If that happens, the consumer can get stuck trying to fetch a large message on a certain partition
-- |   * default: `1048576` (1MB)
-- | * `maxInFlightRequests`
-- |   * Max number of requests that may be in progress at any time. If `Nothing` then no limit.
-- |   * default: `Nothing` (no limit)
-- | * `maxWaitTime`
-- |   * The maximum amount of time in milliseconds the server will block before answering the fetch request if there isn’t sufficient data to immediately satisfy the requirement given by `minBytes`
-- |   * default: `Milliseconds 5000`
-- | * `metadataMaxAge`
-- |   * The period of time in milliseconds after which we force a refresh of metadata even if we haven't seen any partition leadership changes to proactively discover any new brokers or partitions
-- |   * default: `Milliseconds 300000` (5 minutes)
-- | * `minBytes`
-- |   * Minimum amount of data the server should return for a fetch request, otherwise wait up to `maxWaitTime` for more data to accumulate.
-- |   * default: `1`
-- | * `partitionAssigners`
-- |   * list of partition assigners
-- |   * default: `[ roundRobin ]`
-- |   * see [Custom partition assigner](https://kafka.js.org/docs/consuming#a-name-custom-partition-assigner-a-custom-partition-assigner)
-- | * `readUncommitted`
-- |   * Configures the consumer isolation level. If `false` (default), the consumer will not return any transactional messages which were not committed.
-- |   * default: `false`
-- | * `rebalanceTimeout`
-- |   * The maximum time that the coordinator will wait for each member to rejoin when rebalancing the group
-- |   * default: `Milliseconds 60000` (1 minute)
-- | * `sessionTimeout`
-- |   * Timeout in milliseconds used to detect failures. The consumer sends periodic heartbeats to indicate its liveness to the broker. If no heartbeats are received by the broker before the expiration of this session timeout, then the broker will remove this consumer from the group and initiate a rebalance
-- |   * default: `Milliseconds 30000` (30 seconds)
type ConsumerConfig =
  { allowAutoTopicCreation :: Data.Maybe.Maybe Boolean
  , groupId :: String
  , heartbeatInterval :: Data.Maybe.Maybe Data.Time.Duration.Milliseconds
  , maxBytes :: Data.Maybe.Maybe Int
  , maxBytesPerPartition :: Data.Maybe.Maybe Int
  , maxInFlightRequests :: Data.Maybe.Maybe Int
  , maxWaitTime :: Data.Maybe.Maybe Data.Time.Duration.Milliseconds
  , metadataMaxAge :: Data.Maybe.Maybe Data.Time.Duration.Milliseconds
  , minBytes :: Data.Maybe.Maybe Int
  , partitionAssigners :: Data.Maybe.Maybe (Array PartitionAssigner)
  , readUncommitted :: Data.Maybe.Maybe Boolean
  , rebalanceTimeout :: Data.Maybe.Maybe Data.Time.Duration.Milliseconds
  , sessionTimeout :: Data.Maybe.Maybe Data.Time.Duration.Milliseconds
  }

type ConsumerCrashEvent =
  { error :: Effect.Aff.Error
  , groupId :: String
  , restart :: Boolean
  }

type ConsumerCrashEventListener =
  ConsumerCrashEvent -> Effect.Effect Unit

-- | * `duration`
-- |   * time lapsed since requested to join the Consumer Group
-- | * `groupId`
-- |   * Consumer Group ID which should match the one specified in the `ConsumerConfig`
-- | * `groupProtocol`
-- |   * Partition Assigner protocol name e.g. "RoundRobinAssigner"
-- | * `isLeader`
-- |   * is the Consumer Group Leader which is responsible for executing rebalance activity. Consumer Group Leader will take a list of current members, assign partitions to them and send it back to the coordinator. The Coordinator then communicates back to the members about their new partitions.
-- | * `leaderId`
-- |   * Member ID of the Consumer Group Leader
-- | * `memberAssignment`
-- |   * topic-partitions assigned to this Consumer
-- | * `memberId`
-- |   * Member ID of this Consumer in the Consumer Group
type ConsumerGroupJoinEvent =
  { duration :: Data.Time.Duration.Milliseconds
  , groupId :: String
  , groupProtocol :: String
  , isLeader :: Boolean
  , leaderId :: String
  , memberAssignment :: Kafka.FFI.Consumer.ConsumerGroupJoinEventMemberAssignment
  , memberId :: String
  }

type ConsumerGroupJoinEventListener =
  ConsumerGroupJoinEvent -> Effect.Effect Unit

-- | * `autoCommit`
-- |   * auto commit offsets periodically during a batch
-- |   * see [autoCommit](https://kafka.js.org/docs/consuming#a-name-auto-commit-a-autocommit)
-- |   * `interval`
-- |     * The consumer will commit offsets after a given period
-- |   * `threshold`
-- |     * The consumer will commit offsets after resolving a given number of messages
-- | * `eachBatch`
-- |   * `autoResolve`
-- |     * auto commit offsets after successful `eachBatch`
-- |     * default: `true`
-- |   * see [eachBatch](https://kafka.js.org/docs/consuming#a-name-each-batch-a-eachbatch)
-- | * `partitionsConsumedConcurrently`
-- |   * concurrently instead of sequentially invoke `eachBatch`/`eachMessage` for multiple partitions if count is greater than `1`. Messages in the same partition are still guaranteed to be processed in order, but messages from multiple partitions can be processed at the same time.
-- |   * should not be larger than the number of partitions consumed
-- |   * default: `1`
-- |   * see [Partition-aware concurrency](https://kafka.js.org/docs/consuming#a-name-concurrent-processing-a-partition-aware-concurrency)
type ConsumerRunConfig =
  { autoCommit ::
      Data.Maybe.Maybe
        { interval :: Data.Maybe.Maybe Effect.Aff.Milliseconds
        , threshold :: Data.Maybe.Maybe Int
        }
  , consume :: Consume
  , partitionsConsumedConcurrently :: Data.Maybe.Maybe Int
  }

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

type EachBatchHandler =
  EachBatchPayload -> Effect.Aff.Aff Unit

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

type EachMessageHandler =
  EachMessagePayload -> Effect.Aff.Aff Unit

-- | see [Each Message](https://kafka.js.org/docs/consuming#a-name-each-message-a-eachmessage)
-- |
-- | * `heartbeat`
-- |   * can be used to send heartbeat to the broker according to the set `heartbeatInterval` value in consumer [configuration](https://kafka.js.org/docs/consuming#options).
-- | * `message`
-- | * `pause`
-- |   * can be used to pause the consumer for the current topic-partition. All offsets resolved up to that point will be committed (subject to `eachBatchAutoResolve` and [autoCommit](https://kafka.js.org/docs/consuming#auto-commit)). Throw an error to pause in the middle of the batch without resolving the current offset. Alternatively, disable eachBatchAutoResolve. The returned function can be used to resume processing of the topic-partition. See [Pause & Resume](https://kafka.js.org/docs/consuming#pause-resume) for more information about this feature.
-- | * `partition`
-- | * `topic`
type EachMessagePayload =
  { heartbeat :: Effect.Aff.Aff Unit
  , message :: KafkaMessage
  , pause :: Effect.Effect { resume :: Effect.Effect Unit }
  , partition :: Int
  , topic :: String
  }

type GroupMember =
  { memberId :: String
  , memberMetadata :: MemberMetadata
  }

type GroupMemberAssignment =
  { memberAssignment :: MemberAssignment
  , memberId :: String
  }

type GroupState =
  { metadata :: MemberMetadata
  , name :: String
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

type MemberAssignment =
  { assignment :: Kafka.FFI.AssignerProtocol.Assignment
  , userData :: Data.Maybe.Maybe Node.Buffer.Buffer
  , version :: Int
  }

type MemberMetadata =
  { topics :: Array String
  , userData :: Data.Maybe.Maybe Node.Buffer.Buffer
  , version :: Int
  }

type Offsets =
  { topics :: Array Kafka.FFI.Consumer.TopicOffsets
  }

-- | * `PartitionAssignerCustom`
-- |   * PS version which is easier to work with and will be converted to FFI
-- | * `PartitionAssignerNative`
-- |   * FFI version
data PartitionAssigner
  = PartitionAssignerCustom PartitionAssignerCustom
  | PartitionAssignerNative Kafka.FFI.Consumer.PartitionAssignerImpl

type PartitionAssignerConfig =
  { cluster :: Cluster
  , groupId :: String
  }

type PartitionAssignerCustom =
  PartitionAssignerConfig ->
  Assigner

data Topic
  = TopicName String
  | TopicRegex Data.String.Regex.Regex

connect :: Kafka.FFI.Consumer.Consumer -> Effect.Aff.Aff Unit
connect consumer' =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn1 Kafka.FFI.Consumer._connect consumer'

consumer :: Kafka.FFI.Kafka.Kafka -> ConsumerConfig -> Effect.Effect Kafka.FFI.Consumer.Consumer
consumer kafka config =
  Effect.Uncurried.runEffectFn2 Kafka.FFI.Consumer._consumer kafka
    $ toConsumerConfigImpl config
  where
  fromAssignerAssignGroupImpl ::
    Kafka.FFI.Consumer.AssignerAssignGroupImpl ->
    AssignerAssignGroup
  fromAssignerAssignGroupImpl x =
    x
      { members = Data.Array.mapMaybe fromGroupMemberImpl x.members
      }

  fromClusterImpl :: Kafka.FFI.Consumer.ClusterImpl -> Cluster
  fromClusterImpl x =
    { findTopicPartitionMetadata: \({ topic }) -> do
        partitionMetadataImpls <-
          Effect.Uncurried.runEffectFn1 x.findTopicPartitionMetadata topic
        pure
          $ map Kafka.Type.fromPartitionMetadataImpl
          $ partitionMetadataImpls
    }

  fromGroupMemberImpl ::
    Kafka.FFI.Consumer.GroupMemberImpl ->
    Data.Maybe.Maybe GroupMember
  fromGroupMemberImpl x = do
    memberMetadata <- Kafka.FFI.AssignerProtocol.memberMetadataDecode x.memberMetadata
    pure x { memberMetadata = Kafka.FFI.objectToRecord memberMetadata }

  fromPartitionAssignerConfigImpl ::
    Kafka.FFI.Consumer.PartitionAssignerConfigImpl ->
    PartitionAssignerConfig
  fromPartitionAssignerConfigImpl x =
    x { cluster = fromClusterImpl x.cluster }

  toAssignerImpl :: Assigner -> Kafka.FFI.Consumer.AssignerImpl
  toAssignerImpl x =
    x
      { assign = Effect.Uncurried.mkEffectFn1 \assignerAssignGroupImpl -> do
          Control.Promise.fromAff do
            groupMemberAssignments <- x.assign
              $ fromAssignerAssignGroupImpl assignerAssignGroupImpl
            pure
              $ map toGroupMemberAssignmentImpl
              $ groupMemberAssignments
      , protocol = Effect.Uncurried.mkEffectFn1 \topics -> do
          groupState <- x.protocol topics
          pure $ toGroupStateImpl groupState
      }

  toConsumerConfigImpl :: ConsumerConfig -> Kafka.FFI.Consumer.ConsumerConfigImpl
  toConsumerConfigImpl x = Kafka.FFI.objectFromRecord
    { allowAutoTopicCreation: x.allowAutoTopicCreation
    , groupId: x.groupId
    , heartbeatInterval: x.heartbeatInterval <#> case _ of
        Data.Time.Duration.Milliseconds ms -> ms
    , maxBytes: x.maxBytes
    , maxBytesPerPartition: x.maxBytesPerPartition
    , maxInFlightRequests: x.maxInFlightRequests
    , maxWaitTimeInMs: x.maxWaitTime <#> case _ of
        Data.Time.Duration.Milliseconds ms -> ms
    , metadataMaxAge: x.metadataMaxAge <#> case _ of
        Data.Time.Duration.Milliseconds ms -> ms
    , minBytes: x.minBytes
    , partitionAssigners: x.partitionAssigners <#> \partitionAssigners ->
        partitionAssigners <#> case _ of
          PartitionAssignerCustom f -> toPartitionAssignerImpl f
          PartitionAssignerNative f -> f
    , readUncommitted: x.readUncommitted
    , rebalanceTimeout: x.rebalanceTimeout <#> case _ of
        Data.Time.Duration.Milliseconds ms -> ms
    , sessionTimeout: x.sessionTimeout <#> case _ of
        Data.Time.Duration.Milliseconds ms -> ms
    }

  toGroupMemberAssignmentImpl ::
    GroupMemberAssignment ->
    Kafka.FFI.Consumer.GroupMemberAssignmentImpl
  toGroupMemberAssignmentImpl x =
    x
      { memberAssignment =
          Kafka.FFI.AssignerProtocol.memberAssignmentEncode
            $ Kafka.FFI.objectFromRecord x.memberAssignment
      }

  toGroupStateImpl :: GroupState -> Kafka.FFI.Consumer.GroupStateImpl
  toGroupStateImpl x =
    x
      { metadata =
          Kafka.FFI.AssignerProtocol.memberMetadataEncode
            $ Kafka.FFI.objectFromRecord x.metadata
      }

  toPartitionAssignerImpl :: PartitionAssignerCustom -> Kafka.FFI.Consumer.PartitionAssignerImpl
  toPartitionAssignerImpl partitionAssignerCustom partitionAssignerConfigImpl =
    toAssignerImpl
      $ partitionAssignerCustom
      $ fromPartitionAssignerConfigImpl partitionAssignerConfigImpl

disconnect :: Kafka.FFI.Consumer.Consumer -> Effect.Aff.Aff Unit
disconnect consumer' =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn1 Kafka.FFI.Consumer._disconnect consumer'

onCrash ::
  Kafka.FFI.Consumer.Consumer ->
  ConsumerCrashEventListener ->
  Effect.Effect { removeListener :: Effect.Effect Unit }
onCrash consumer' consumerCrashEventListener = do
  removeListener <- Effect.Uncurried.runEffectFn2 Kafka.FFI.Consumer._onCrash consumer'
    $ toConsumerCrashEventListenerImpl consumerCrashEventListener
  pure { removeListener }
  where
  fromConsumerGropuJoinEventImpl ::
    Kafka.FFI.Consumer.ConsumerCrashEventImpl ->
    ConsumerCrashEvent
  fromConsumerGropuJoinEventImpl x = x.payload

  toConsumerCrashEventListenerImpl ::
    ConsumerCrashEventListener ->
    Kafka.FFI.Consumer.ConsumerCrashEventListenerImpl
  toConsumerCrashEventListenerImpl listener =
    Effect.Uncurried.mkEffectFn1 \eventImpl ->
      listener
        $ fromConsumerGropuJoinEventImpl eventImpl

onGroupJoin ::
  Kafka.FFI.Consumer.Consumer ->
  ConsumerGroupJoinEventListener ->
  Effect.Effect { removeListener :: Effect.Effect Unit }
onGroupJoin consumer' consumerGroupJoinEventListener = do
  removeListener <- Effect.Uncurried.runEffectFn2 Kafka.FFI.Consumer._onGroupJoin consumer'
    $ toConsumerGroupJoinEventListenerImpl consumerGroupJoinEventListener
  pure { removeListener }
  where
  fromConsumerGropuJoinEventImpl ::
    Kafka.FFI.Consumer.ConsumerGroupJoinEventImpl ->
    ConsumerGroupJoinEvent
  fromConsumerGropuJoinEventImpl x =
    { duration: Data.Time.Duration.Milliseconds x.payload.duration
    , groupId: x.payload.groupId
    , groupProtocol: x.payload.groupProtocol
    , isLeader: x.payload.isLeader
    , leaderId: x.payload.leaderId
    , memberAssignment: x.payload.memberAssignment
    , memberId: x.payload.memberId
    }

  toConsumerGroupJoinEventListenerImpl ::
    ConsumerGroupJoinEventListener ->
    Kafka.FFI.Consumer.ConsumerGroupJoinEventListenerImpl
  toConsumerGroupJoinEventListenerImpl listener =
    Effect.Uncurried.mkEffectFn1 \eventImpl ->
      listener
        $ fromConsumerGropuJoinEventImpl eventImpl

-- | Default partition assigner from `kafkajs`
roundRobin :: PartitionAssigner
roundRobin = PartitionAssignerNative Kafka.FFI.Consumer.roundRobin

run ::
  Kafka.FFI.Consumer.Consumer ->
  ConsumerRunConfig ->
  Effect.Aff.Aff Unit
run consumer' consumerRunConfig =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn2 Kafka.FFI.Consumer._run consumer'
    $ toConsumerRunConfigImpl consumerRunConfig
  where
  fromBatchImpl :: Kafka.FFI.Consumer.BatchImpl -> Batch
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

  fromEachBatchPayloadImpl :: Kafka.FFI.Consumer.EachBatchPayloadImpl -> EachBatchPayload
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

  fromEachMessagePayloadImpl :: Kafka.FFI.Consumer.EachMessagePayloadImpl -> EachMessagePayload
  fromEachMessagePayloadImpl x =
    { heartbeat: Control.Promise.toAffE x.heartbeat
    , message: fromKafkaMessageImpl x.message
    , partition: x.partition
    , pause: { resume: _ } <$> x.pause
    , topic: x.topic
    }

  fromKafkaMessageImpl :: Kafka.FFI.Consumer.KafkaMessageImpl -> KafkaMessage
  fromKafkaMessageImpl kafkaMessageImpl =
    record
      { headers = Data.Maybe.fromMaybe Foreign.Object.empty record.headers
      , key = Data.Nullable.toMaybe record.key
      , value = Data.Nullable.toMaybe record.value
      }
    where
    record = Kafka.FFI.objectToRecord kafkaMessageImpl

  toConsumerRunConfigImpl :: ConsumerRunConfig -> Kafka.FFI.Consumer.ConsumerRunConfigImpl
  toConsumerRunConfigImpl x = Kafka.FFI.objectFromRecord
    { autoCommit: Data.Maybe.isJust x.autoCommit
    , autoCommitInterval: do
        autoCommit <- x.autoCommit
        interval <- autoCommit.interval
        pure case interval of
          Effect.Aff.Milliseconds ms -> ms
    , autoCommitThreshold: x.autoCommit >>= _.threshold
    , eachBatch: case x.consume of
        EachBatch eachBatch -> Data.Maybe.Just $
          toEachBatchHandlerImpl eachBatch.handler
        EachMessage _ -> Data.Maybe.Nothing
    , eachBatchAutoResolve: case x.consume of
        EachBatch eachBatch -> eachBatch.autoResolve
        EachMessage _ -> Data.Maybe.Nothing
    , eachMessage: case x.consume of
        EachBatch _ -> Data.Maybe.Nothing
        EachMessage eachMessageHandler -> Data.Maybe.Just $
          toEachMessageHandlerImpl eachMessageHandler
    , partitionsConsumedConcurrently: x.partitionsConsumedConcurrently
    }

  toEachBatchHandlerImpl :: EachBatchHandler -> Kafka.FFI.Consumer.EachBatchHandlerImpl
  toEachBatchHandlerImpl eachBatchHandler =
    Effect.Uncurried.mkEffectFn1 \eachBatchPayloadImpl ->
      Control.Promise.fromAff
        $ eachBatchHandler
        $ fromEachBatchPayloadImpl eachBatchPayloadImpl

  toEachMessageHandlerImpl :: EachMessageHandler -> Kafka.FFI.Consumer.EachMessageHandlerImpl
  toEachMessageHandlerImpl eachMessageHandler =
    Effect.Uncurried.mkEffectFn1 \eachMessagePayloadImpl ->
      Control.Promise.fromAff
        $ eachMessageHandler
        $ fromEachMessagePayloadImpl eachMessagePayloadImpl

seek :: Kafka.FFI.Consumer.Consumer -> Kafka.FFI.Consumer.TopicPartitionOffset -> Effect.Effect Unit
seek consumer' topicPartitionOffset =
  Effect.Uncurried.runEffectFn2 Kafka.FFI.Consumer._seek consumer' topicPartitionOffset

subscribe ::
  Kafka.FFI.Consumer.Consumer ->
  ConsumerSubscribeTopics ->
  Effect.Aff.Aff Unit
subscribe consumer' consumerSubscribeTopics =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn2 Kafka.FFI.Consumer._subscribe consumer'
    $ toConsumerSubscribeTopicsImpl consumerSubscribeTopics
  where
  toConsumerSubscribeTopicsImpl ::
    ConsumerSubscribeTopics ->
    Kafka.FFI.Consumer.ConsumerSubscribeTopicsImpl
  toConsumerSubscribeTopicsImpl x = Kafka.FFI.objectFromRecord
    { fromBeginning: x.fromBeginning
    , topics: toConsumerSubscribeTopicImpl <$> x.topics
    }

  toConsumerSubscribeTopicImpl ::
    Topic ->
    Kafka.FFI.Consumer.ConsumerSubscribeTopicImpl
  toConsumerSubscribeTopicImpl topic = case topic of
    TopicName string -> Untagged.Union.asOneOf string
    TopicRegex regex -> Untagged.Union.asOneOf regex
