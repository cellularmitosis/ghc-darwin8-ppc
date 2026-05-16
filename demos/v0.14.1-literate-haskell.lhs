v0.14.1 demo program — literate Haskell on PPC/Tiger
=====================================================

This is a literate Haskell file in *bird-track* style.  Lines that
start with a `>` (followed by a space) are code; everything else is
prose, which the compiler ignores.  The `unlit` pre-processor is
what strips the prose out and feeds the bare Haskell to ghc.

That same `unlit` binary is what was wrong in the v0.14.0 bindist
(it shipped a host arm64 binary that couldn't execute on Tiger).
v0.14.1 ships a real PPC unlit, so this file compiles and runs.

Module header:

> module Main where
> import Data.List (sort)
> import Data.Char (toUpper)

A small `factorial`, to prove the bignum path works through a `.lhs`
file:

> factorial :: Integer -> Integer
> factorial 0 = 1
> factorial n = n * factorial (n - 1)

The Collatz sequence — picks a starting `n`, applies `3n+1` if odd,
`n/2` if even, repeats until reaching 1:

> collatz :: Int -> [Int]
> collatz 1 = [1]
> collatz n
>   | even n    = n : collatz (n `div` 2)
>   | otherwise = n : collatz (3 * n + 1)

Tying it together:

> main :: IO ()
> main = do
>   putStrLn "literate haskell on tiger ppc:"
>   putStrLn ("  factorial 20  = " ++ show (factorial 20))
>   putStrLn ("  sort \"tiger\"  = " ++ show (sort "tiger"))
>   putStrLn ("  map toUpper   = " ++ map toUpper "ppc darwin 8")
>   putStrLn ("  collatz 27    = length " ++ show (length (collatz 27))
>                                ++ ", max " ++ show (maximum (collatz 27)))
