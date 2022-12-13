module Kafka.Admin
  ( Admin
  , admin
  , connect
  , createTopics
  , disconnect
  ) where

import Prelude

import Control.Promise as Control.Promise
import Data.Maybe as Data.Maybe
import Effect as Effect
import Effect.Aff as Effect.Aff
import Effect.Uncurried as Effect.Uncurried
import Kafka.FFI as Kafka.FFI
import Kafka.Kafka as Kafka.Kafka

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L430
foreign import data Admin :: Type

type AdminConfig =
  {
  }

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L183
-- |
-- | Unsupported
-- | * `retry?: RetryOptions`
type AdminConfigImpl =
  {
  }

type CreateTopicsOptions =
  { timeout :: Data.Maybe.Maybe Number
  , topics :: Array TopicConfig
  , validateOnly :: Data.Maybe.Maybe Boolean
  , waitForLeaders :: Data.Maybe.Maybe Boolean
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

type TopicConfig =
  { numPartitions :: Data.Maybe.Maybe Int
  , replicationFactor :: Data.Maybe.Maybe Int
  , topic :: String
  }

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
    Kafka.Kafka.Kafka
    AdminConfigImpl
    Admin

admin :: Kafka.Kafka.Kafka -> AdminConfigImpl -> Effect.Effect Admin
admin kafka adminConfigImpl =
  Effect.Uncurried.runEffectFn2 _admin kafka
    $ toAdminConfigImpl adminConfigImpl
  where
  toAdminConfigImpl :: AdminConfig -> AdminConfigImpl
  toAdminConfigImpl x = x

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L431
-- |
-- | `connect(): Promise<void>`
foreign import _connect ::
  Effect.Uncurried.EffectFn1
    Admin
    (Control.Promise.Promise Unit)

connect :: Admin -> Effect.Aff.Aff Unit
connect admin' =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn1 _connect admin'

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L434
-- |
-- | `createTopics(options: { ... }): Promise<boolean>`
foreign import _createTopics ::
  Effect.Uncurried.EffectFn2
    Admin
    CreateTopicsOptionsImpl
    (Control.Promise.Promise Boolean)

createTopics ::
  Admin ->
  CreateTopicsOptions ->
  Effect.Aff.Aff Boolean
createTopics admin' createTopicsOptions =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn2 _createTopics admin'
    $ toCreateTopicsOptionsImpl createTopicsOptions
  where
  toCreateTopicsOptionsImpl :: CreateTopicsOptions -> CreateTopicsOptionsImpl
  toCreateTopicsOptionsImpl x = Kafka.FFI.objectFromRecord
    { timeout: x.timeout
    , topics: toTopicConfigImpl <$> x.topics
    , validateOnly: x.validateOnly
    , waitForLeaders: x.waitForLeaders
    }

  toTopicConfigImpl :: TopicConfig -> TopicConfigImpl
  toTopicConfigImpl x = Kafka.FFI.objectFromRecord x

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L432
-- |
-- | `disconnect(): Promise<void>`
foreign import _disconnect ::
  Effect.Uncurried.EffectFn1
    Admin
    (Control.Promise.Promise Unit)

disconnect :: Admin -> Effect.Aff.Aff Unit
disconnect admin' =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn1 _disconnect admin'
