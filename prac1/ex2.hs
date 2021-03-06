import Drawing

lightBulb :: Color -> Double -> Drawing
lightBulb c y = colored c $ translated 0 y $ solidCircle 1

semafore :: Drawing
semafore = solidRectangle 3 8 <>
            lightBulb red 2.5 <>
            lightBulb yellow 0 <>
            lightBulb green (-2.5)

main :: IO ()
main = svgOf (coordinatePlane <> semafore)
