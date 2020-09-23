import Drawing

lightBulb :: Color -> Double -> Drawing
lightBulb c y = colored c $ translated 0 y $ solidCircle 1

semafor :: (Double, Double) -> Drawing
semafor (x, y) = translated x y (
          lightBulb red 2.5 <>
          lightBulb yellow 0 <>
          lightBulb green (-2.5) <>
          solidRectangle 3 8)

semafors :: (Double, Double) -> (Int, Int) -> Drawing
semafors (x, y) (w, h) =
    semafor (x, y) <>
    semafors (x + 4.0, y) (w - 1, 1) <>
    semafors (x, y + 9) (w, h - 1)

myDrawing :: Drawing
myDrawing = semafors ((-4.0), (-9.0)) (3, 3)

main :: IO ()
main = svgOf (myDrawing <> coordinatePlane)
