module Kafka.Type
  ( MessageHeaders
  , MessageHeadersImpl
  ) where

import Foreign.Object as Foreign.Object

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
