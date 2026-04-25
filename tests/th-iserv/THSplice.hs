{-# LANGUAGE TemplateHaskell #-}
module Main where

import Language.Haskell.TH

-- $(stringE "hello") becomes the literal "hello" at TH time.
-- If TH works, this prints "hello from a TH splice on Tiger".
main :: IO ()
main = putStrLn $(stringE "hello from a TH splice on Tiger")
