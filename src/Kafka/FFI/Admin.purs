module Kafka.FFI.Admin
  ( Admin
  , AdminConfigImpl
  , CreateTopicsOptionsImpl
  , TopicConfigImpl
  , _admin
  , _connect
  , _createTopics
  , _disconnect
  ) where

import Prelude

import Control.Promise as Control.Promise
import Effect.Uncurried as Effect.Uncurried
import Kafka.FFI as Kafka.FFI
import Kafka.FFI.Kafka as Kafka.FFI.Kafka

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L430
foreign import data Admin :: Type

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L183
-- |
-- | Unsupported
-- | * `retry?: RetryOptions`
type AdminConfigImpl =
  {
  }

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L434
-- |
-- | Required
-- | * `topics: ITopicConfig[]`
-- |
-- | Optional
-- | * `timeout?: number`
-- | * `validateOnly?: boolean`
-- | * `waitForLeaders?: boolean`
type CreateTopicsOptionsImpl =
  Kafka.FFI.Object
    (topics :: Array TopicConfigImpl)
    ( timeout :: Number
    , validateOnly :: Boolean
    , waitForLeaders :: Boolean
    )

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L187
-- |
-- | Required
-- | * `topic: string`
-- |
-- | Optional
-- | * `numPartitions?: number`
-- | * `replicationFactor?: number`
-- |
-- | Unsupported
-- | * `configEntries?: object[]`
-- | * `replicaAssignment?: object[]`
type TopicConfigImpl =
  Kafka.FFI.Object
    (topic :: String)
    ( numPartitions :: Int
    , replicationFactor :: Int
    )

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L13
-- |
-- | `admin(config?: AdminConfig): Admin`
foreign import _admin ::
  Effect.Uncurried.EffectFn2
    Kafka.FFI.Kafka.Kafka
    AdminConfigImpl
    Admin

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L431
-- |
-- | `connect(): Promise<void>`
foreign import _connect ::
  Effect.Uncurried.EffectFn1
    Admin
    (Control.Promise.Promise Unit)

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L434
-- |
-- | `createTopics(options: { ... }): Promise<boolean>`
foreign import _createTopics ::
  Effect.Uncurried.EffectFn2
    Admin
    CreateTopicsOptionsImpl
    (Control.Promise.Promise Boolean)

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L432
-- |
-- | `disconnect(): Promise<void>`
foreign import _disconnect ::
  Effect.Uncurried.EffectFn1
    Admin
    (Control.Promise.Promise Unit)
