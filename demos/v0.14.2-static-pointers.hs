{-# LANGUAGE StaticPointers #-}
-- v0.14.2 demo: StaticPointers (and -fobject-code GHCi) on PPC/Tiger.
--
-- The compiler emits SPT-init code that registers each `static`
-- pointer with the GHC runtime so it can be deRef'd later.  That init
-- code calls `__cxa_atexit(handler, env, __dso_handle)` so the SPT
-- entries are unregistered at shutdown.  On Mach-O, `__dso_handle`
-- is spelled `___dso_handle` in the object's symbol table (three
-- leading underscores -- the platform underscore-prefix convention).
--
-- Pre-v0.14.2 the runtime Mach-O loader's `lookupDependentSymbol`
-- special case for `__dso_handle` strcmp'd against the ELF
-- spelling, missed the Mach-O form, and dropped through to dlsym --
-- which on Tiger doesn't expose `___dso_handle` (provided at link
-- time by dylib1.o / crt1.o, not in the dyld namespace).  Result:
-- `:l Foo.hs` in GHCi `-fobject-code` mode aborted with
--   unknown symbol `___dso_handle'
-- whenever the module had any `static` reference.
--
-- v0.14.2's two-line patch to `rts/Linker.c` matches both spellings.
module Main where

import GHC.StaticPtr

-- A handful of `static` pointers of different shapes, to make the
-- demo more than a single yes/no.

staticTrue :: StaticPtr Bool
staticTrue = static True

staticGreeting :: StaticPtr String
staticGreeting = static "v0.14.2 static-pointer demo on PPC/Tiger"

staticDouble :: StaticPtr (Int -> Int)
staticDouble = static (\x -> x + x)

staticSum :: StaticPtr ([Int] -> Int)
staticSum = static sum

main :: IO ()
main = do
    putStrLn "deRefStaticPtr round-trip:"
    putStrLn $ "  static True               = " ++ show (deRefStaticPtr staticTrue)
    putStrLn $ "  static \"v0.14.2 ...\"      = " ++ deRefStaticPtr staticGreeting
    putStrLn $ "  static (\\x -> x+x) $ 21   = " ++ show (deRefStaticPtr staticDouble 21)
    putStrLn $ "  static sum $ [1..10]      = " ++ show (deRefStaticPtr staticSum [1..10])
    putStrLn ""
    putStrLn "StaticPointers work on PPC/Tiger."
