import Drawing

treeDrawing :: Int -> Point -> Double -> Drawing
treeDrawing 0 (x, y) _ = translated x y $ colored yellow $ solidCircle 0.5
treeDrawing n (x, y) a = 
    let end = (x + 1.5 * (cos a), y + 1.5 * (sin a)) in
    polyline [(x, y), end] <>
    treeDrawing (n - 1) end (a + (pi / 12)) <>
    treeDrawing (n - 1) end (a - (pi / 12))

myDrawing :: Drawing
myDrawing = treeDrawing 8 (0.0, 0.0) (pi / 2.0)

main :: IO ()
main = svgOf myDrawing
