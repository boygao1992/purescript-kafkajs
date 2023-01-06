module Kafka.Producer
  ( Acks(..)
  , CompressionType(..)
  , Message
  , Producer
  , ProducerBatch
  , ProducerConfig
  , ProducerRecord
  , RecordMetadata
  , TopicMessages
  , Value(..)
  , connect
  , disconnect
  , producer
  , send
  , sendBatch
  ) where

import Prelude

import Control.Promise as Control.Promise
import Data.Array as Data.Array
import Data.DateTime.Instant as Data.DateTime.Instant
import Data.Maybe as Data.Maybe
import Data.Nullable as Data.Nullable
import Data.Time.Duration as Data.Time.Duration
import Effect as Effect
import Effect.Aff as Effect.Aff
import Effect.Uncurried as Effect.Uncurried
import Kafka.FFI as Kafka.FFI
import Kafka.Kafka as Kafka.Kafka
import Kafka.Type as Kafka.Type
import Node.Buffer as Node.Buffer
import Untagged.Union as Untagged.Union

-- | Control the number of required acks.
-- | * `AcksAll`
-- |   * all insync replicas must acknowledge
-- | * `AcksNo`
-- |   * no acknowledgments
-- | * `AcksLeader`
-- |   * only waits for the leader to acknowledge
data Acks
  = AcksAll
  | AcksNo
  | AcksLeader

derive instance eqAcks :: Eq Acks
derive instance ordAcks :: Ord Acks

type AcksImpl = Int

data CompressionType
  = CompressionTypeNone
  | CompressionTypeGzip

derive instance eqCompressionType :: Eq CompressionType
derive instance ordCompressionType :: Ord CompressionType

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1116
-- | `CompressionTypes`
-- |
-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/src/protocol/message/compression/index.js#L5
-- | `Compression.Types`
-- |
-- | NOTE only `GZIP` is implemented
-- | see [`Compression.Codecs`](https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/src/protocol/message/compression/index.js#L13-L24)
type CompressionTypeImpl = Int

-- | see [Message structure](https://kafka.js.org/docs/producing#message-structure)
-- |
-- | * `headers`
-- |   * Metadata to associate with your message. See [Headers](https://kafka.js.org/docs/producing#message-headers)
-- | * `key`
-- |   * Used for partitioning. See [Key](https://kafka.js.org/docs/producing#message-key)
-- | * `partition`
-- |   * Which partition to send the message to. See [Key](https://kafka.js.org/docs/producing#message-key) for details on how the partition is decided if this property is omitted.
-- | * `timestamp`
-- |   * The timestamp of when the message was created. See [Timestamp](https://kafka.js.org/docs/producing#message-timestamp) for details.
-- |   * default: `Date.now()`
-- | * `value`
-- |   * Your message content. The value can be a `Buffer`, a `string` or `null`. The value will always be encoded as bytes when sent to Kafka. When consumed, the consumer will need to interpret the value according to your schema.
type Message =
  { headers :: Data.Maybe.Maybe Kafka.Type.MessageHeaders
  , key :: Data.Maybe.Maybe Value
  , partition :: Data.Maybe.Maybe Int
  , timestamp :: Data.Maybe.Maybe Data.DateTime.Instant.Instant
  , value :: Data.Maybe.Maybe Value
  }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L109
-- |
-- | Required
-- | * `value: Buffer | string | null`
-- |
-- | Optional
-- | * `headers?: IHeaders`
-- | * `key?: Buffer | string | null`
-- | * `partition?: number`
-- | * `timestamp?: string`
-- |   * NOTE the expected type is actually `number`
-- |     see [protocol.requests.produce.v7.request test](https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/src/protocol/requests/produce/v7/request.spec.js#L25)
-- |     see also [protocol.requests.produce.v3.request implementation](https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/src/protocol/requests/produce/v3/request.js#L99) which hasn't changed since `v3`
type MessageImpl =
  Kafka.FFI.Object
    ( value :: Data.Nullable.Nullable ValueImpl
    )
    ( headers :: Kafka.Type.MessageHeadersImpl
    , key :: ValueImpl
    , partition :: Int
    , timestamp :: Number
    )

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L787
foreign import data Producer :: Type

-- | * `acks`
-- |   * Control the number of required acks.
-- |   * default: `AcksAll`
-- | * `compression`
-- |   * compression codec
-- |   * default: `CompressionTypeNone`
-- | * `timeout`
-- |   * The time to await a response in ms
-- |   * default: `30000`
-- | * `topicMessages`
-- |   * a list of topics and for each topic a list of messages
type ProducerBatch =
  { acks :: Data.Maybe.Maybe Acks
  , compression :: Data.Maybe.Maybe CompressionType
  , timeout :: Data.Maybe.Maybe Data.Time.Duration.Milliseconds
  , topicMessages :: Array TopicMessages
  }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L753
-- |
-- | Optional
-- | * `acks?: number`
-- | * `compression?: CompressionTypes`
-- | * `timeout?: number`
-- | * `topicMessages?: TopicMessages[]`
type ProducerBatchImpl =
  Kafka.FFI.Object
    ()
    ( acks :: AcksImpl
    , compression :: CompressionTypeImpl
    , timeout :: Number
    , topicMessages :: Array TopicMessagesImpl
    )

-- | see [Options](https://kafka.js.org/docs/producing#options)
-- |
-- | * `allowAutoTopicCreation`
-- |   * Allow topic creation when querying metadata for non-existent topics
-- |   * default: `true`
-- | * `idempotent`
-- |   * If enabled producer will ensure each message is written exactly once. Acks must be set to `-1` ("all"). Retries will default to `MAX_SAFE_INTEGER`.
-- |   * default: `false`
-- | * `maxInFlightRequests`
-- |   * Max number of requests that may be in progress at any time. If falsey then no limit.
-- |   * default: `null` (no limit)
-- | * `metadataMaxAge`
-- |   * The period of time in milliseconds after which we force a refresh of metadata even if we haven't seen any partition leadership changes to proactively discover any new brokers or partitions
-- |   * default: `300000`
-- | * `transactionTimeout`
-- |   * The maximum amount of time in ms that the transaction coordinator will wait for a transaction status update from the producer before proactively aborting the ongoing transaction. If this value is larger than the `transaction.max.timeout.ms` setting in the broker, the request will fail with a `InvalidTransactionTimeout` error
-- |   * default: `60000`
-- | * `transactionalId`
-- |   * The `transactionalId` allows Kafka to fence out zombie instances by rejecting writes from producers with the same `transactionalId`, allowing only writes from the most recently registered producer. To ensure EoS (Exactly-once Semantics) in a stream processing application, it is important that the `transactionalId` is always the same for a given input topic and partition in the read-process-write cycle.
-- |   * see [Choosing a `transactionalId`](https://kafka.js.org/docs/transactions#choosing-a-transactionalid)
type ProducerConfig =
  { allowAutoTopicCreation :: Data.Maybe.Maybe Boolean
  , idempotent :: Data.Maybe.Maybe Boolean
  , maxInFlightRequests :: Data.Maybe.Maybe Int
  , metadataMaxAge :: Data.Maybe.Maybe Data.Time.Duration.Milliseconds
  , transactionTimeout :: Data.Maybe.Maybe Data.Time.Duration.Milliseconds
  , transactionalId :: Data.Maybe.Maybe String
  }

-- | https://github.com/tulios/kafkajs/blob/v2.2.3/types/index.d.ts#L98
-- |
-- | Optional
-- | * `allowAutoTopicCreation?: boolean`
-- | * `idempotent?: boolean`
-- | * `maxInFlightRequests?: number`
-- | * `metadataMaxAge?: number`
-- | * `transactionTimeout?: number`
-- | * `transactionalId?: string`
-- |
-- | Unsupported
-- | * `createPartitioner?: ICustomPartitioner`
-- | * `retry?: RetryOptions`
type ProducerConfigImpl =
  Kafka.FFI.Object
    ()
    ( allowAutoTopicCreation :: Boolean
    , idempotent :: Boolean
    , maxInFlightRequests :: Int
    , metadataMaxAge :: Number
    , transactionTimeout :: Number
    , transactionalId :: String
    )

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L729
-- |
-- | * `acks`
-- |   * Control the number of required acks.
-- |   * default: `AcksAll`
-- | * `compression`
-- |   * compression codec
-- |   * default: `CompressionTypeNone`
-- | * `messages`
-- |   * a list of messages to be sent
-- | * `timeout`
-- |   * The time to await a response in ms
-- |   * default: `30000`
-- | * `topic`
-- |   * topic name
type ProducerRecord =
  { acks :: Data.Maybe.Maybe Acks
  , compression :: Data.Maybe.Maybe CompressionType
  , messages :: Array Message
  , timeout :: Data.Maybe.Maybe Data.Time.Duration.Milliseconds
  , topic :: String
  }

-- | * `baseOffset`
-- |   * the offset of the first message in the associated segment file
-- | * `errorCode`
-- |   * the error code, or 0 if there was no error.
-- |   * see [protocal.error.errorCodes](https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/src/protocol/error.js#L4) for all the error codes supported by `kafkajs`
-- |   * see [Error Codes | Kafka Protocol Guide](https://kafka.apache.org/protocol.html#protocol_error_codes) for the complete list which has new additions
-- | * `logAppendTime`
-- |   * the timestamp returned by broker after appending the messages. If CreateTime is used for the topic, the timestamp will be -1. If LogAppendTime is used for the topic, the timestamp will be the broker local time when the messages are appended.
-- | * `logStartOffset`
-- |   * the start offset of the log at the time of this append
-- | * `partition`
-- | * `topicName`
type RecordMetadata =
  { baseOffset :: Data.Maybe.Maybe String
  , errorCode :: Int
  , logAppendTime :: Data.Maybe.Maybe String
  , logStartOffset :: Data.Maybe.Maybe String
  , partition :: Int
  , topicName :: String
  }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L737
-- |
-- | Required
-- | * `errorCode: number`
-- |   * NOTE `RecordMetadataImpl` is success response so likely `errorCode` is always `0` otherwise we should expect an exception raised from `Promise`
-- |     * see [protocol.requests.produce.v3.response](https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/src/protocol/requests/produce/v3/response.js#L45)
-- | * `partition: number`
-- | * `topicName: string`
-- |
-- | Optional
-- | * `baseOffset?: string`
-- | * `logAppendTime?: string`
-- | * `logStartOffset?: string`
-- |
-- | Unsupported
-- | * `offset?: string`
-- |   * NOTE doesn't exist in Kafka protocol schema. See https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/src/protocol/requests/produce/v7/response.js#L3-L14
-- | * `timestamp?: string`
-- |   * NOTE doesn't exist in Kafka protocol schema. See https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/src/protocol/requests/produce/v7/response.js#L3-L14
type RecordMetadataImpl =
  Kafka.FFI.Object
    ( errorCode :: Int
    , partition :: Int
    , topicName :: String
    )
    ( baseOffset :: String
    , logAppendTime :: String
    , logStartOffset :: String
    )

type TopicMessages =
  { messages :: Array Message
  , topic :: String
  }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L748
-- |
-- | * `messages: Message[]`
-- | * `topic: string`
type TopicMessagesImpl =
  { messages :: Array MessageImpl
  , topic :: String
  }

data Value
  = Buffer Node.Buffer.Buffer
  | String String

type ValueImpl =
  Node.Buffer.Buffer
    Untagged.Union.|+| String

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L788
-- |
-- | `connect(): Promise<void>`
foreign import _connect ::
  Effect.Uncurried.EffectFn1
    Producer
    (Control.Promise.Promise Unit)

connect :: Producer -> Effect.Aff.Aff Unit
connect producer' =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn1 _connect producer'

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L789
-- |
-- | `disconnect(): Promise<void>`
foreign import _disconnect ::
  Effect.Uncurried.EffectFn1
    Producer
    (Control.Promise.Promise Unit)

disconnect :: Producer -> Effect.Aff.Aff Unit
disconnect producer' =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn1 _disconnect producer'

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L11
-- |
-- | `producer(config?: ProducerConfig): Producer`
foreign import _producer ::
  Effect.Uncurried.EffectFn2
    Kafka.Kafka.Kafka
    ProducerConfigImpl
    Producer

producer :: Kafka.Kafka.Kafka -> ProducerConfig -> Effect.Effect Producer
producer kafka config =
  Effect.Uncurried.runEffectFn2 _producer kafka
    $ toProducerConfigImpl config
  where
  toProducerConfigImpl :: ProducerConfig -> ProducerConfigImpl
  toProducerConfigImpl x = Kafka.FFI.objectFromRecord
    { allowAutoTopicCreation: x.allowAutoTopicCreation
    , idempotent: x.idempotent
    , maxInFlightRequests: x.maxInFlightRequests
    , metadataMaxAge: x.metadataMaxAge <#> case _ of
        Data.Time.Duration.Milliseconds ms -> ms
    , transactionTimeout: x.transactionTimeout <#> case _ of
        Data.Time.Duration.Milliseconds ms -> ms
    , transactionalId: x.transactionalId
    }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/src/producer/messageProducer.js#L118
-- |
-- | NOTE logic is very simple so instead of FFI we rewrite in PS
send :: Producer -> ProducerRecord -> Effect.Aff.Aff (Array RecordMetadata)
send producer' x = sendBatch producer'
  { acks: x.acks
  , compression: x.compression
  , timeout: x.timeout
  , topicMessages: Data.Array.singleton topicMessages
  }
  where
  topicMessages :: TopicMessages
  topicMessages =
    { messages: x.messages
    , topic: x.topic
    }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L776
-- |
-- | `sendBatch(batch: ProducerBatch): Promise<RecordMetadata[]>`
foreign import _sendBatch ::
  Effect.Uncurried.EffectFn2
    Producer
    ProducerBatchImpl
    (Control.Promise.Promise (Array RecordMetadataImpl))

sendBatch :: Producer -> ProducerBatch -> Effect.Aff.Aff (Array RecordMetadata)
sendBatch producer' producerBatch = do
  recordMetadataImpls <- Control.Promise.toAffE do
    Effect.Uncurried.runEffectFn2 _sendBatch producer'
      $ toProducerBatchImpl producerBatch
  pure $ fromRecordMetadataImpl <$> recordMetadataImpls
  where
  fromRecordMetadataImpl :: RecordMetadataImpl -> RecordMetadata
  fromRecordMetadataImpl = Kafka.FFI.objectToRecord

  -- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/src/producer/messageProducer.js#L43-L46
  -- |
  -- | -1 = all replicas must acknowledge
  -- |  0 = no acknowledgments
  -- |  1 = only waits for the leader to acknowledge
  toAcksImpl :: Acks -> AcksImpl
  toAcksImpl = case _ of
    AcksAll -> -1
    AcksNo -> 0
    AcksLeader -> 1

  -- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/src/protocol/message/compression/index.js#L5
  -- |
  -- | None = 0
  -- | GZIP = 1
  toCompressionTypeImpl :: CompressionType -> CompressionTypeImpl
  toCompressionTypeImpl = case _ of
    CompressionTypeNone -> 0
    CompressionTypeGzip -> 1

  toMessageImpl :: Message -> MessageImpl
  toMessageImpl x = Kafka.FFI.objectFromRecord
    { headers: x.headers
    , key: toValueImpl <$> x.key
    , partition: x.partition
    , timestamp: x.timestamp <#> \timestamp ->
        case Data.DateTime.Instant.unInstant timestamp of
          Data.Time.Duration.Milliseconds ms -> ms
    , value: Data.Nullable.toNullable $ map toValueImpl $ x.value
    }

  toProducerBatchImpl :: ProducerBatch -> ProducerBatchImpl
  toProducerBatchImpl x = Kafka.FFI.objectFromRecord
    { acks: toAcksImpl <$> x.acks
    , compression: toCompressionTypeImpl <$> x.compression
    , timeout: x.timeout <#> case _ of
        Data.Time.Duration.Milliseconds ms -> ms
    , topicMessages: toTopicMessagesImpl <$> x.topicMessages
    }

  toTopicMessagesImpl :: TopicMessages -> TopicMessagesImpl
  toTopicMessagesImpl x =
    { messages: toMessageImpl <$> x.messages
    , topic: x.topic
    }

  toValueImpl :: Value -> ValueImpl
  toValueImpl value = case value of
    Buffer buffer -> Untagged.Union.asOneOf buffer
    String string -> Untagged.Union.asOneOf string

