import Drawing

lightBulb :: Color -> Double -> Drawing
lightBulb c y = colored c $ translated 0 y $ solidCircle 1

myDrawing :: Drawing
myDrawing = rectangle 3 8 <>
            lightBulb red 2.5 <>
            lightBulb yellow 0 <>
            lightBulb green (-2.5)

main :: IO ()
main = svgOf (myDrawing <> coordinatePlane)
