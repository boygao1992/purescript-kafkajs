module Kafka.Admin
  ( Admin
  , admin
  ) where

import Prelude

import Effect as Effect
import Effect.Uncurried as Effect.Uncurried
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

