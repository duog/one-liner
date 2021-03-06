-----------------------------------------------------------------------------
-- |
-- Module      :  Generics.OneLiner.Internal
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  sjoerd@w3future.com
-- Stability   :  experimental
-- Portability :  non-portable
--
-----------------------------------------------------------------------------
{-# LANGUAGE
    GADTs
  , DataKinds
  , EmptyCase
  , PolyKinds
  , RankNTypes
  , LambdaCase
  , TypeFamilies
  , TypeOperators
  , ConstraintKinds
  , FlexibleContexts
  , ScopedTypeVariables
  , UndecidableInstances
  #-}
module Generics.OneLiner.Internal where

import GHC.Generics
import GHC.Types (Constraint)
import Control.Applicative
import Data.Bifunctor.Clown
import Data.Bifunctor.Joker
import Data.Functor.Contravariant.Divisible
import Data.Proxy
import Data.Profunctor
import Data.Tagged


class CtorIndex (t :: * -> *) where
  ctorIndex' :: t x -> Int
  ctorIndex' _ = 0
  ctorCount :: proxy t -> Int
  ctorCount _ = 1

instance CtorIndex V1 where
  ctorCount _ = 0

instance (CtorIndex f, CtorIndex g) => CtorIndex (f :+: g) where
  ctorIndex' (L1 l) = ctorIndex' l
  ctorIndex' (R1 r) = ctorCount (Proxy :: Proxy f) + ctorIndex' r
  ctorCount _ = ctorCount (Proxy :: Proxy f) + ctorCount (Proxy :: Proxy g)

instance CtorIndex f => CtorIndex (M1 i t f) where
  ctorIndex' = ctorIndex' . unM1
  ctorCount _ = ctorCount (Proxy :: Proxy f)

instance CtorIndex U1
instance CtorIndex (K1 i a)
instance CtorIndex (f :*: g)
instance CtorIndex (f :.: g)
instance CtorIndex Par1
instance CtorIndex (Rec1 f)


type family Constraints' (t :: * -> *) (c :: * -> Constraint) :: Constraint
type instance Constraints' V1 c = ()
type instance Constraints' U1 c = ()
type instance Constraints' (f :+: g) c = (Constraints' f c, Constraints' g c)
type instance Constraints' (f :*: g) c = (Constraints' f c, Constraints' g c)
type instance Constraints' (K1 i a) c = c a
type instance Constraints' (M1 i t f) c = Constraints' f c

class CtorIndex t => ADT' (t :: * -> *) where
  generic' :: (Constraints' t c, GenericProfunctor p)
    => for c -> (forall s. c s => p s s) -> p (t x) (t x)

class ADT' t => ADTNonEmpty' (t :: * -> *) where
  nonEmpty' :: (Constraints' t c, GenericNonEmptyProfunctor p)
    => for c -> (forall s. c s => p s s) -> p (t x) (t x)

class ADTNonEmpty' t => ADTRecord' (t :: * -> *) where
  record' :: (Constraints' t c, GenericRecordProfunctor p)
    => for c -> (forall s. c s => p s s) -> p (t x) (t x)

instance ADT' V1 where generic' _ _ = zero
instance ADT' U1 where generic' _ _ = unit
instance (ADT' f, ADT' g) => ADT' (f :+: g) where generic' for f = plus (generic' for f) (generic' for f)
instance (ADT' f, ADT' g) => ADT' (f :*: g) where generic' for f = mult (generic' for f) (generic' for f)
instance ADT' (K1 i v) where generic' _ = dimap unK1 K1
instance ADT' f => ADT' (M1 i t f) where generic' for f = dimap unM1 M1 (generic' for f)

instance ADTNonEmpty' U1 where nonEmpty' _ _ = unit
instance (ADTNonEmpty' f, ADTNonEmpty' g) => ADTNonEmpty' (f :+: g) where nonEmpty' for f = plus (nonEmpty' for f) (nonEmpty' for f)
instance (ADTNonEmpty' f, ADTNonEmpty' g) => ADTNonEmpty' (f :*: g) where nonEmpty' for f = mult (nonEmpty' for f) (nonEmpty' for f)
instance ADTNonEmpty' (K1 i v) where nonEmpty' _ = dimap unK1 K1
instance ADTNonEmpty' f => ADTNonEmpty' (M1 i t f) where nonEmpty' for f = dimap unM1 M1 (nonEmpty' for f)

instance ADTRecord' U1 where record' _ _ = unit
instance (ADTRecord' f, ADTRecord' g) => ADTRecord' (f :*: g) where record' for f = mult (record' for f) (record' for f)
instance ADTRecord' (K1 i v) where record' _ = dimap unK1 K1
instance ADTRecord' f => ADTRecord' (M1 i t f) where record' for f = dimap unM1 M1 (record' for f)


type family Constraints1' (t :: * -> *) (c :: (* -> *) -> Constraint) :: Constraint
type instance Constraints1' V1 c = ()
type instance Constraints1' U1 c = ()
type instance Constraints1' (f :+: g) c = (Constraints1' f c, Constraints1' g c)
type instance Constraints1' (f :*: g) c = (Constraints1' f c, Constraints1' g c)
type instance Constraints1' (f :.: g) c = (Constraints1' f c, Constraints1' g c)
type instance Constraints1' Par1 c = ()
type instance Constraints1' (Rec1 f) c = c f
type instance Constraints1' (M1 i t f) c = Constraints1' f c

class CtorIndex t => ADT1' (t :: * -> *) where
  generic1' :: (Constraints1' t c, GenericProfunctor p)
    => for c -> (forall d e s. c s => p d e -> p (s d) (s e)) -> p a b -> p (t a) (t b)

class ADT1' t => ADTNonEmpty1' (t :: * -> *) where
  nonEmpty1' :: (Constraints1' t c, GenericNonEmptyProfunctor p)
    => for c -> (forall d e s. c s => p d e -> p (s d) (s e)) -> p a b -> p (t a) (t b)

class ADTNonEmpty1' t => ADTRecord1' (t :: * -> *) where
  record1' :: (Constraints1' t c, GenericRecordProfunctor p)
    => for c -> (forall d e s. c s => p d e -> p (s d) (s e)) -> p a b -> p (t a) (t b)

instance ADT1' V1 where generic1' _ _ _ = zero
instance ADT1' U1 where generic1' _ _ _ = unit
instance (ADT1' f, ADT1' g) => ADT1' (f :+: g) where generic1' for f p = plus (generic1' for f p) (generic1' for f p)
instance (ADT1' f, ADT1' g) => ADT1' (f :*: g) where generic1' for f p = mult (generic1' for f p) (generic1' for f p)
instance (ADT1' f, ADT1' g) => ADT1' (f :.: g) where generic1' for f p = dimap unComp1 Comp1 $ generic1' for f $ generic1' for f p
instance ADT1' Par1 where generic1' _ _ = dimap unPar1 Par1
instance ADT1' (Rec1 f) where generic1' _ f p = dimap unRec1 Rec1 (f p)
instance ADT1' f => ADT1' (M1 i t f) where generic1' for f p = dimap unM1 M1 (generic1' for f p)

instance ADTNonEmpty1' U1 where nonEmpty1' _ _ _ = unit
instance (ADTNonEmpty1' f, ADTNonEmpty1' g) => ADTNonEmpty1' (f :+: g) where nonEmpty1' for f p = plus (nonEmpty1' for f p) (nonEmpty1' for f p)
instance (ADTNonEmpty1' f, ADTNonEmpty1' g) => ADTNonEmpty1' (f :*: g) where nonEmpty1' for f p = mult (nonEmpty1' for f p) (nonEmpty1' for f p)
instance (ADTNonEmpty1' f, ADTNonEmpty1' g) => ADTNonEmpty1' (f :.: g) where nonEmpty1' for f p = dimap unComp1 Comp1 $ nonEmpty1' for f $ nonEmpty1' for f p
instance ADTNonEmpty1' Par1 where nonEmpty1' _ _ = dimap unPar1 Par1
instance ADTNonEmpty1' (Rec1 f) where nonEmpty1' _ f p = dimap unRec1 Rec1 (f p)
instance ADTNonEmpty1' f => ADTNonEmpty1' (M1 i t f) where nonEmpty1' for f p = dimap unM1 M1 (nonEmpty1' for f p)

instance ADTRecord1' U1 where record1' _ _ _ = unit
instance (ADTRecord1' f, ADTRecord1' g) => ADTRecord1' (f :*: g) where record1' for f p = mult (record1' for f p) (record1' for f p)
instance (ADTRecord1' f, ADTRecord1' g) => ADTRecord1' (f :.: g) where record1' for f p = dimap unComp1 Comp1 $ record1' for f $ record1' for f p
instance ADTRecord1' Par1 where record1' _ _ = dimap unPar1 Par1
instance ADTRecord1' (Rec1 f) where record1' _ f p = dimap unRec1 Rec1 (f p)
instance ADTRecord1' f => ADTRecord1' (M1 i t f) where record1' for f p = dimap unM1 M1 (record1' for f p)


absurd :: V1 a -> b
absurd = \case {}

class Profunctor p => GenericRecordProfunctor p where
  unit :: p (U1 a) (U1 a')
  mult :: p (f a) (f' a') -> p (g a) (g' a') -> p ((f :*: g) a) ((f' :*: g') a')

class GenericRecordProfunctor p => GenericNonEmptyProfunctor p where
  plus :: p (f a) (f' a') -> p (g a) (g' a') -> p ((f :+: g) a) ((f' :+: g') a')

class GenericNonEmptyProfunctor p => GenericProfunctor p where
  zero :: p (V1 a) (V1 a')

instance GenericRecordProfunctor (->) where
  unit _ = U1
  mult f g (l :*: r) = f l :*: g r
instance GenericNonEmptyProfunctor (->) where
  plus f _ (L1 l) = L1 (f l)
  plus _ g (R1 l) = R1 (g l)
instance GenericProfunctor (->) where
  zero = absurd


instance GenericRecordProfunctor Tagged where
  unit = Tagged U1
  mult (Tagged l) (Tagged r) = Tagged $ l :*: r


instance Applicative f => GenericRecordProfunctor (Star f) where
  unit = Star $ \_ -> pure U1
  mult (Star f) (Star g) = Star $ \(l :*: r) -> (:*:) <$> f l <*> g r
instance Applicative f => GenericNonEmptyProfunctor (Star f) where
  plus (Star f) (Star g) = Star $ \case
    L1 l -> L1 <$> f l
    R1 r -> R1 <$> g r
instance Applicative f => GenericProfunctor (Star f) where
  zero = Star absurd


instance Functor f => GenericRecordProfunctor (Costar f) where
  unit = Costar $ const U1
  mult (Costar f) (Costar g) = Costar $ \lr -> f ((\(l :*: _) -> l) <$> lr) :*: g ((\(_ :*: r) -> r) <$> lr)


instance Applicative f => GenericRecordProfunctor (Joker f) where
  unit = Joker $ pure U1
  mult (Joker l) (Joker r) = Joker $ (:*:) <$> l <*> r
instance Alternative f => GenericNonEmptyProfunctor (Joker f) where
  plus (Joker l) (Joker r) = Joker $ L1 <$> l <|> R1 <$> r
instance Alternative f => GenericProfunctor (Joker f) where
  zero = Joker empty


instance Divisible f => GenericRecordProfunctor (Clown f) where
  unit = Clown conquer
  mult (Clown f) (Clown g) = Clown $ divide (\(l :*: r) -> (l, r)) f g
instance Decidable f => GenericNonEmptyProfunctor (Clown f) where
  plus (Clown f) (Clown g) = Clown $ choose h f g where
    h (L1 l) = Left l
    h (R1 r) = Right r
instance Decidable f => GenericProfunctor (Clown f) where
  zero = Clown $ lose (\v -> v `seq` undefined)


record :: (ADTRecord t, Constraints t c, GenericRecordProfunctor p)
       => for c -> (forall s. c s => p s s) -> p t t
record for f = dimap from to $ record' for f

record1 :: (ADTRecord1 t, Constraints1 t c, GenericRecordProfunctor p)
        => for c -> (forall d e s. c s => p d e -> p (s d) (s e)) -> p a b -> p (t a) (t b)
record1 for f p = dimap from1 to1 $ record1' for f p

nonEmpty :: (ADTNonEmpty t, Constraints t c, GenericNonEmptyProfunctor p)
         => for c -> (forall s. c s => p s s) -> p t t
nonEmpty for f = dimap from to $ nonEmpty' for f

nonEmpty1 :: (ADTNonEmpty1 t, Constraints1 t c, GenericNonEmptyProfunctor p)
          => for c -> (forall d e s. c s => p d e -> p (s d) (s e)) -> p a b -> p (t a) (t b)
nonEmpty1 for f p = dimap from1 to1 $ nonEmpty1' for f p

-- | All the above functions have been implemented using this single function,
-- using different `profunctor`s.
generic :: (ADT t, Constraints t c, GenericProfunctor p)
        => for c -> (forall s. c s => p s s) -> p t t
generic for f = dimap from to $ generic' for f

generic1 :: (ADT1 t, Constraints1 t c, GenericProfunctor p)
         => for c -> (forall d e s. c s => p d e -> p (s d) (s e)) -> p a b -> p (t a) (t b)
generic1 for f p = dimap from1 to1 $ generic1' for f p

-- | `Constraints` is a constraint type synonym, containing the constraint requirements for an instance for `t` of class `c`.
-- It requires an instance of class `c` for each component of `t`.
type Constraints t c = Constraints' (Rep t) c

type Constraints1 t c = Constraints1' (Rep1 t) c

-- | `ADTRecord` is a constraint type synonym. An instance is an `ADT` with *exactly* one constructor.
type ADTRecord t = (Generic t, ADTRecord' (Rep t))

type ADTRecord1 t = (Generic1 t, ADTRecord1' (Rep1 t))

-- | `ADTNonEmpty` is a constraint type synonym. An instance is an `ADT` with *at least* one constructor.
type ADTNonEmpty t = (Generic t, ADTNonEmpty' (Rep t))

type ADTNonEmpty1 t = (Generic1 t, ADTNonEmpty1' (Rep1 t))

-- | `ADT` is a constraint type synonym. The `Generic` instance can be derived,
-- and any generic representation will be an instance of `ADT'`.
type ADT t = (Generic t, ADT' (Rep t))

type ADT1 t = (Generic1 t, ADT1' (Rep1 t))

-- | Tell the compiler which class we want to use in the traversal. Should be used like this:
--
-- > (For :: For Show)
--
-- Where @Show@ can be any class.
data For (c :: k -> Constraint) = For

-- | Get the index in the lists returned by `create` and `createA` of the constructor of the given value.
--
-- For example, this is the implementation of `put` that generates the binary data that
-- the above implentation of `get` expects:
--
-- @
-- `put` t = `putWord8` (`toEnum` (`ctorIndex` t)) `<>` `gfoldMap` (`For` :: `For` `Binary`) `put` t
-- @
ctorIndex :: ADT t => t -> Int
ctorIndex = ctorIndex' . from

ctorIndex1 :: ADT1 t => t a -> Int
ctorIndex1 = ctorIndex' . from1
