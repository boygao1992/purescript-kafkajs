module Kafka.FFI.Transaction
  ( Offsets
  , PartitionOffset
  , TopicOffsets
  , Transaction
  , _abort
  , _commit
  , _sendOffsets
  , _transaction
  ) where

import Prelude

import Control.Promise as Control.Promise
import Effect.Uncurried as Effect.Uncurried
import Kafka.FFI.Producer as Kafka.FFI.Producer

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

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L822
-- |
-- | `commit(): Promise<void>`
foreign import _commit ::
  Effect.Uncurried.EffectFn1
    Transaction
    (Control.Promise.Promise Unit)

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L821
-- |
-- | `sendOffsets(offsets: Offsets & { consumerGroupId: string }): Promise<void>`
foreign import _sendOffsets ::
  Effect.Uncurried.EffectFn2
    Transaction
    Offsets
    (Control.Promise.Promise Unit)

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L816
-- |
-- | `transaction(): Promise<Transaction>`
foreign import _transaction ::
  Effect.Uncurried.EffectFn1
    Kafka.FFI.Producer.Producer
    (Control.Promise.Promise Transaction)
