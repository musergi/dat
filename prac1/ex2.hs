import Drawing

lightBulb :: Color -> Double -> Drawing
lightBulb c y : colored c $ translated 0 y $ solidCircle 1

myDrawing :: Drawing
myDrawing = lightBulb red 1.5 <>
            lightBulb yellow 0 <>
            lightBulb green -1.5

main :: IO ()
main = svgOf (myDrawing <> coordinatePlane)
