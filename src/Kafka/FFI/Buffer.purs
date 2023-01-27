module Kafka.FFI.Buffer
  ( Buffer(..)
  ) where

import Foreign as Foreign
import Node.Buffer as Node.Buffer
import Untagged.TypeCheck as Untagged.TypeCheck

newtype Buffer = Buffer Node.Buffer.Buffer

instance hasRuntimeTypeBuffer :: Untagged.TypeCheck.HasRuntimeType Buffer where
  hasRuntimeType _ = isBuffer

foreign import isBuffer :: Foreign.Foreign -> Boolean

