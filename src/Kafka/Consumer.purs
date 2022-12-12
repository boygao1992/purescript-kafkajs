module Kafka.Consumer
  ( Consumer
  , ConsumerConfig
  , Topic(..)
  , consumer
  , subscribe
  ) where

import Prelude

import Control.Promise as Control.Promise
import Data.Maybe as Data.Maybe
import Data.String.Regex as Data.String.Regex
import Effect as Effect
import Effect.Aff as Effect.Aff
import Effect.Uncurried as Effect.Uncurried
import Kafka.FFI as Kafka.FFI
import Kafka.Kafka as Kafka.Kafka
import Untagged.Union as Untagged.Union

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

type ConsumerSubscribeTopics =
  { fromBeginning :: Data.Maybe.Maybe Boolean
  , topics :: Array Topic
  }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1030
-- |
-- | Required
-- | * `topics: (string | RegExp)[]`
-- |
-- | Optional
-- | * `fromBeginning?: boolean`
-- |   * default to `false`, see https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/src/consumer/index.js#L134
type ConsumerSubscribeTopicsImpl =
  Kafka.FFI.Object
    ( topics :: Array ConsumerSubscribeTopicImpl
    )
    ( fromBeginning :: Boolean
    )

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1030
-- |
-- | `(string | RegExp)`
type ConsumerSubscribeTopicImpl =
  String
    Untagged.Union.|+| Data.String.Regex.Regex

data Topic
  = TopicName String
  | TopicRegex Data.String.Regex.Regex

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

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1035
-- |
-- | `subscribe(subscription: ConsumerSubscribeTopics | ConsumerSubscribeTopic): Promise<void>`
-- |  * NOTE `ConsumerSubscribeTopic` is deprecated, see https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L1027
foreign import _subscribe ::
  Effect.Uncurried.EffectFn2
    Consumer
    ConsumerSubscribeTopicsImpl
    (Control.Promise.Promise Unit)

subscribe ::
  Consumer ->
  ConsumerSubscribeTopics ->
  Effect.Aff.Aff Unit
subscribe consumer' consumerSubscribeTopics =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn2 _subscribe consumer'
    $ toConsumerSubscribeTopicsImpl consumerSubscribeTopics
  where
  toConsumerSubscribeTopicsImpl ::
    ConsumerSubscribeTopics ->
    ConsumerSubscribeTopicsImpl
  toConsumerSubscribeTopicsImpl x = Kafka.FFI.objectFromRecord
    { fromBeginning: x.fromBeginning
    , topics: toConsumerSubscribeTopicImpl <$> x.topics
    }

  toConsumerSubscribeTopicImpl ::
    Topic ->
    ConsumerSubscribeTopicImpl
  toConsumerSubscribeTopicImpl topic = case topic of
    TopicName string -> Untagged.Union.asOneOf string
    TopicRegex regex -> Untagged.Union.asOneOf regex
