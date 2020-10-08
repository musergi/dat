import Drawing

lightBulb :: Color -> Double -> Drawing
lightBulb c y = colored c $ translated 0 y $ solidCircle 1

semafor :: Drawing
semafor = solidRectangle 3 8 <>
            lightBulb red 2.5 <>
            lightBulb yellow 0 <>
            lightBulb green (-2.5)

semaforAt :: Point -> Drawing
semaforAt (x, y) = translated x y semafor

semaforGrid :: Point -> (Int, Int) -> Drawing
semaforGrid (_, _) (_, 0) = blank
semaforGrid (_, _) (0,_ ) = blank
semaforGrid (x, y) (w, h) =
    semaforAt (x, y) <>
    semaforGrid (x + 4.0, y) (w - 1, 1) <> -- Rest of the row
    semaforGrid (x, y + 9) (w, h - 1)      -- Row on top

myDrawing :: Drawing
myDrawing = semaforGrid ((-4.0), (-9.0)) (3, 3)

main :: IO ()
main = svgOf (coordinatePlane <> myDrawing)
