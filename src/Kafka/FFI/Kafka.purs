module Kafka.FFI.Kafka
  ( BrokerFunctionImpl
  , Kafka
  , KafkaConfigBrokersImpl
  , KafkaConfigImpl
  , LogLevelImpl
  , _newKafka
  ) where

import Control.Promise as Control.Promise
import Effect as Effect
import Effect.Uncurried as Effect.Uncurried
import Kafka.FFI as Kafka.FFI
import Untagged.Union as Untagged.Union

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L17
-- |
-- | * `BrokersFunction = () => string[] | Promise<string[]>`
type BrokerFunctionImpl =
  Effect.Effect (Array String)
    Untagged.Union.|+| Effect.Effect (Control.Promise.Promise (Array String))

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L50
-- |
-- | Required
-- | * `brokers: string[] | BrokersFunction`
-- |
-- | Optional
-- | * `clientId?: string`
-- | * `logLevel?: logLevel`
-- |
-- | Unsupported
-- | * `ssl?: tls.ConnectionOptions | boolean`
-- | * `sasl?: SASLOptions`
-- | * `clientId?: string`
-- | * `connectionTimeout?: number`
-- | * `authenticationTimeout?: number`
-- | * `reauthenticationThreshold?: number`
-- | * `requestTimeout?: number`
-- | * `enforceRequestTimeout?: boolean`
-- | * `retry?: RetryOptions`
-- | * `socketFactory?: ISocketFactory`
-- | * `logCreator?: logCreator`
type KafkaConfigImpl =
  Kafka.FFI.Object
    ( brokers :: KafkaConfigBrokersImpl
    )
    ( clientId :: String
    , logLevel :: LogLevelImpl
    )

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L51
-- |
-- | `brokers: string[] | BrokersFunction`
type KafkaConfigBrokersImpl =
  Array String
    Untagged.Union.|+| BrokerFunctionImpl

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L513
type LogLevelImpl = Int

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L9
foreign import data Kafka :: Type

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L10
-- |
-- | `constructor(config: KafkaConfig)`
foreign import _newKafka ::
  Effect.Uncurried.EffectFn1
    KafkaConfigImpl
    Kafka
