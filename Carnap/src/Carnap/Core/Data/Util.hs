{-#LANGUAGE FlexibleContexts, RankNTypes,TypeOperators, ScopedTypeVariables, GADTs, MultiParamTypeClasses #-}

module Carnap.Core.Data.Util (scopeHeight, equalizeTypes, incArity, checkChildren,
mapover, (:~:)(Refl)) where

--this module defines utility functions and typeclasses for manipulating
--the data types defined in Core.Data

import Carnap.Core.Data.AbstractSyntaxDataTypes
import Carnap.Core.Data.AbstractSyntaxClasses
import Data.Typeable
import Control.Lens.Plated (Plated, cosmos, transform, children)
import Control.Lens.Fold (anyOf)
import Data.Typeable
import Control.Monad.State.Lazy

--------------------------------------------------------
--1.Utility Functions
--------------------------------------------------------

{-|
Given two occupants of a typed fixpoint, this function returns @Just@
a proof of the equality of their types, if their types are equal, and
otherwise @Nothing@.  Concretely, it lets you do things like dispatch to
different behaviors depending on the type of your arguments, for all the
languages that Carnap supports (since these languages are typed
fixedpoints).

For example, suppose you have two functions @f :: Language Int -> Bool@ and
@g :: Language Bool -> Bool@, and two representative language items @a ::
Language Int@, and @b :: Language Bool@. Then you can write

> combine f g v = case equalizeTypes v a of
>                     Just Refl -> f v
>                     Nothing -> case equalizeTypes v b of
>                         Just Refl -> g v
>                         Nothing -> False

to union the functions into a single polymorphic function.

-}
equalizeTypes :: Fix f a -> Fix f b -> Maybe (a :~: b)
equalizeTypes (x@(Fx _) :: Fix f a) (y@(Fx _) :: Fix f b) = eqT :: Maybe (a :~: b)

{-|
This function replaces the head of a given language item with another head
that increases the arity of the item.
-}
incArity :: (Typeable a, Typeable b) => 
    (forall c . FixLang l c ->  Maybe (FixLang l (b -> c))) -> 
    FixLang l (b -> a)  ->  Maybe (FixLang l (b -> b -> a))
incArity f ((head :: FixLang l (t -> b -> a)) :!$: (tail :: FixLang l t)) = 
        case eqT :: Maybe (t :~: b) of
            Nothing -> Nothing
            Just Refl ->  do x <- incArity f head
                             return $ x :!$: tail
incArity f head = f head

{-|
this function checks to see if phi occurs as a child of psi
-}
checkChildren :: (Eq s, Plated s) => s -> s -> Bool
checkChildren phi psi = phi /= psi && anyOf cosmos (== phi) psi

{-|
this function will, given a suitably polymorphic argument `f`, apply `f` to each of the children of the linguistic expression `le`.
-}
mapover :: (forall a . FixLang l a -> FixLang l a) -> FixLang l b -> FixLang l b
mapover f le@(x :!$: y) = mapover f x :!$: f y
mapover f x = x

{-|
This function will assign a height to a given linguistic expression,
greater than the height of any of any formula in the scope of one of its
variable-binding subexpressions
-}
scopeHeight :: MonadVar (FixLang f) (State Int) => FixLang f a -> Int
scopeHeight (x :!$: y) = max (scopeHeight x) (scopeHeight y)
scopeHeight (LLam f) = scopeHeight (f dv) + 1
    where  dv = evalState fresh (0 :: Int)
scopeHeight _ = 0
