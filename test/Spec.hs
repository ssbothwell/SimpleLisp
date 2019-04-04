module Main where

import Control.Monad.Except (runExcept)
import Control.Applicative
import Text.Trifecta
import Test.Hspec
import Data.Function (on)
import Lib


yields :: Eq a => a -> Result a -> Bool
yields s (Success s') = s == s'
yields _ _ = False

parseFailed :: Result a -> Bool
parseFailed (Success _) = False
parseFailed _ = True

specParseYields :: String -> Term -> SpecWith ()
specParseYields s term =
    it ("parses " ++ s ++ " as " ++ show term) $
        parse s `shouldSatisfy` yields term

specParseFails :: String -> SpecWith ()
specParseFails s =
    it ("fails to parse " ++ s) $
        parse s `shouldSatisfy` parseFailed

specEvalYields :: Term -> Either EvalError Term -> SpecWith ()
specEvalYields term eterm =
    it ("evaluates " ++ show term ++ " as " ++ show eterm) $
        (runExcept . evalTerm) term `shouldBe` eterm
    
checkParse :: SpecWith ()
checkParse = describe "Test Parser" $
    mapM_ (uncurry specParseYields)
        [ ("1", Number 1)
        , ("True", Boolean True)
        , ("False", Boolean False)
        , ("\"Foobar\"", String "Foobar")
        , ("add", Atom "add")
        , ("lambda", Atom "lambda")
        , ("()", List [])
        , ("(1)", List [Number 1])
        , ("(1 2 3)", List [Number 1, Number 2, Number 3])
        , ("(1 . 2 . 3)", List [Number 1, Number 2, Number 3])
        --, ("(True . 1 . 2 . 3)", List [Boolean True, Number 1, Number 2, Number 3])
        , ("(1 2 (True False))", List [Number 1, Number 2, List [Boolean True, Boolean False]])
        , ("(add 1 2)", List [Atom "add", Number 1, Number 2])
        , ("(lambda x (add 1 2))", List [Atom "lambda", Atom "x", List [Atom "add", Number 1, Number 2]])
        ]
   
checkEval :: SpecWith ()
checkEval = describe "Test Evaluation" $
    mapM_ (uncurry specEvalYields)
        [ (Number 1, Right $ Number 1)
        , (Boolean True, Right $ Boolean True)
        , (Boolean False, Right $ Boolean False)
        , (String "Foobar", Right $ String "Foobar")
        , (Atom "add", Right $ Atom "add")
        , (Atom "lambda", Right $ Atom "lambda")
        , (List [], Right $ List [])
        , (List [Number 1], Right $ List [Number 1])
        , (List [Atom "add", Number 1, Number 2], Right $ Number 3)
        , (List [Atom "add", Number 1, List [Atom "add", Number 2, List [Atom "add", Number 3, Number 4]]], Right $ Number 10)
        , (List [Number 1, List [Atom "add", Number 1, List [Atom "add", Number 2, List [Atom "add", Number 3, Number 4]]]], Right $ List [Number 1, Number 10])
        , (List [Boolean True, Number 1, List [Atom "add", Number 1, List [Atom "add", Number 2, List [Atom "add", Number 3, Number 4]]]], Right $ List [Boolean True, Number 1, Number 10])
        ]

main :: IO ()
main = hspec $ do
    checkParse
    checkEval
