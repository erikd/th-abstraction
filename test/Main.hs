{-# Language KindSignatures, TemplateHaskell, GADTs #-}

module Main (main) where

import Control.Monad
import Language.Haskell.TH
import Language.Haskell.TH.Datatype

import Harness

type Gadt1Int = Gadt1 Int

data Gadt1 a where
  Gadtc1 :: Int   -> Gadt1Int
  Gadtc2 :: (a,a) -> Gadt1 a

data Adt1 a b = Adtc1 (a,b) | Bool `Adtc2` Int

data Gadtrec1 a where
  Gadtrecc1, Gadtrecc2 :: { gadtrec1a :: a, gadtrec1b :: b } -> Gadtrec1 (a,b)

data Equal :: * -> * -> * -> * where
  Equalc :: (Read a, Show a) => [a] -> Maybe a -> Equal a a a

data Showable :: * where
  Showable :: Show a => a -> Showable

data R = R1 { field1, field2 :: Int }

return [] -- segment type declarations above from refiy below

main :: IO ()
main =
  do adt1Test
     gadt1Test
     gadtrec1Test
     equalTest
     showableTest
     recordTest

adt1Test :: IO ()
adt1Test =
  $(do info <- reifyDatatype ''Adt1

       let [a,b] = map (VarT . mkName) ["a","b"]

       validate info
         DatatypeInfo
           { datatypeName = ''Adt1
           , datatypeContext = []
           , datatypeVars = [a, b]
           , datatypeVariant = Datatype
           , datatypeCons =
               [ ConstructorInfo
                   { constructorName = 'Adtc1
                   , constructorContext = []
                   , constructorVars = []
                   , constructorFields = [AppT (AppT (TupleT 2) a) b]
                   , constructorVariant = NormalConstructor }
               , ConstructorInfo
                   { constructorName = 'Adtc2
                   , constructorContext = []
                   , constructorVars = []
                   , constructorFields = [ConT ''Bool, ConT ''Int]
                   , constructorVariant = NormalConstructor }
               ]
           }
   )

gadt1Test :: IO ()
gadt1Test =
  $(do info <- reifyDatatype ''Gadt1

       let a = VarT (mkName "a")

       validate info
         DatatypeInfo
           { datatypeName = ''Gadt1
           , datatypeContext = []
           , datatypeVars = [a]
           , datatypeVariant = Datatype
           , datatypeCons =
               [ ConstructorInfo
                   { constructorName = 'Gadtc1
                   , constructorVars = []
                   , constructorContext = [equalPred a (ConT ''Int)]
                   , constructorFields = [ConT ''Int]
                   , constructorVariant = NormalConstructor }
               , ConstructorInfo
                   { constructorName = 'Gadtc2
                   , constructorVars = []
                   , constructorContext = []
                   , constructorFields = [AppT (AppT (TupleT 2) a) a]
                   , constructorVariant = NormalConstructor }
               ]
           }
   )

gadtrec1Test :: IO ()
gadtrec1Test =
  $(do info <- reifyDatatype ''Gadtrec1

       let a = VarT (mkName "a")
       let [v1,v2] = map mkName ["v1","v2"]

       let con = ConstructorInfo
                   { constructorName    = 'Gadtrecc1
                   , constructorVars    = [PlainTV v1, PlainTV v2]
                   , constructorContext =
                        [equalPred a (AppT (AppT (TupleT 2) (VarT v1)) (VarT v2))]
                   , constructorFields  = [VarT v1, VarT v2]
                   , constructorVariant = RecordConstructor ['gadtrec1a, 'gadtrec1b] }

       validate info
         DatatypeInfo
           { datatypeName    = ''Gadtrec1
           , datatypeContext = []
           , datatypeVars    = [a]
           , datatypeVariant = Datatype
           , datatypeCons    =
               [ con, con { constructorName = 'Gadtrecc2 } ]
           }
   )

equalTest :: IO ()
equalTest =
  $(do info <- reifyDatatype ''Equal

       let [a,b,c] = map (VarT . mkName) ["a","b","c"]

       validate info
         DatatypeInfo
           { datatypeName    = ''Equal
           , datatypeContext = []
           , datatypeVars    = [a,b,c]
           , datatypeVariant = Datatype
           , datatypeCons    =
               [ ConstructorInfo
                   { constructorName    = 'Equalc
                   , constructorVars    = []
                   , constructorContext =
                        [equalPred a c, equalPred b c, classPred ''Read [c], classPred ''Show [c] ]
                   , constructorFields  =
                        [ListT `AppT` c, ConT ''Maybe `AppT` c]
                   , constructorVariant = NormalConstructor }
               ]
           }
   )

showableTest :: IO ()
showableTest =
  $(do info <- reifyDatatype ''Showable

       let a = mkName "a"

       validate info
         DatatypeInfo
           { datatypeName    = ''Showable
           , datatypeContext = []
           , datatypeVars    = []
           , datatypeVariant = Datatype
           , datatypeCons    =
               [ ConstructorInfo
                   { constructorName    = 'Showable
                   , constructorVars    = [PlainTV a]
                   , constructorContext = [classPred ''Show [VarT a]]
                   , constructorFields  = [VarT a]
                   , constructorVariant = NormalConstructor }
               ]
           }
   )

recordTest :: IO ()
recordTest =
  $(do info <- reifyDatatype ''R
       validate info
         DatatypeInfo
           { datatypeName    = ''R
           , datatypeContext = []
           , datatypeVars    = []
           , datatypeVariant = Datatype
           , datatypeCons    =
               [ ConstructorInfo
                   { constructorName    = 'R1
                   , constructorVars    = []
                   , constructorContext = []
                   , constructorFields  = [ConT ''Int, ConT ''Int]
                   , constructorVariant = RecordConstructor ['field1, 'field2] }
               ]
           }
   )
