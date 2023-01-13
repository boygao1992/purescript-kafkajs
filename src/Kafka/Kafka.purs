module Kafka.Kafka
  ( KafkaConfig
  , KafkaConfigBrokers(..)
  , LogLevel(..)
  , newKafka
  ) where

import Prelude

import Control.Promise as Control.Promise
import Data.Maybe as Data.Maybe
import Effect as Effect
import Effect.Aff as Effect.Aff
import Effect.Uncurried as Effect.Uncurried
import Kafka.FFI as Kafka.FFI
import Kafka.FFI.Kafka as Kafka.FFI.Kafka
import Untagged.Union as Untagged.Union

-- | * `brokers`
-- |   * A list of seed broker URLs to fetch metadata of the whole broker cluster
-- |   * see [Broker discovery](https://kafka.js.org/docs/configuration#broker-discovery) if you want to dynamically fetch the list through an `Effect`/`Aff`
-- | * `clientId`
-- |   * A logical identifier of an application to be included in
-- |     server-side request logging.
-- |   * see [Client Id](https://kafka.js.org/docs/configuration#client-id)
-- | * `logLevel`
-- |   * The log level of `kafkajs` built-in `STDOUT` logger
-- |   * see [Logging](https://kafka.js.org/docs/configuration#logging)
type KafkaConfig =
  { brokers :: KafkaConfigBrokers
  , clientId :: Data.Maybe.Maybe String
  , logLevel :: Data.Maybe.Maybe LogLevel
  }

data KafkaConfigBrokers
  = KafkaConfigBrokersAsync (Effect.Aff.Aff (Array String))
  | KafkaConfigBrokersPure (Array String)
  | KafkaConfigBrokersSync (Effect.Effect (Array String))

data LogLevel
  = LogLevelNothing
  | LogLevelError
  | LogLevelWarn
  | LogLevelInfo
  | LogLevelDebug

newKafka :: KafkaConfig -> Effect.Effect Kafka.FFI.Kafka.Kafka
newKafka config =
  Effect.Uncurried.runEffectFn1 Kafka.FFI.Kafka._newKafka
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
  toLogLevelImpl :: LogLevel -> Kafka.FFI.Kafka.LogLevelImpl
  toLogLevelImpl = case _ of
    LogLevelNothing -> 0
    LogLevelError -> 1
    LogLevelWarn -> 2
    LogLevelInfo -> 3
    LogLevelDebug -> 4

  toKafkaConfigImpl :: KafkaConfig -> Kafka.FFI.Kafka.KafkaConfigImpl
  toKafkaConfigImpl x = Kafka.FFI.objectFromRecord
    { brokers: case x.brokers of
        KafkaConfigBrokersAsync aff -> Untagged.Union.asOneOf $ Control.Promise.fromAff aff
        KafkaConfigBrokersPure list -> Untagged.Union.asOneOf list
        KafkaConfigBrokersSync effect -> Untagged.Union.asOneOf effect
    , clientId: x.clientId
    , logLevel: toLogLevelImpl <$> x.logLevel
    }

