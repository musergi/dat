
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
        , gmPaused :: Bool
        , gmInterval :: Time    -- generation interval when not paused
        , gmPendingTime :: Time -- time from last generation
        }
    deriving (Show, Read)

setGmBoard x g       = g{ gmBoard = x }
setGmGridMode x g    = g{ gmGridMode = x }
setGmZoom x g        = g{ gmZoom = x }
setGmShift x g       = g{ gmShift = x }
setGmPaused x g      = g{ gmPaused = x }
setGmInterval x g    = g{ gmInterval = x }
setGmPendingTime x g = g{ gmPendingTime = x }

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
    , gmPaused = True
    , gmInterval = 1.0 -- in seconds
    , gmPendingTime = 0.0
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
handleEvent (KeyDown " ") game = switchPaused game
handleEvent (KeyDown "+") game = multInterval 0.5 game
handleEvent (KeyDown "-") game = multInterval 2.0 game
handleEvent (TimePassing dt) game = timeUpdate dt game
handleEvent _ game =
    game

-- Game drawing
draw :: Game -> Drawing
draw game =
    let scale = gmZoom game
        offset = gmShift game in
    transformed offset scale (
        drawBoard (gmBoard game) <>
        gridDrawing game (gmGridMode game)) <>
    drawUserInterface game

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

-- Time passing funtionality
timeUpdate :: Double -> Game -> Game
timeUpdate dt game = updateWhenNoPendingTime $ timeElapse dt game

updateWhenNoPendingTime game =
    let pendingTime = gmPendingTime game in
    if pendingTime < 0
        then resetPendingTime $ updataBoard game
        else game

updataBoard :: Game -> Game
updataBoard game = setGmBoard (nextGeneration (gmBoard game)) game

resetPendingTime :: Game -> Game
resetPendingTime game = setGmPendingTime (gmInterval game) game

timeElapse :: Double -> Game -> Game
timeElapse dt game = 
    let real_dt = if gmPaused game then 0 else dt in
    setGmPendingTime (gmPendingTime game - real_dt) game

switchPaused :: Game -> Game
switchPaused game = setGmPaused (not (gmPaused game)) game

multInterval :: Double -> Game -> Game
multInterval factor game =
    let newInterval = gmInterval game * factor
        clampedInterval = max 0.125 newInterval in
    setGmInterval clampedInterval game

-- UI drawing functions

type Control = (String, String)

controls :: [Control]
controls = [
    ("N", "Next Step"),
    ("G", "Change grid mode"),
    ("O", "Zoom out"),
    ("I", "Zoom in"),
    ("ARROWUP", "Shift down"),
    ("ARROWDOWN", "Shift up"),
    ("ARROWRIGHT", "Shift left"),
    ("ARROWLEFT", "Shift right"),
    ("SPACE", "Pause/run toggle"),
    ("+", "Increase run velocity"),
    ("-", "Decrease run velocity"),
    ("Use the mouse to set live/dead cells", "")]

controlsHorizontalOffset = 1.0
controlsVerticalOffset = 1.0
controlsHorizontalSpacing = 6.0
controlsVerticalSpacing = 1.0


drawUserInterface :: Game -> Drawing
drawUserInterface game = drawControls <> drawSettings game

drawControls :: Drawing
drawControls =
    let x = ((-viewWidth) / 2 + controlsHorizontalOffset)
        y = (viewHeight / 2 - controlsVerticalOffset)
        controlsDrawing = foldMap drawControlLine $ zip [0..] controls in
    colored blue $ translated x y controlsDrawing

drawControlLine :: (Int, Control) -> Drawing
drawControlLine (i, (t1, t2)) =
    translated 0.0 (fromIntegral i * (-controlsVerticalSpacing)) (
        ltext t1 <>
        translated controlsHorizontalSpacing 0.0 (ltext t2))

ltext :: String -> Drawing
ltext = atext startAnchor

drawSettings :: Game -> Drawing
drawSettings game =
    let drawing = foldMap drawSetting $ zip [0..] $ getSettingsStrings game
        x = (viewWidth / 2 - controlsHorizontalOffset) 
        y = (viewHeight / 2 - controlsVerticalOffset) in
    colored red $ translated x y drawing

drawSetting :: (Int, String) -> Drawing
drawSetting (i, s) =
    translated 0.0 (fromIntegral i * (-controlsVerticalSpacing)) $ rtext s

getSettingsStrings :: Game -> [String]
getSettingsStrings game = 
    let tps = show (1.0 / (gmInterval game)) 
        paused = if gmPaused game then " (paused)" else ""
        zoom = show (gmZoom game)
        shift_x = show (fst (gmShift game))
        shift_y = show (snd (gmShift game)) in [
            tps ++ " steps per second" ++ paused,
            "Zoom = " ++ zoom,
            "Shift - (" ++ shift_x ++ ", " ++ shift_y ++ ")"]
            
rtext :: String -> Drawing
rtext = atext endAnchor
