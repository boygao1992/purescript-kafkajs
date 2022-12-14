module Kafka.FFI
  ( class RemoveKeysRL
  , removeKeysRL
  , Object
  , objectFromRecord
  , objectToRecord
  ) where

import Prelude

import Control.Monad.ST as Control.Monad.ST
import Foreign.Object as Foreign.Object
import Foreign.Object.ST as Foreign.Object.ST
import Option as Option
import Prim.RowList as Prim.RowList
import Type.Prelude as Type.Prelude
import Unsafe.Coerce as Unsafe.Coerce

-- | A version of `Option.Record _ _` that has the same underlying
-- | representation as `Option.Option _` which can be used directly
-- | in FFI definitions to represent JS Object with fields that may
-- | or may not exist.
-- |
-- | We canot use `Option.Record _ _` directly in FFI definitions
-- | because its underlying representation is not a plain JS object.
newtype Object (required :: Row Type) (optional :: Row Type) =
  Object
    (Foreign.Object.Object (forall a. a))

objectFromOptionRecord ::
  forall optional required.
  Option.Record required optional ->
  Object required optional
objectFromOptionRecord optionRecord =
  Object (Foreign.Object.union underlying.required underlying.optional)
  where
  underlying ::
    { required :: Foreign.Object.Object (forall a. a)
    , optional :: Foreign.Object.Object (forall a. a)
    }
  underlying = unwrap optionRecord

  unwrap ::
    Option.Record required optional ->
    { required :: Foreign.Object.Object (forall a. a)
    , optional :: Foreign.Object.Object (forall a. a)
    }
  unwrap = Unsafe.Coerce.unsafeCoerce

objectFromRecord ::
  forall optional required record.
  Option.FromRecord record required optional =>
  Prim.Record record ->
  Object required optional
objectFromRecord = objectFromOptionRecord <<< Option.recordFromRecord

objectToOptionRecord ::
  forall optional optionalRowList required requiredRowList.
  Prim.RowList.RowToList optional optionalRowList =>
  Prim.RowList.RowToList required requiredRowList =>
  RemoveKeysRL optionalRowList =>
  RemoveKeysRL requiredRowList =>
  Object required optional ->
  Option.Record required optional
objectToOptionRecord (Object copy) = wrap underlying
  where
  underlying ::
    { required :: Foreign.Object.Object (forall a. a)
    , optional :: Foreign.Object.Object (forall a. a)
    }
  underlying =
    -- NOTE `Option.recordToRecord` uses `Record.Builder.disjointUnion`
    -- which is left-biased so we need to remove the optional keys from
    -- the required `copy`, otherwise fields from the original `copy`
    -- will override the result of `optionalBuilder`, causing some
    -- optional fields not properly wrapped in `Maybe _`.
    -- See https://github.com/joneshf/purescript-option/blob/8506cbf1fd5d5465a9dc990dfe6f2960ae51c1ab/src/Option.purs#L2317
    --
    -- To make the underlying representation more accurate, we remove
    -- required keys from the optional `copy` too.
    { required: removeKeys (Type.Prelude.Proxy :: _ optionalRowList) copy
    , optional: removeKeys (Type.Prelude.Proxy :: _ requiredRowList) copy
    }

  wrap ::
    { required :: Foreign.Object.Object (forall a. a)
    , optional :: Foreign.Object.Object (forall a. a)
    } ->
    Option.Record required optional
  wrap = Unsafe.Coerce.unsafeCoerce

objectToRecord ::
  forall optional optionalRowList record required requiredRowList.
  Prim.RowList.RowToList optional optionalRowList =>
  Prim.RowList.RowToList required requiredRowList =>
  RemoveKeysRL optionalRowList =>
  RemoveKeysRL requiredRowList =>
  Option.ToRecord required optional record =>
  Object required optional ->
  Prim.Record record
objectToRecord = Option.recordToRecord <<< objectToOptionRecord

-- | Remove all keys in a `Row _` from a `Foreign.Object.Object _`
removeKeys ::
  forall a rowList.
  RemoveKeysRL rowList =>
  Type.Prelude.Proxy rowList ->
  Foreign.Object.Object a ->
  Foreign.Object.Object a
removeKeys rowList object = Foreign.Object.runST do
  copy <- Foreign.Object.thawST object
  removeKeysRL rowList copy

class RemoveKeysRL (rowList :: Prim.RowList.RowList Type) where
  removeKeysRL ::
    forall a r.
    Type.Prelude.Proxy rowList ->
    Foreign.Object.ST.STObject r a ->
    Control.Monad.ST.ST r (Foreign.Object.ST.STObject r a)

instance removeKeyRLsNil :: RemoveKeysRL Prim.RowList.Nil where
  removeKeysRL _ stObject = pure stObject

instance removeKeysRLCons ::
  ( Type.Prelude.IsSymbol key
  , RemoveKeysRL rest
  ) =>
  RemoveKeysRL (Prim.RowList.Cons key value rest) where
  removeKeysRL _ stObject = do
    stObjectRest <- Foreign.Object.ST.delete key stObject
    removeKeysRL (Type.Prelude.Proxy :: _ rest) stObjectRest
    where
    key :: String
    key = Type.Prelude.reflectSymbol (Type.Prelude.Proxy :: _ key)
