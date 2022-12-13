module Kafka.Kafka
  ( LogLevel(..)
  , Kafka
  , KafkaConfig
  , KafkaConfigBrokers(..)
  , newKafka
  ) where

import Prelude

import Control.Promise as Control.Promise
import Data.Maybe as Data.Maybe
import Effect as Effect
import Effect.Aff as Effect.Aff
import Effect.Uncurried as Effect.Uncurried
import Kafka.FFI as Kafka.FFI
import Untagged.Union as Untagged.Union

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L17
-- |
-- | * `BrokersFunction = () => string[] | Promise<string[]>`
type BrokerFunctionImpl =
  Effect.Effect (Array String)
    Untagged.Union.|+| Effect.Effect (Control.Promise.Promise (Array String))

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L9
foreign import data Kafka :: Type

-- | * `brokers`
-- | * `clientId`
-- |   * A logical identifier of an application to be included in
-- |     server-side request logging.
-- |   * see [Client Id](https://kafka.js.org/docs/configuration#client-id)
type KafkaConfig =
  { brokers :: KafkaConfigBrokers
  , clientId :: Data.Maybe.Maybe String
  , logLevel :: Data.Maybe.Maybe LogLevel
  }

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

data KafkaConfigBrokers
  = KafkaConfigBrokersAsync (Effect.Aff.Aff (Array String))
  | KafkaConfigBrokersPure (Array String)
  | KafkaConfigBrokersSync (Effect.Effect (Array String))

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L51
-- |
-- | `brokers: string[] | BrokersFunction`
type KafkaConfigBrokersImpl =
  Array String
    Untagged.Union.|+| BrokerFunctionImpl

data LogLevel
  = LogLevelNothing
  | LogLevelError
  | LogLevelWarn
  | LogLevelInfo
  | LogLevelDebug

-- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L513
type LogLevelImpl = Int

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L10
-- |
-- | `constructor(config: KafkaConfig)`
foreign import _newKafka ::
  Effect.Uncurried.EffectFn1
    KafkaConfigImpl
    Kafka

newKafka :: KafkaConfig -> Effect.Effect Kafka
newKafka config =
  Effect.Uncurried.runEffectFn1 _newKafka
    $ toKafkaConfigImpl
    $ config
  where
  -- | https://github.com/tulios/kafkajs/blob/d8fd93e7ce8e4675e3bb9b13d7a1e55a1e0f6bbf/types/index.d.ts#L513
  -- |
  -- | ```
  -- | export enum logLevel {
  -- |   NOTHING = 0,
  -- |   ERROR = 1,
  -- |   WARN = 2,
  -- |   INFO = 4,
  -- |   DEBUG = 5,
  -- | }
  -- | ```
  toLogLevelImpl :: LogLevel -> LogLevelImpl
  toLogLevelImpl = case _ of
    LogLevelNothing -> 0
    LogLevelError -> 1
    LogLevelWarn -> 2
    LogLevelInfo -> 3
    LogLevelDebug -> 4

  toKafkaConfigImpl :: KafkaConfig -> KafkaConfigImpl
  toKafkaConfigImpl x = Kafka.FFI.objectFromRecord
    { brokers: case x.brokers of
        KafkaConfigBrokersAsync aff -> Untagged.Union.asOneOf $ Control.Promise.fromAff aff
        KafkaConfigBrokersPure list -> Untagged.Union.asOneOf list
        KafkaConfigBrokersSync effect -> Untagged.Union.asOneOf effect
    , clientId: x.clientId
    , logLevel: toLogLevelImpl <$> x.logLevel
    }

