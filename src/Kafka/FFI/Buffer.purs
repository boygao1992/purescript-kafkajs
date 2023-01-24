module Kafka.FFI.Buffer
  ( Buffer(..)
  ) where

import Data.Function.Uncurried as Function.Uncurried
import Foreign as Foreign
import Node.Buffer as Node.Buffer
import Untagged.TypeCheck as Untagged.TypeCheck

newtype Buffer = Buffer Node.Buffer.Buffer

instance hasRuntimeTypeBuffer :: Untagged.TypeCheck.HasRuntimeType Buffer where
  hasRuntimeType _ = isBuffer

foreign import _isBuffer ::
  Function.Uncurried.Fn1
    Foreign.Foreign
    Boolean

isBuffer :: Foreign.Foreign -> Boolean
isBuffer foreign' = Function.Uncurried.runFn1 _isBuffer foreign'
