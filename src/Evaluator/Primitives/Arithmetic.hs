{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE LambdaCase #-}
module Evaluator.Primitives.Arithmetic where

import Control.Monad.Except

import Evaluator.Types

data ArithOp = Add | Subtract | Multiply | Divide | ABS | Modulo | Signum | Negate

parseArithOp :: Term -> Maybe ArithOp
parseArithOp (Symbol str) =
  case str of
    "+"       -> Just Add
    "-"       -> Just Subtract
    "*"       -> Just Multiply
    "/"       -> Just Divide
    "%"       -> Just Modulo
    "abs"     -> Just ABS
    "signum"  -> Just Signum
    "negate"  -> Just Negate
    _         -> Nothing
parseArithOp _ = Nothing

add :: MonadError EvalError m => DotList Term -> m Term
add terms = return . Number $ f terms
  where f (Number x :-. Nil) = x
        f (Number x :-: xs)  = x + f xs
        f _                = 0

subtract' :: MonadError EvalError m => DotList Term -> m Term
subtract' terms = return . Number $ f terms
  where f = undefined

multiply :: MonadError EvalError m => DotList Term -> m Term
multiply terms = return . Number $ f terms
  where f (Number x :-. Nil) = x
        f (Number x :-: xs)  = x * f xs
        f _                = 1

divide :: MonadError EvalError m => DotList Term -> m Term
divide = arrity 2 "/" f
  where
    f mterm =
      mterm >>= \case
        Unary _ -> undefined
        Binary (Number x) (Number y) -> return . Number $ x `div` y
        Binary _ _ -> undefined

abs' :: MonadError EvalError m => DotList Term -> m Term
abs' = arrity 1 "abs" f
  where
    f mterm =
      mterm >>= \case
        Unary (Number x) -> return . Number $ abs x
        Unary _ -> undefined
        Binary _ _ -> undefined

modulo :: MonadError EvalError m => DotList Term -> m Term
modulo = arrity 2 "%" f
  where
    f mterm =
      mterm >>= \case
        Binary (Number x) (Number y) -> return . Number $ x `mod` y
        Binary _ _ -> undefined
        Unary _ -> undefined

negate' :: MonadError EvalError m => DotList Term -> m Term
negate' = arrity 1 "negate" f
  where
    f mterm =
      mterm >>= \case
        Unary (Number x) -> return . Number $ negate x
        Unary _ -> undefined
        Binary _ _ -> undefined

signum' :: MonadError EvalError m => DotList Term -> m Term
signum' = arrity 1 "signum" f
  where
    f mterm =
      mterm >>= \case
        Unary (Number x) -> return . Number $ signum x
        Unary _ -> undefined
        Binary _ _ -> undefined
