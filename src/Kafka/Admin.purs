module Kafka.Admin
  ( AdminConfig
  , CreateTopicsOptions
  , TopicConfig
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
import Kafka.FFI.Admin as Kafka.FFI.Admin
import Kafka.FFI.Kafka as Kafka.FFI.Kafka

type AdminConfig =
  {
  }

type CreateTopicsOptions =
  { timeout :: Data.Maybe.Maybe Number
  , topics :: Array TopicConfig
  , validateOnly :: Data.Maybe.Maybe Boolean
  , waitForLeaders :: Data.Maybe.Maybe Boolean
  }

type TopicConfig =
  { numPartitions :: Data.Maybe.Maybe Int
  , replicationFactor :: Data.Maybe.Maybe Int
  , topic :: String
  }

admin :: Kafka.FFI.Kafka.Kafka -> Kafka.FFI.Admin.AdminConfigImpl -> Effect.Effect Kafka.FFI.Admin.Admin
admin kafka adminConfigImpl =
  Effect.Uncurried.runEffectFn2 Kafka.FFI.Admin._admin kafka
    $ toAdminConfigImpl adminConfigImpl
  where
  toAdminConfigImpl :: AdminConfig -> Kafka.FFI.Admin.AdminConfigImpl
  toAdminConfigImpl x = x

connect :: Kafka.FFI.Admin.Admin -> Effect.Aff.Aff Unit
connect admin' =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn1 Kafka.FFI.Admin._connect admin'

createTopics ::
  Kafka.FFI.Admin.Admin ->
  CreateTopicsOptions ->
  Effect.Aff.Aff Boolean
createTopics admin' createTopicsOptions =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn2 Kafka.FFI.Admin._createTopics admin'
    $ toCreateTopicsOptionsImpl createTopicsOptions
  where
  toCreateTopicsOptionsImpl :: CreateTopicsOptions -> Kafka.FFI.Admin.CreateTopicsOptionsImpl
  toCreateTopicsOptionsImpl x = Kafka.FFI.objectFromRecord
    { timeout: x.timeout
    , topics: toTopicConfigImpl <$> x.topics
    , validateOnly: x.validateOnly
    , waitForLeaders: x.waitForLeaders
    }

  toTopicConfigImpl :: TopicConfig -> Kafka.FFI.Admin.TopicConfigImpl
  toTopicConfigImpl x = Kafka.FFI.objectFromRecord x

disconnect :: Kafka.FFI.Admin.Admin -> Effect.Aff.Aff Unit
disconnect admin' =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn1 Kafka.FFI.Admin._disconnect admin'
