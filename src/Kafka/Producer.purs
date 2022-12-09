module Kafka.Producer
  ( Producer
  , ProducerConfig
  , producer
  ) where

import Prelude

import Effect as Effect
import Effect.Uncurried as Effect.Uncurried
import Kafka.Kafka as Kafka.Kafka

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L787
foreign import data Producer :: Type

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
