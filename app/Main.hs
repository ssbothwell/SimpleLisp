{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad.Except
import Control.Monad.Reader

import qualified Data.ByteString as BS
import Data.Text (Text, pack, unpack)
import Data.Text.Encoding
import Data.Text.Encoding.Error

import System.Environment

import Evaluator.Types
import Evaluator
import Parser
import Repl
 
------------
--- AppM ---
------------

data Env = Env { _source :: Text, _logLevel :: LogLevel }

newtype AppM m a = AppM { unAppM :: ReaderT Env m a }
  deriving (Functor, Applicative, Monad, MonadReader Env, MonadIO)

runAppM :: Env -> AppM m a -> m a
runAppM env (AppM m) = runReaderT m env

interpret :: AppM IO (Either EvalError Term)
interpret = do
  sourceCode <- asks _source
  let lispExpression = parse sourceCode
  return . evalLispM evalEnv $ eval lispExpression


------------
--- Main ---
------------

readFilePath :: Text -> IO Text
readFilePath = fmap (decodeUtf8With lenientDecode) . BS.readFile . unpack

readArgs :: IO (Maybe [Text])
readArgs = do
  args <- (fmap . fmap) pack getArgs
  case args of
    [] -> return Nothing
    xs -> return $ Just xs

main :: IO ()
main = do
  args <- readArgs
  case args of
    Just [mode, arg] -> 
      case mode of
        "-o" -> do
          contents <- readFilePath arg
          let env = Env contents Normal
          result <- runAppM env interpret
          print result
        "-e" -> do
          let env = Env arg Normal
          result <- runAppM env interpret
          print result
        "-i" -> repl evalEnv
        _ -> repl evalEnv
    _ -> repl evalEnv
