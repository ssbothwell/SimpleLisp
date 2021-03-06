{-# LANGUAGE OverloadedStrings #-}
module Main where

import Data.Text (Text)
import Text.Trifecta

-- | TODO: + QuickCheck
import Test.Hspec

import Evaluator
import Evaluator.Types
import Parser


yields :: Eq a => a -> Result a -> Bool
yields s (Success s') = s == s'
yields _ _ = False

parseFailed :: Result a -> Bool
parseFailed (Success _) = False
parseFailed _ = True

specParseYields :: Text -> Term -> SpecWith ()
specParseYields s term =
    it ("parses " ++ show s ++ " as " ++ show term) $
        parse s `shouldSatisfy` yields term

specParseFails :: Text -> SpecWith ()
specParseFails s =
    it ("fails to parse " ++ show s) $
        parse s `shouldSatisfy` parseFailed

specEvalYields :: Text -> Either EvalError Term -> SpecWith ()
specEvalYields term eterm =
    it ("evaluates " ++ show term ++ " as " ++ show eterm) $
        (evalLispM evalEnv . eval) (parse term) `shouldBe` eterm


testCases :: [(Text, Term, Either EvalError Term)]
testCases =
  -- Atomic Values
  [ ( "1"
    , Number 1
    , Right $ Number 1
    )
  , ( "True",
      Boolean True
    , Right $ Boolean True)
  , ( "False"
    , Boolean False
    , Right $ Boolean False
    )
  , ( "\"Foobar\""
    , String "Foobar"
    , Right $ String "Foobar"
    )
  , ( "+"
    , Symbol "+"
    , Left IllFormedSyntax
    )
  , ( "()"
    , List []
    , Right $ List []
    )
  ]
  ++
  -- Lists/DotLists
  [ ( "(1)"
    , List [Number 1]
    , Left $ ObjectNotApplicable (Number 1)
    )
  , ( "(True)"
    , List [Boolean True]
    , Left $ ObjectNotApplicable (Boolean True)
    )
  , ( "(1 2 3)"
    , List [Number 1, Number 2, Number 3]
    , Left $ ObjectNotApplicable (Number 1)
    )
  , ( "(1 2 (True False))"
    , List [Number 1, Number 2, List [Boolean True, Boolean False]]
    , Left $ ObjectNotApplicable (Boolean True)
    )
  , ( "(1 . 2)"
    , DotList ([Number 1], Number 2)
    , Left . NotAProperList $ DotList ([Number 1], Number 2)
    )
  , ( "(1 2 . 3)"
    , DotList ([Number 1, Number 2], Number 3)
    , Left $ NotAProperList (DotList ([Number 1, Number 2], Number 3))
    )
  , ( "(1 . (2 . (3 . 4)))"
    , DotList ([Number 1], DotList ([Number 2], DotList ([Number 3], Number 4)))
    , Left $ NotAProperList (DotList ([Number 3], Number 4)) -- Would be nice if this printed the full list
    )
  ]
  ++
  -- +
  [ ( "(+ 1 2)"
    , List [Symbol "+", Number 1, Number 2]
    , Right $ Number 3
    )
  , ( "(+ 1 (+ 2 (+ 3 4)))"
    , List [Symbol "+", Number 1, List [Symbol "+", Number 2, List [Symbol "+", Number 3, Number 4]]]
    , Right $ Number 10
    )
  ]
  ++
  -- quote
  [ ( "'(1 2)"
    , List [Symbol "quote", List [Number 1, Number 2]]
    , Right $ List [Number 1, Number 2]
    )
  , ( "'(1 . 2)"
    , List [Symbol "quote", DotList ([Number 1], Number 2)]
    , Right $ DotList ([Number 1], Number 2)
    )
  ]
  ++
  -- atom
  [ ( "(atom? 1)"
    , List [Symbol "atom?", Number 1]
    , Right $ Boolean True
    )
  , ( "(atom? '(1))"
    , List [Symbol "atom?", List [Symbol "quote", List [Number 1]]]
    , Right $ Boolean False
    )
  ]
  ++
  -- eq?
  [ ( "(eq? 1 1)"
    , List [Symbol "eq?", Number 1, Number 1]
    , Right $ Boolean True
    )
  , ( "(eq? 1 2)"
    , List [Symbol "eq?", Number 1, Number 2]
    , Right $ Boolean False
    )
  , ( "(eq? 3 (+ 1 2))"
    , List [Symbol "eq?", Number 3, List [Symbol "+", Number 1, Number 2]]
    , Right $ Boolean True
    )
  ]
  ++
  -- cons
  [ ( "(cons 1 2)"
    , List [Symbol "cons", Number 1, Number 2]
    , Right $ DotList ([Number 1], Number 2)
    )
  , ( "(cons 1 '(2 3))"
    , List [Symbol "cons", Number 1, List [Symbol "quote", List [Number 2, Number 3]]]
    , Right $ List [Number 1, Number 2, Number 3]
    )
  , ( "(cons 1 (cons 2 ()))"
    , List [Symbol "cons", Number 1, List [Symbol "cons", Number 2, List []]]
    , Right $ List [Number 1, Number 2]
    )
  ]
  ++
  -- car
  [ ( "(car '(1 2))"
    , List [Symbol "car", List [Symbol "quote", List [Number 1, Number 2]]]
    , Right $ Number 1
    )
  , ( "(car '(1 . 2))"
    , List [Symbol "car", List [Symbol "quote", DotList ([Number 1], Number 2)]]
    , Right $ Number 1
    )
  ]
  ++
  -- cdr
  [ ( "(cdr '(1 2))"
    , List [Symbol "cdr", List [Symbol "quote", List [Number 1, Number 2]]]
    , Right $ List [Number 2]
    )
  , ( "(cdr '(1 . 2))"
    , List [Symbol "cdr", List [Symbol "quote", DotList ([Number 1], Number 2)]]
    , Right $ Number 2
    )
  ]
  ++
  -- cond
  [ ( "(cond)"
    , List [Symbol "cond"]
    , Left UnspecifiedReturn
    )
  , ( "(cond ())"
    , List [Symbol "cond", List []]
    , Left IllFormedSyntax
    )
  , ( "(cond 1)"
    , List [Symbol "cond", Number 1]
    , Left IllFormedSyntax
    )
  , ( "(cond 1 2)"
    , List [Symbol "cond", Number 1, Number 2]
    , Left IllFormedSyntax
    )
  , ( "(cond (()))"
    , List [Symbol "cond", List [List []]]
    , Right $ List []
    )
  , ( "(cond (True))"
    , List [Symbol "cond", List [Boolean True]]
    , Right $ Boolean True
    )
  , ( "(cond (1))"
    , List [Symbol "cond", List [Number 1]]
    , Right $ Number 1
    )
  , ( "(cond (True 1))"
    , List [Symbol "cond", List [Boolean True, Number 1]]
    , Right $ Number 1
    )
  , ( "(cond (2 1))"
    , List [Symbol "cond", List [Number 2, Number 1]]
    , Right $ Number 1
    )
  , ( "(cond (False 1) (True 2))"
    , List [Symbol "cond", List [Boolean False, Number 1], List [Boolean True, Number 2]]
    , Right $ Number 2
    )
  ]
  -- ++
  -- -- lambda
  -- [ ( "(lambda x (+ 1 2))"
  --   )
  -- ]
        
-- | TODO: + unhappy parses
checkParse :: SpecWith ()
checkParse = describe "Test Parser" $
    mapM_ (uncurry specParseYields) $ (\(str, ast, _) -> (str, ast)) <$> testCases

checkEval :: SpecWith ()
checkEval = describe "Test Evaluation" $
    mapM_ (uncurry specEvalYields) $ (\(str, _, term) -> (str, term)) <$> testCases
      

main :: IO ()
main = hspec $ do
    checkParse
    checkEval
