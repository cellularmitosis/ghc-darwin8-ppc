-- v0.10.0 demo: -prof cost-centre + heap profiling on Tiger.
--
-- Compile and run:
--   $ source scripts/cross-env.sh
--   $ STAGE1=external/ghc-modern/ghc-9.2.8/_build/stage1/bin/powerpc-apple-darwin8-ghc
--   $ $STAGE1 -O -prof -fprof-auto demos/v0.10.0-mandel-prof.hs -o /tmp/mandel
--   $ scp /tmp/mandel pmacg5:/tmp/ && \
--       ssh pmacg5 'cd /tmp && DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
--                                ./mandel +RTS -p -h -RTS && cat mandel.prof | head -20'
--
-- Output: ASCII Mandelbrot set, plus a real GHC cost-centre time/alloc
-- report and a `.hp` heap-profile sample file ready for hp2ps post-
-- processing.

module Main where

import Data.Complex

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
