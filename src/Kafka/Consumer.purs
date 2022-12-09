module Kafka.Consumer
  ( Consumer
  , ConsumerConfig
  , consumer
  ) where

import Prelude

import Effect as Effect
import Effect.Uncurried as Effect.Uncurried
import Kafka.Kafka as Kafka.Kafka

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

