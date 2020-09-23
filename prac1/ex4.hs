import Drawing

treeDrawing :: Int -> (Double, Double) -> (Double, Double) -> Drawing
treeDrawing 0 (x, y) _ = translated x y $ colored yellow $ solidCircle 0.5
treeDrawing n (x, y) (t, l) = 
    let end = (x + l * (cos t), y + l * (sin t)) in
    treeDrawing (n - 1) end (t + (pi / 12), l) <>
    treeDrawing (n - 1) end (t - (pi / 12), l) <>
    polyline [(x, y), end]

myDrawing :: Drawing
myDrawing = treeDrawing 8 (0.0, 0.0) (pi / 2.0, 2.0)

main :: IO ()
main = svgOf (myDrawing <> coordinatePlane)
