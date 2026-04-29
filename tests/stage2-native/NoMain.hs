-- Module without main, no Typeable.  Should compile cleanly.
module NoMain where

addOne :: Int -> Int
addOne x = x + 1
