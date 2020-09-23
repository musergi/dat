import Drawing

lightBulb :: Color -> Double -> Drawing
lightBulb c y = colored c $ translated 0 y $ solidCircle 1

trafficLight :: Drawing
trafficLight = lightBulb red 2.5 <>
            lightBulb yellow 0 <>
            lightBulb green (-2.5) <>
            solidRectangle 3 8

repeatDraw :: (Int -> Drawing) -> Int -> Drawing
repeatDraw thing 0 = blank
repeatDraw thing n = thing n <> repeatDraw thing (n - 1)

light :: Int -> Int -> Drawing
light r c = translated (3 * fromIntegral c - 6) (8 * fromIntegral r - 16) trafficLight

lightRow :: Int -> Drawing
lightRow r = repeatDraw (light r) 3

myDrawing :: Drawing
myDrawing = repeatDraw lightRow 3

main :: IO ()
main = svgOf (myDrawing <> coordinatePlane)
