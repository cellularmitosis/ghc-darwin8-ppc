-- Mandelbrot set printer.  Has plenty of arithmetic to make `+RTS -p` cost
-- centres meaningful, and runs in a few hundred ms so heap profiles too.
module Main where

import Data.Complex
import qualified Data.List as L

mandelIter :: Complex Double -> Int
mandelIter c = go 0 0
  where
    go n z
      | n >= maxIter           = maxIter
      | magnitude z >= 2.0     = n
      | otherwise              = go (n+1) (z*z + c)
    maxIter = 80

ramp :: Int -> Char
ramp n
  | n >= 80   = ' '
  | n >= 40   = '.'
  | n >= 20   = '+'
  | n >= 10   = '*'
  | n >=  5   = '#'
  | otherwise = '@'

renderRow :: Double -> Double -> Double -> Int -> String
renderRow xMin xMax y w =
    [ ramp (mandelIter (x :+ y))
    | i <- [0 .. w-1]
    , let x = xMin + (xMax - xMin) * fromIntegral i / fromIntegral (w-1)
    ]

main :: IO ()
main = do
  let w = 60
      h = 24
      xMin = -2.2; xMax = 1.0
      yMin = -1.2; yMax = 1.2
  mapM_ putStrLn
    [ renderRow xMin xMax y w
    | i <- [0 .. h-1]
    , let y = yMin + (yMax - yMin) * fromIntegral i / fromIntegral (h-1)
    ]
