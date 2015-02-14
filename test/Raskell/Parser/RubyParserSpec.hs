module Raskell.Parser.RubyParserSpec where

import SpecHelper
import Text.Parsec (parse)
import Text.Parsec.String (Parser)
import Text.Parsec.Error
import Data.Either
import Text.Parsec.Prim (Stream, ParsecT)
import Raskell.Parser.FunctionsAndTypesForParsing (regularParse)
import Raskell.Parser.RubyParser
import Raskell.Parser.Whitespace (whitespace)
import Raskell.Parser.ASTNodes

fullParse :: Parser a -> String -> a
fullParse p = unbox . parse (whitespace >> p) ""
  where
    unbox :: Either ParseError a -> a
    unbox (Left _) = error "failed"
    unbox (Right a) = a

veryBasicParsing :: Spec
veryBasicParsing = do
  numericParsing
  variableParsing
  parensParsing
  binopParsing
  exprParsing

numericParsing :: Spec
numericParsing =
  describe "numeric parsing" $ do
    it "parses a simple number" $
      fullParse numeric "1" `shouldBe` Int 1
    it "parses a simple number with multiple numbers" $
      fullParse numeric "123" `shouldBe` Int 123
    it "parses a simple number with underscores" $
      fullParse numeric "1_2_3" `shouldBe` Int 123
    it "parses a simple float" $
      fullParse numeric "1.23" `shouldBe` Float 1.23
    it "doesn't parse a simple float with no leading number" $
      regularParse numeric ".23" `shouldSatisfy` isLeft
    it "parses a simple float with underscores" $
      fullParse numeric "1_2.23" `shouldBe` Float 12.23
    it "parses a simple float with underscores on the right" $
      fullParse numeric "1_2.2_3" `shouldBe` Float 12.23
    it "parses variables with upcase innards" $
      fullParse var "abCd" `shouldBe` Var "abCd"
    it "does not parse a variable starting with a digit" $
      regularParse var "1abc" `shouldSatisfy` isLeft

variableParsing :: Spec
variableParsing =
  describe "variable parsing" $ do
    it "parses an alpha variable" $
      fullParse var "abcd" `shouldBe` Var "abcd"
    it "parses variables with upcase innards" $
      fullParse var "abCd" `shouldBe` Var "abCd"
    it "does not parse a variable starting with a digit" $
      regularParse var "1abc" `shouldSatisfy` isLeft
    it "parses a variable with a leading _" $
      fullParse var "_abc" `shouldBe` Var "_abc"
    it "parses a variable with a leading __" $
      fullParse var "__abc" `shouldBe` Var "__abc"

parensParsing :: Spec
parensParsing =
  describe "parens parsing" $ do
    it "parses a number inside parens" $
      fullParse parens "(1)" `shouldBe` Parens (Int 1)
    it "parses a number inside parens with leading whitespace" $
      fullParse parens "( 1)" `shouldBe` Parens (Int 1)
    it "parses a number inside parens with trailing whitespace" $
      fullParse parens "(1 )" `shouldBe` Parens (Int 1)
    it "parses a number inside parens with whitespace" $
      fullParse parens "( 1 )" `shouldBe` Parens (Int 1)
    it "parses a number inside parens following whitespace" $
      fullParse parens "(1) " `shouldBe` Parens (Int 1)
    it "parses a long number inside parens" $
      fullParse parens "(1234)" `shouldBe` Parens (Int 1234)
    it "TODO parses blank parens" $ -- TODO FIXME
      -- regularParse parens "()" `shouldBe` Parens ?
      regularParse parens "()" `shouldSatisfy` isLeft

binopParsing :: Spec
binopParsing =
  describe "parsing plus" $ do
    it "parses 2 + 2" $
      fullParse add "2+2" `shouldBe` BPlus (Int 2) (Int 2)
    it "parses 2 + 2 with whitespace" $
      fullParse add " 2 + 2 " `shouldBe` BPlus (Int 2) (Int 2)
    it "parses 2.0 + 2.1" $
      fullParse add "2.0+2.1" `shouldBe` BPlus (Float 2.0) (Float 2.1)

exprParsing :: Spec
exprParsing =
  describe "expression parsing" $ do
    it "parses 2 + 2" $
      fullParse expr "2 + 2" `shouldBe` BPlus (Int 2) (Int 2)
    it "parses parens with add" $
      fullParse expr "(2 +3)" `shouldBe` Parens (BPlus (Int 2) (Int 3))
    it "parses float with add" $
      fullParse expr "(2.0 +3)" `shouldBe` Parens (BPlus (Float 2.0) (Int 3))
    it "parses add with var" $
      fullParse expr "(2.0 + a)" `shouldBe` Parens (BPlus (Float 2.0) (Var "a"))

main :: IO ()
main = hspec spec
spec :: Spec
spec = veryBasicParsing