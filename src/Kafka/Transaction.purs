module Kafka.Transaction
  ( Transaction
  , abort
  , commit
  , transaction
  ) where

import Prelude

import Control.Promise as Control.Promise
import Effect.Aff as Effect.Aff
import Effect.Uncurried as Effect.Uncurried
import Kafka.Producer as Kafka.Producer

foreign import data Transaction :: Type

foreign import _abort ::
  Effect.Uncurried.EffectFn1
    Transaction
    (Control.Promise.Promise Unit)

abort :: Transaction -> Effect.Aff.Aff Unit
abort transaction' =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn1 _abort transaction'

foreign import _commit ::
  Effect.Uncurried.EffectFn1
    Transaction
    (Control.Promise.Promise Unit)

commit :: Transaction -> Effect.Aff.Aff Unit
commit transaction' =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn1 _commit transaction'

foreign import _transaction ::
  Effect.Uncurried.EffectFn1
    Kafka.Producer.Producer
    (Control.Promise.Promise Transaction)

transaction ::
  Kafka.Producer.Producer ->
  Effect.Aff.Aff Transaction
transaction producer =
  Control.Promise.toAffE
    $ Effect.Uncurried.runEffectFn1 _transaction producer
