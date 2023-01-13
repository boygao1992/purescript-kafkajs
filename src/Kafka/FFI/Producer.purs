module Kafka.FFI.Producer
  ( AcksImpl
  , CompressionTypeImpl
  , MessageImpl
  , Producer
  , ProducerBatchImpl
  , ProducerConfigImpl
  , RecordMetadataImpl
  , TopicMessagesImpl
  , ValueImpl
  , _connect
  , _disconnect
  , _producer
  , _sendBatch
  ) where

import Prelude

import Control.Promise as Control.Promise
import Data.Nullable as Data.Nullable
import Effect.Uncurried as Effect.Uncurried
import Kafka.FFI as Kafka.FFI
import Kafka.FFI.Kafka as Kafka.FFI.Kafka
import Kafka.Type as Kafka.Type
import Node.Buffer as Node.Buffer
import Untagged.Union as Untagged.Union

type AcksImpl = Int

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1116
-- | `CompressionTypes`
-- |
-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/src/protocol/message/compression/index.js#L5
-- | `Compression.Types`
type CompressionTypeImpl = Int

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

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L748
-- |
-- | * `messages: Message[]`
-- | * `topic: string`
type TopicMessagesImpl =
  { messages :: Array MessageImpl
  , topic :: String
  }

type ValueImpl =
  Node.Buffer.Buffer
    Untagged.Union.|+| String

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L787
foreign import data Producer :: Type

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L788
-- |
-- | `connect(): Promise<void>`
foreign import _connect ::
  Effect.Uncurried.EffectFn1
    Producer
    (Control.Promise.Promise Unit)

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L789
-- |
-- | `disconnect(): Promise<void>`
foreign import _disconnect ::
  Effect.Uncurried.EffectFn1
    Producer
    (Control.Promise.Promise Unit)

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L11
-- |
-- | `producer(config?: ProducerConfig): Producer`
foreign import _producer ::
  Effect.Uncurried.EffectFn2
    Kafka.FFI.Kafka.Kafka
    ProducerConfigImpl
    Producer

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L776
-- |
-- | `sendBatch(batch: ProducerBatch): Promise<RecordMetadata[]>`
foreign import _sendBatch ::
  Effect.Uncurried.EffectFn2
    Producer
    ProducerBatchImpl
    (Control.Promise.Promise (Array RecordMetadataImpl))
