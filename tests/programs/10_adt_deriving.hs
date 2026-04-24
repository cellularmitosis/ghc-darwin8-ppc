data Color = Red | Green | Blue deriving (Show, Eq, Ord, Enum, Bounded)

data Tree a = Leaf | Node (Tree a) a (Tree a) deriving Show

insert :: Ord a => a -> Tree a -> Tree a
insert x Leaf = Node Leaf x Leaf
insert x t@(Node l v r)
  | x < v = Node (insert x l) v r
  | x > v = Node l v (insert x r)
  | otherwise = t

inorder :: Tree a -> [a]
inorder Leaf = []
inorder (Node l v r) = inorder l ++ [v] ++ inorder r

main :: IO ()
main = do
  mapM_ print [Red, Green, Blue]
  putStrLn $ "Red == Red: " ++ show (Red == Red)
  putStrLn $ "Red < Blue: " ++ show (Red < Blue)
  putStrLn $ "[minBound..maxBound] :: [Color] = " ++ show [minBound..maxBound :: Color]
  let t = foldr insert Leaf [5, 2, 8, 1, 9, 3, 7, 4, 6]
  putStrLn $ "inorder BST [5,2,8,..]: " ++ show (inorder t :: [Int])
