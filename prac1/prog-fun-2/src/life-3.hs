
{-# LANGUAGE OverloadedStrings #-}

module Main where
import Life.Board
import Life.Draw

import Drawing
import Drawing.Vector

-----------------------------------------------------
-- The game state

data Game = Game
        { gmBoard :: Board      -- last board generation
        , gmGridMode :: GridMode
        , gmZoom :: Double, gmShift :: Point
        }
    deriving (Show, Read)

setGmBoard x g       = g{ gmBoard = x }
setGmGridMode x g    = g{ gmGridMode = x }
setGmZoom x g        = g{ gmZoom = x }
setGmShift x g       = g{ gmShift = x }

data GridMode = NoGrid | LivesGrid | ViewGrid
    deriving (Show, Read)

-----------------------------------------------------
-- Initialization

viewWidth, viewHeight :: Double
viewWidth = 60.0
viewHeight = 30.0

main :: IO ()
main =
    activityOf viewWidth viewHeight initial handleEvent draw

board0Cells =
    [(-5, 0), (-4, 0), (-3, 0), (-2, 0), (-1, 0), (0, 0), (1, 0), (2, 0), (3, 0), (4, 0)]

initial = Game
    { gmBoard = foldr (setCell True) initBoard board0Cells
    , gmGridMode = NoGrid
    , gmZoom = 1.0, gmShift = (0.0, 0.0)
    }

-----------------------------------------------------
-- A completar per l'estudiant

-- Event handling
handleEvent :: Event -> Game -> Game
handleEvent (KeyDown "N") game =
    setGmBoard (nextGeneration (gmBoard game)) game
handleEvent (MouseDown (x, y)) game =
    let pos = screenToBoard (x, y) game
        brd = gmBoard game
    in setGmBoard (setCell (not $ cellIsLive pos brd) pos brd) game
handleEvent (KeyDown "G") game =
    setGmGridMode (next (gmGridMode game)) game
handleEvent (KeyDown "I") game = zoomIn game
handleEvent (KeyDown "O") game = zoomOut game
handleEvent (KeyDown "ARROWUP") game = move (0, (-1)) game
handleEvent (KeyDown "ARROWDOWN") game = move (0, 1) game
handleEvent (KeyDown "ARROWRIGHT") game = move ((-1), 0) game
handleEvent (KeyDown "ARROWLEFT") game = move (1, 0) game
handleEvent _ game =
    game

-- Game drawing
draw :: Game -> Drawing
draw game =
    let scale = gmZoom game
        offset = gmShift game in
    transformed offset scale (
        drawBoard (gmBoard game) <>
        gridDrawing game (gmGridMode game))

transformed :: Point -> Double -> Drawing -> Drawing
transformed (x, y) s drawing = scaled s s $ translated x y drawing

-- GridMode
next :: GridMode -> GridMode
next NoGrid = LivesGrid
next LivesGrid = ViewGrid
next _ = NoGrid

gridDrawing :: Game -> GridMode -> Drawing
gridDrawing _  NoGrid = blank
gridDrawing game LivesGrid = 
    let board = gmBoard game in
    drawGrid (minLiveCell board) (maxLiveCell board)
gridDrawing game ViewGrid =
    let z = gmZoom game
        w = round (viewWidth / z)
        h = round (viewHeight / z) in
    drawGrid (-w, -h) (w, h)

-- Screen to board coordinates
screenToBoard :: Point -> Game -> Pos
screenToBoard point game =
    let (bx, by) = (1.0 / gmZoom game) *^ point ^-^ gmShift game
    in (round bx, round by)

-- Zoom functionality
zoomIn :: Game -> Game
zoomIn = zoom 2.0

zoomOut :: Game -> Game
zoomOut = zoom 0.5

zoom :: Double -> Game -> Game
zoom factor game = 
    let newZoom = gmZoom game * factor in
    setGmZoom (min 2.0 (max 0.25 newZoom)) game


-- Move functionality
move :: Point -> Game -> Game
move offset game =
    setGmShift (gmShift game ^+^ offset) game
