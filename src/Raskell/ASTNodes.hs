module Raskell.ASTNodes
( Expr (..)
) where

data Expr = RbInt Integer
          | RbFloat Double
          | RbString String
          | BPlus Expr Expr
          | Parens Expr
          | RubyToken String [Expr]
          | VarAssign String Expr
            deriving (Show, Eq)
