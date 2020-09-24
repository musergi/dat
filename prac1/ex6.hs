import Drawing

lightBulb :: Color -> Double -> Drawing
lightBulb c y = colored c $ translated 0 y $ solidCircle 1

trafficLight :: Drawing
trafficLight = lightBulb red 2.5 <>
            lightBulb yellow 0 <>
            lightBulb green (-2.5) <>
            solidRectangle 3 8

light :: (Double, Double) -> Drawing
light (x, y) = translated x y trafficLight

trafficLights :: [(Double, Double)] -> Drawing
trafficLights p = foldMap light p

myDrawing :: Drawing
myDrawing = trafficLights [
    ((-4), 9), (0, 9), (4, 9),
    ((-4), 0), (0, 0), (4, 0),
    ((-4), (-9)), (0, (-9)), (4, (-9))]

main :: IO ()
main = svgOf (myDrawing <> coordinatePlane)
