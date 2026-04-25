-- v0.5.0 — runghc-tiger.  Compile + scp + ssh-run, all in one.
-- This demo is meant to be run via `runghc-tiger` itself.  Pass args
-- and watch them survive the round trip from your host shell, through
-- ssh, into a Tiger-running PPC binary, and back as exit code.
--
-- Usage:
--   scripts/runghc-tiger demos/v0.5.0-runghc-args.hs alpha beta gamma
--   echo $?    # → 3 (the argv length we exit with)
--
-- v0.5.0 is what made this two-line workflow possible.  Before v0.5.0,
-- you needed to manually compile, scp, ssh, capture exit code, then
-- clean up the remote tmp file by hand.
module Main where

import System.Environment (getArgs, getProgName)
import System.Exit (exitWith, ExitCode(..))

main :: IO ()
main = do
  prog <- getProgName
  args <- getArgs
  putStrLn $ "runghc-tiger demo: " ++ prog
  putStrLn $ "  argc = " ++ show (length args)
  putStrLn $ "  argv = " ++ show args
  -- Exit with argc so the caller can verify exit codes round-trip.
  case length args of
    0 -> exitWith ExitSuccess
    n -> exitWith (ExitFailure n)
