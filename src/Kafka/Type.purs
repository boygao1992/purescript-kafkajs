module Kafka.Type
  ( MessageHeaders
  , MessageHeadersImpl
  , PartitionMetadata
  , PartitionMetadataImpl
  , fromPartitionMetadataImpl
  ) where

import Data.Maybe as Data.Maybe
import Foreign.Object as Foreign.Object
import Kafka.FFI as Kafka.FFI

type MessageHeaders =
  Foreign.Object.Object String

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L148
-- |
-- | ```
-- | export interface IHeaders {
-- |   [key: string]: Buffer | string | (Buffer | string)[] | undefined
-- | }
-- | ```
-- |
-- | NOTE only support `string` for now
type MessageHeadersImpl =
  Foreign.Object.Object String

-- | * `isr`
-- |   * in-sync replicas
-- | * `leader`
-- |   * leader replica
-- | * `offlineReplicas`
-- |   * offline replicas (not in-sync)
-- | * `partitionErrorCode`
-- |   * partition error code, or `0` if there was no error
-- | * `partitionId`
-- |   * partition ID
-- | * `replicas`
-- |   * all replicas (including both in-sync and offline)
type PartitionMetadata =
  { isr :: Array Int
  , leader :: Int
  , offlineReplicas :: Array Int
  , partitionErrorCode :: Int
  , partitionId :: Int
  , replicas :: Array Int
  }

-- | https://github.com/tulios/kafkajs/blob/dcee6971c4a739ebb02d9279f68155e3945c50f7/types/index.d.ts#L139
-- |
-- | Required
-- | * `isr: number[]`
-- | * `leader: number`
-- | * `partitionErrorCode: number`
-- | * `partitionId: number`
-- | * `replicas: number[]`
-- |
-- | Optional
-- | * `offlineReplicas?: number[]`
type PartitionMetadataImpl =
  Kafka.FFI.Object
    ( isr :: Array Int
    , leader :: Int
    , partitionErrorCode :: Int
    , partitionId :: Int
    , replicas :: Array Int
    )
    ( offlineReplicas :: Array Int
    )

fromPartitionMetadataImpl :: PartitionMetadataImpl -> PartitionMetadata
fromPartitionMetadataImpl partitionMetadataImpl =
  x { offlineReplicas = Data.Maybe.fromMaybe [] x.offlineReplicas }
  where
  x = Kafka.FFI.objectToRecord partitionMetadataImpl
