module Kafka.Producer
  ( Message
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

-- | * `topicMessages`
-- |   * a list of topics and for each topic a list of messages
type ProducerBatch =
  { topicMessages :: Array TopicMessages
  }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L753
-- |
-- | Optional
-- | * `topicMessages?: TopicMessages[]`
type ProducerBatchImpl =
  Kafka.FFI.Object
    ()
    ( topicMessages :: Array TopicMessagesImpl
    )

type ProducerConfig =
  {}

-- | https://github.com/tulios/kafkajs/blob/v2.2.3/types/index.d.ts#L98
-- |
-- | Unsupported
-- | * `allowAutoTopicCreation?: boolean`
-- | * `createPartitioner?: ICustomPartitioner`
-- | * `idempotent?: boolean`
-- | * `maxInFlightRequests?: number`
-- | * `metadataMaxAge?: number`
-- | * `retry?: RetryOptions`
-- | * `transactionTimeout?: number`
-- | * `transactionalId?: string`
type ProducerConfigImpl =
  {}

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L729
type ProducerRecord =
  { messages :: Array Message
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
  toProducerConfigImpl x = x

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/src/producer/messageProducer.js#L118
-- |
-- | NOTE logic is very simple so instead of FFI we rewrite in PS
send :: Producer -> ProducerRecord -> Effect.Aff.Aff (Array RecordMetadata)
send producer' x = sendBatch producer'
  { topicMessages: Data.Array.singleton topicMessages
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
    { topicMessages: toTopicMessagesImpl <$> x.topicMessages
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

