module Kafka.FFI.AssignerProtocol
  ( Assignment
  , MemberAssignmentBuffer(..)
  , MemberAssignmentImpl
  , MemberMetadataBuffer(..)
  , MemberMetadataImpl
  , memberAssignmentDecode
  , memberAssignmentEncode
  , memberMetadataDecode
  , memberMetadataEncode
  ) where

import Prelude

import Data.Maybe as Data.Maybe
import Data.Nullable as Data.Nullable
import Foreign.Object as Foreign.Object
import Kafka.FFI as Kafka.FFI
import Node.Buffer as Node.Buffer

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L213
-- |
-- | `type Assignment = { [topic: string]: number[] }`
type Assignment = Foreign.Object.Object (Array Int)

newtype MemberAssignmentBuffer = MemberAssignmentBuffer Node.Buffer.Buffer

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L593
-- |
-- | Required
-- | * `assignment: Assignment`
-- | * `version: number`
-- |
-- | Optional
-- | * `userData: Buffer`
-- |   * see https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/src/consumer/assignerProtocol.js#L43
type MemberAssignmentImpl =
  Kafka.FFI.Object
    ( assignment :: Assignment
    , version :: Int
    )
    ( userData :: Node.Buffer.Buffer
    )

newtype MemberMetadataBuffer = MemberMetadataBuffer Node.Buffer.Buffer

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L587
-- |
-- | Required
-- | * `topics: string[]`
-- | * `version: number`
-- |
-- | Optional
-- | * `userData: Buffer`
-- |   * see https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/src/consumer/assignerProtocol.js#L9
type MemberMetadataImpl =
  Kafka.FFI.Object
    ( topics :: Array String
    , version :: Int
    )
    ( userData :: Node.Buffer.Buffer
    )

foreign import _memberAssignmentDecode ::
  MemberAssignmentBuffer ->
  (Data.Nullable.Nullable MemberAssignmentImpl)

memberAssignmentDecode :: MemberAssignmentBuffer -> Data.Maybe.Maybe MemberAssignmentImpl
memberAssignmentDecode buffer =
  Data.Nullable.toMaybe
    $ _memberAssignmentDecode buffer

foreign import memberAssignmentEncode ::
  MemberAssignmentImpl ->
  MemberAssignmentBuffer

foreign import _memberMetadataDecode ::
  MemberMetadataBuffer ->
  (Data.Nullable.Nullable MemberMetadataImpl)

memberMetadataDecode :: MemberMetadataBuffer -> Data.Maybe.Maybe MemberMetadataImpl
memberMetadataDecode buffer =
  Data.Nullable.toMaybe
    $ _memberMetadataDecode buffer

foreign import memberMetadataEncode ::
  MemberMetadataImpl ->
  MemberMetadataBuffer

