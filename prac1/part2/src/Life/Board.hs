
-- This module defines a model for the board of 'The Game of Life'

module Life.Board
    ( Board, Pos, initBoard
    , cellIsLive, liveCells
    , minCol, maxCol, minRow, maxRow, minLiveCell, maxLiveCell
    , setCell, nextGeneration
    )
where
import qualified Data.Set as S
import qualified Data.Map as M

import System.IO.Unsafe

-- Each cell in the board is determined by a pair of Int's (column, row)
type Pos = (Int, Int)

-- The type of the board
data Board = Board
        { cells :: S.Set Pos
        , minCol :: Int, maxCol :: Int
        , minRow :: Int, maxRow :: Int
        }
    deriving (Show, Read)

-- The empty board (all cells are dead)
initBoard :: Board
initBoard =
    Board S.empty 0 0 0 0

-- 'cellIsLive pos board' is true iff the cell at 'pos' of 'board' is live
cellIsLive :: Pos -> Board -> Bool
cellIsLive pos board =
    S.member pos (cells board)

-- 'liveCells board' is the list of live cells of 'board'
liveCells :: Board -> [Pos]
liveCells board =
    S.toList (cells board)

-- Get the minimum position (column, row) of the live cells
minLiveCell :: Board -> Pos
minLiveCell board =
    (minCol board, minRow board)

-- Get the maximum position (column, row) of the live cells
maxLiveCell :: Board -> Pos
maxLiveCell board =
    (maxCol board, maxRow board)

-- 'setCell live pos board' change the liveness of cell at 'pos' of 'board' (live if 'live' is 'True' or dead if 'live' is 'False')
setCell :: Bool -> Pos -> Board -> Board
setCell False pos board =
    board{ cells = S.delete pos (cells board) }
setCell True pos@(col, row) board | S.null (cells board) =
    board{ cells = S.insert pos (cells board)
         , minCol = col, maxCol = col
         , minRow = row, maxRow = row
         }
setCell True pos@(col, row) board =
    board{ cells = S.insert pos (cells board)
         , minCol = min col (minCol board), maxCol = max col (maxCol board)
         , minRow = min row (minRow board), maxRow = max row (maxRow board)
         }

-- 'nextGeneration board' gets the next generation of 'board'
nextGeneration :: Board -> Board
nextGeneration board =
    foldr setLive initBoard $ M.toList newCells
    where
        -- 'newCells' is a map from cell positions to pairs (live, neighbors)
        newCells :: M.Map Pos (Bool, Int)
        newCells =
            let livePoss = liveCells board
                map0 = M.fromList $ fmap (\pos -> (pos, (True, 0))) livePoss
            in foldr newCellsFor map0 livePoss
        newCellsFor pos1 map1 =
            let nposs = neighborPositions pos1
                incNeighbors pos map = M.insertWith (\ _ (live, n) -> (live, n + 1)) pos (False, 1) map
            in foldr incNeighbors map1 nposs
        setLive (pos, (live, around)) board1 =
            if live && elem around [2, 3] || not live && around == 3 then
                setCell True pos board1
            else board1

neighborPositions :: Pos -> [Pos]
neighborPositions (col, row) =
    [ (col + 1, row), (col + 1, row + 1), (col, row + 1), (col - 1, row + 1)
    , (col - 1, row), (col - 1, row - 1), (col, row - 1), (col + 1, row - 1)
    ]

