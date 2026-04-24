-- Data.Time: basic formatting and arithmetic.  Values that can't
-- vary between host and target: UTC epoch + fixed-offset diff.
import Data.Time
import Data.Time.Clock.POSIX

main :: IO ()
main = do
  -- Epoch 0
  let epoch = posixSecondsToUTCTime 0
  putStrLn $ "epoch: " ++ show epoch
  -- Specific day
  let day = fromGregorian 2026 4 24
  putStrLn $ "day: " ++ show day
  -- Day arithmetic
  let laterDay = addDays 100 day
  putStrLn $ "+100 days: " ++ show laterDay
  -- Diff
  let diff = diffDays laterDay day
  putStrLn $ "diff: " ++ show diff ++ " days"
  -- Time of day
  let tod = TimeOfDay 14 30 45
  putStrLn $ "tod: " ++ show tod
  -- NominalDiffTime arithmetic
  let secs = 3661 :: NominalDiffTime
  putStrLn $ "3661s = " ++ show secs
