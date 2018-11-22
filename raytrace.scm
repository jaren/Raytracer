;;; Scheme Recursive Art Contest Entry
;;;
;;; Please do not include your name or personal info in this file.
;;;
;;; Title: <Your title here>
;;;
;;; Description:
;;;   <It's your masterpiece.
;;;    Use these three lines to describe
;;;    its inner meaning.>

; Uncomment for running in racket
(require racket/draw)
(define (screen_width) 500)
(define (screen_height) 500)
(define target (make-bitmap (screen_width) (screen_height)))
(define dc (new bitmap-dc% [bitmap target]))
(define (exitonclick) (send target save-file "output.png" 'png))
(send dc set-pen "" 0 'transparent)
(define (pixel x y color)
  (send dc set-brush color 'solid)
  (send dc draw-rectangle x y x y))
(define (rgb r g b)
  (make-object color%
    (exact-round (exact->inexact (* 255 r)))
    (exact-round (exact->inexact (* 255 g)))
    (exact-round (exact->inexact (* 255 b)))))
(define (reduce func l)
  (if (null? (cdr l))
      (car l)
      (func (car l) (reduce func (cdr l)))))
(define nil '())

; General utils
(define (clamp oldmin oldmax newmin newmax val)
  (+ (* (/ (- val oldmin) (- oldmax oldmin)) (- newmax newmin)) newmin))
(define (min a b)
  (if (< a b)
      a
      b))
(define (max a b)
  (if (< a b)
      b
      a))
(define (ntake list n)
    ; Takes n elements from a list and returns (first-n . remaining)
    (define (iter list n)
      (if (= n 0)
        (cons nil list)
        (let
          ((next (iter (cdr list) (- n 1))))
          (cons
            (cons (car list) (car next))
            (cdr next)))))
    (iter list n))
(define (ngroup list n)
    ; Splits a list into sublists of n elements each
    (if (null? list)
      nil
      (let
        ((take (ntake list n)))
        (cons (car take) (ngroup (cdr take) n)))))
(define (loop-range min-val max-val func)
  ; Basically a for loop
  (func min-val)
  (if (< min-val max-val)
      (loop-range (+ min-val 1) max-val func)
      nil))
(define (zip pairs)
  ; Zips multiple lists together
  ; Returns: list of lists
  (if (null? pairs)
      '(() ())
      (if (null? (car pairs))
          nil
          (cons (map car pairs) (zip (map cdr pairs))))))
(define (list-index l index)
  ; Gets the element of a list at an index
  ; Returns: (index)th element of l
  (if (= 0 index)
      (car l)
      (list-index (cdr l) (- index 1))))
(define (square x) (* x x))

; Vectors
; Vector structure: (x y z)
(define vec-create list)
(define (vec-x vec) (list-index vec 0))
(define (vec-y vec) (list-index vec 1))
(define (vec-z vec) (list-index vec 2))
(define (vec-mul v1 scalar) (map (lambda (x) (* x scalar)) v1))
(define (vec-add v1 v2) (map (lambda (x) (reduce + x)) (zip (list v1 v2))))
(define (vec-sub v1 v2) (vec-add v1 (vec-mul v2 -1)))
(define (vec-dot v1 v2) (reduce + (map (lambda (x) (reduce * x)) (zip (list v1 v2)))))
(define (vec-cross v1 v2) ; Only 3d
  (vec-create
   (- (* (vec-y v1) (vec-z v2)) (* (vec-z v1) (vec-y v2)))
   (- (* (vec-z v1) (vec-x v2)) (* (vec-x v1) (vec-z v2)))
   (- (* (vec-x v1) (vec-y v2)) (* (vec-y v1) (vec-x v2)))))
(define (vec-distsq v1 v2) (reduce + (map (lambda (x) (square (reduce - x))) (zip (list v1 v2)))))
(define (vec-dist v1 v2) (sqrt (vec-distsq v1 v2)))
(define vec-zero (vec-create 0 0 0))
(define (vec-magnitude v1) (vec-dist v1 vec-zero))
(define (vec-normalize v1) (vec-mul v1 (/ 1 (vec-magnitude v1))))
(define (vec-rgb vec) (apply rgb vec))

; Rays
(define (ray-create orig dir) (list orig (vec-normalize dir)))
(define (ray-orig ray) (list-index ray 0))
(define (ray-dir ray) (list-index ray 1))

; Objects
; Object structure: (intersect-function properties color reflection)
; Intersect function: determines whether an object intersects with a ray
;   Returns: ray of phit and nhit
;            nil if no intersection
; Properties: list of object type specific attributes
; Color: vec3 (color)
; Reflection: from 0 to 1, amount reflected
(define object-create list)
(define (object-intersect obj) (list-index obj 0))
(define (object-properties obj) (list-index obj 1))
(define (object-color obj) (list-index obj 2))
(define (object-reflection obj) (list-index obj 3))
; Spheres
; Sphere properties: (radius position)
(define (sphere-create radius vec color reflection)
  (object-create sphere-intersect (list radius vec) color reflection))
(define (sphere-intersect sphere ray)
  (define radius (sphere-radius sphere))
  (define position (sphere-position sphere))
  (define origin (ray-orig ray))
  (define direction (ray-dir ray))
  (define l (vec-sub position origin))
  (define tca (vec-dot l direction))
  (define d2 (- (vec-dot l l) (square tca)))
  (if (> d2 radius)
      nil
      ((lambda () ; Uses lambda because begin in an expression doesn't allow defines in racket
         (define thc (sqrt (- (square radius) d2)))
         (define t0 (- tca thc))
         (define t1 (+ tca thc))
         (define t
           (cond
             ((< t0 0) t1)
             ((< t1 0) t0)
             (else (min t0 t1))))
         (if (< t 0)
             nil
             ((lambda ()
               (define phit (+ origin (* direction t)))
               (define nhit (vec-sub phit position))
               (ray-create phit nhit))))))))
(define (sphere-radius sphere) (list-index (object-properties sphere) 0))
(define (sphere-position sphere) (list-index (object-properties sphere) 1))
; Triangles
; Triangle properties: (p1 p2 p3)
(define (triangle-create p1 p2 p3 color)
  (object-create triangle-intersect (list p1 p2 p3) color))
(define (triangle-intersect triangle ray)
  ; TODO
  #f)
(define (triangle-p1 triangle) (list-index (object-properties triangle) 0))
(define (triangle-p2 triangle) (list-index (object-properties triangle) 1))
(define (triangle-p3 triangle) (list-index (object-properties triangle) 2))
(define (calculate-bbox points)
  ; Finds the smallest bounding box around a set of points, represented as (min max)
  (list
    (vec-create
      (reduce min (map vec-x points))
      (reduce min (map vec-y points))
      (reduce min (map vec-z points)))
    (vec-create
      (reduce max (map vec-x points))
      (reduce max (map vec-y points))
      (reduce max (map vec-z points)))))
(define (bbox-intersect bbox ray)
  ; https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-box-intersection
  ; TODO
  #t)
(define (mesh-create nums color)
  ; Creates a mesh from a list of triangle vertex positions (each triplet is a vec)
  (define points (ntake nums 3))
  (define triangles
    (map
      (lambda (vertices)
        (triangle-create (list-index vertices 0) (list-index vertices 1) (list-index vertices 2) color))
      (ntake points 3)))
  (define bbox (calculate-bbox points))
  (object-create mesh-intersect (list triangles bbox) color))
(define (mesh-intersect mesh ray)
  ; Checks for intersection with bounding box for optimization
  ; If passed, checks for intersection with any of the triangles
  (if (not (bbox-intersect (mesh-bbox mesh) ray))
      nil
      (let
        ((intersect (ray-closest ray (mesh-triangles mesh))))
        (if (null? intersect)
          nil
          (list-index intersect 1)))))
(define (mesh-triangles mesh) (list-index (object-properties mesh) 0))
(define (mesh-bbox mesh) (list-index (object-properties mesh) 1))

; Raytracing
(define (ray-closest ray objects)
  ; Find closest object intersecting with a ray
  ; Returns: (distance^2: number, hit: ray, object: object)
  ; Returns nil if nothing hit
  (reduce
     (lambda (o1 o2)
         (cond
           ((null? o1) o2)
           ((null? o2) o1)
           ((> (list-index o1 0) (list-index o2 0)) o2)
           (else o1)))
     (cons nil (map
      (lambda (object)
        (define intersect ((object-intersect object) object ray))
        (if (null? intersect)
            nil
            (list (vec-distsq (ray-orig intersect) (ray-orig ray)) intersect object)))
      objects))))
(define (get-brightness hit)
  ; Gets brightness as a function of hit position, hit normal, light position, and light intensity
  ; https://www.scratchapixel.com/lessons/3d-basic-rendering/introduction-to-shading/shading-spherical-light
  ; Returns: number from 0 to 1
  (*
    light-intensity
    ;(/ (* 4 pi)                                                                      
    ;(/ (vec-distsq (ray-orig hit) list-pos))                                         ; Inverse square
    (vec-dot (ray-dir hit) (vec-normalize (vec-sub (ray-orig hit) light-pos)))))      ; Angle between nhit and -lightdir
(define (get-reflect lightdir nhit)
  ; Get a reflection direction from a light direction and normal
  ; https://www.scratchapixel.com/lessons/3d-basic-rendering/introduction-to-shading/reflection-refraction-fresnel
  (vec-sub lightdir (vec-mul nhit (* 2 (vec-dot lightdir nhit)))))
(define (ray-trace depth ray)
  ; Traces a ray into the scene
  ; Returns: vec3 (color)
  (if (> depth max-depth)
    (sky-color ray)
    ((lambda ()
      (define closest (ray-closest ray objects))  
      (define hit (list-index closest 1))
      (define phit (ray-orig hit))
      (define nhit (ray-dir hit))
      (cond
        ((null? closest) (sky-color ray))                           ; If no object, use sky color
        ((> (object-reflection closest) 0)                          ; If reflects, recurse with reflection and multiply by reflection amount
          (vec-mul
            (ray-trace (+ depth 1) (ray-create (ray-orig closest) (get-reflect (vec-sub hit light-pos) nhit)))
            (object-reflection closest)))                                               
        (else ((lambda ()                                                ; If object hit, cast shadow ray and calculate brightness if not in shadow
          (define shadow-closest
            (ray-closest (ray-create
              (ray-orig hit)
              (vec-sub light-pos hit))))                            ; TODO: Add bias?
          (if (or                                                   ; If no intersecting object with shadow ray or object is beyond light, illuminate
                (null? shadow-closest)
                (> (square (list-index shadow-closest 0)) (vec-distsq (ray-orig hit) light-pos)))
              (vec-mul (object-color closest) (get-brightness hit))
              vec-zero)))))))))                                         ; Otherwise, black
(define (pixel-trace x y)
  ; Get pixel color at (x, y) by casting rays
  ; Returns: vec3 (color)
  (ray-trace 0 (ray-create
   camera-pos
   (vec-create 0 0 0)))) ; Replace #f with actual ray direction

; Setup
(define pi 3.141592653589793)
(define max-depth 5)
(define camera-pos (vec-create 0 0 2))
(define camera-lookat vec-zero)
(define camera-up (vec-create 0 1 0))
(define camera-fov 45)
(define light-pos (vec-create 0 1 0))
(define light-intensity 1)
(define (sky-color ray)
  vec-zero)
(define encoded-triangles ; Go bEaRs! 💛🐻💙
  '(-1.484681 31.204302 34.082390 -4.657000 18.834000 36.221001 1.611036 28.018562 36.478394-4.657000 18.834000 36.221001 -8.802338 2.144344 33.455635 -1.126192 -3.419684 38.170231-4.657000 18.834000 36.221001 -1.126192 -3.419684 38.170231 1.611036 28.018562 36.478394-7.432120 25.235868 4.101042 -6.179287 19.685888 1.037878 -5.255217 24.236168 4.7568029.185553 -2.071796 12.392843 11.984219 -2.770401 25.621906 9.001225 -6.258841 32.9576874.493389 -3.505280 15.073405 9.185553 -2.071796 12.392843 9.001225 -6.258841 32.9576871.834158 25.688805 0.159938 3.608516 31.380711 2.404709 7.727060 28.221897 0.856680-7.898045 -21.120445 27.630659 -6.105236 -17.728930 31.152744 -4.171048 -16.088728 22.005552-7.046159 -26.464823 29.696983 -7.099590 -21.549801 31.906393 -7.898045 -21.120445 27.630659-7.432120 25.235868 4.101042 -8.938938 21.844803 0.747445 -6.179287 19.685888 1.0378788.894669 22.213018 0.568352 7.727060 28.221897 0.856680 5.537637 24.126274 4.6266162.749910 -29.238297 32.392220 -1.801881 -30.712883 28.994860 2.467273 -29.376026 30.516581-1.801881 -30.712883 28.994860 -3.198527 -28.617718 32.912144 -7.046159 -26.464823 29.696983-1.801881 -30.712883 28.994860 -7.046159 -26.464823 29.696983 -4.230879 -28.835491 26.188507-0.635238 13.785073 11.285372 8.413334 12.993277 15.513279 7.913428 6.677024 16.5911377.013606 6.767942 14.807220 -0.635238 13.785073 11.285372 7.913428 6.677024 16.591137-7.046159 -26.464823 29.696983 -7.898045 -21.120445 27.630659 -6.638173 -23.003172 24.531134-4.230879 -28.835491 26.188507 -7.046159 -26.464823 29.696983 -3.969551 -24.561682 22.691885-3.969551 -24.561682 22.691885 -7.046159 -26.464823 29.696983 -6.638173 -23.003172 24.531134-1.801881 -30.712883 28.994860 -4.230879 -28.835491 26.188507 -1.237524 -34.748291 25.7553734.493389 -3.505280 15.073405 3.005798 -16.558197 22.244383 -2.959815 -0.752676 13.6541123.005798 -16.558197 22.244383 4.493389 -3.505280 15.073405 5.470914 -14.837020 23.6158585.470914 -14.837020 23.615858 4.493389 -3.505280 15.073405 9.001225 -6.258841 32.9576871.611036 28.018562 36.478394 9.634606 20.370308 28.821838 3.541741 33.579082 26.5897068.894669 22.213018 0.568352 5.537637 24.126274 4.626616 6.119787 19.766003 1.2224529.634606 20.370308 28.821838 8.700079 29.983038 19.624762 3.541741 33.579082 26.589706-1.484681 31.204302 34.082390 1.611036 28.018562 36.478394 3.541741 33.579082 26.589706-4.171048 -16.088728 22.005552 1.947252 -24.253481 21.842985 -3.969551 -24.561682 22.6918859.634606 20.370308 28.821838 1.611036 28.018562 36.478394 5.745000 19.430000 35.221001-7.898045 -21.120445 27.630659 -4.171048 -16.088728 22.005552 -6.638173 -23.003172 24.531134-4.171048 -16.088728 22.005552 -3.969551 -24.561682 22.691885 -6.638173 -23.003172 24.5311347.727060 28.221897 0.856680 8.700079 29.983038 19.624762 9.634606 20.370308 28.8218382.328632 21.260309 0.616814 6.119787 19.766003 1.222452 5.537637 24.126274 4.626616-1.484681 31.204302 34.082390 3.541741 33.579082 26.589706 -8.675598 30.621349 25.196724-3.969551 -24.561682 22.691885 -1.709026 -33.572163 23.526108 -4.230879 -28.835491 26.188507-6.251345 6.789930 14.487438 -6.992056 18.764214 14.803025 -0.635238 13.785073 11.285372-9.548964 23.254120 29.225044 -1.484681 31.204302 34.082390 -8.675598 30.621349 25.1967244.493389 -3.505280 15.073405 4.437311 -1.139168 4.162669 9.185553 -2.071796 12.3928437.913428 6.677024 16.591137 10.108561 4.726177 14.141148 7.013606 6.767942 14.80722010.108561 4.726177 14.141148 9.185553 -2.071796 12.392843 9.527778 2.177347 0.815900-4.657000 18.834000 36.221001 -1.484681 31.204302 34.082390 -9.548964 23.254120 29.2250448.894669 22.213018 0.568352 6.119787 19.766003 1.222452 2.328632 21.260309 0.616814-7.192000 -9.592000 32.307999 -12.201250 -3.276955 25.176874 -6.636508 -8.878730 20.3488585.537637 24.126274 4.626616 2.862655 25.812363 4.967522 2.328632 21.260309 0.6168142.862655 25.812363 4.967522 1.834158 25.688805 0.159938 2.328632 21.260309 0.616814-6.727471 -3.309624 13.498251 -7.461477 -1.419544 3.937480 -4.197314 -0.556743 4.2312057.727060 28.221897 0.856680 8.894669 22.213018 0.568352 2.328632 21.260309 0.616814-6.105236 -17.728930 31.152744 -7.192000 -9.592000 32.307999 -6.636508 -8.878730 20.348858-1.268000 -15.890000 36.216999 -1.126192 -3.419684 38.170231 -7.192000 -9.592000 32.3079992.328632 21.260309 0.616814 1.834158 25.688805 0.159938 7.727060 28.221897 0.8566803.750203 5.550569 12.976421 2.568558 1.979944 13.094726 -3.321475 5.391914 13.098011-0.635238 13.785073 11.285372 7.013606 6.767942 14.807220 3.750203 5.550569 12.976421-12.201250 -3.276955 25.176874 -6.727471 -3.309624 13.498251 -6.636508 -8.878730 20.348858-0.635238 13.785073 11.285372 3.750203 5.550569 12.976421 -3.321475 5.391914 13.0980119.335578 -4.656919 1.292057 9.527778 2.177347 0.815900 8.300633 -0.977677 3.257643-6.727471 -3.309624 13.498251 -2.959815 -0.752676 13.654112 -6.636508 -8.878730 20.3488582.568558 1.979944 13.094726 4.493389 -3.505280 15.073405 -2.959815 -0.752676 13.6541123.005798 -16.558197 22.244383 -4.171048 -16.088728 22.005552 -6.636508 -8.878730 20.3488583.005798 -16.558197 22.244383 -6.636508 -8.878730 20.348858 -2.959815 -0.752676 13.654112-6.636508 -8.878730 20.348858 -4.171048 -16.088728 22.005552 -6.105236 -17.728930 31.1527447.673471 -21.092440 27.753307 6.618941 -22.322584 32.498806 7.026054 -25.971077 28.496658-7.461477 -1.419544 3.937480 -9.357018 -4.581838 1.821885 -4.197314 -0.556743 4.231205-6.088196 31.428537 20.126797 3.541741 33.579082 26.589706 3.368739 30.890829 14.790194-6.088196 31.428537 20.126797 3.368739 30.890829 14.790194 -0.168664 26.795916 12.4364317.673471 -21.092440 27.753307 5.470914 -14.837020 23.615858 6.618941 -22.322584 32.498806-9.357018 -4.581838 1.821885 -3.394011 -4.707254 0.580471 -4.197314 -0.556743 4.23120510.108561 4.726177 14.141148 9.527778 2.177347 0.815900 7.013606 6.767942 14.8072209.185553 -2.071796 12.392843 8.300633 -0.977677 3.257643 9.527778 2.177347 0.8159005.729996 5.236123 0.231954 9.527778 2.177347 0.815900 9.335578 -4.656919 1.2920577.013606 6.767942 14.807220 9.527778 2.177347 0.815900 5.729996 5.236123 0.2319545.729996 5.236123 0.231954 3.750203 5.550569 12.976421 7.013606 6.767942 14.807220-3.321475 5.391914 13.098011 2.568558 1.979944 13.094726 -2.959815 -0.752676 13.6541124.437311 -1.139168 4.162669 2.568558 1.979944 13.094726 2.540653 1.894426 0.052413-3.321475 5.391914 13.098011 -2.959815 -0.752676 13.654112 -4.197314 -0.556743 4.231205-6.727471 -3.309624 13.498251 -4.197314 -0.556743 4.231205 -2.959815 -0.752676 13.654112-9.973310 2.851690 0.317673 -6.251345 6.789930 14.487438 -5.766913 5.253135 0.308008-2.816637 2.314441 0.097908 -5.766913 5.253135 0.308008 -6.251345 6.789930 14.487438-2.816637 2.314441 0.097908 -6.251345 6.789930 14.487438 -3.321475 5.391914 13.0980116.618941 -22.322584 32.498806 5.470914 -14.837020 23.615858 5.598054 -16.795719 30.787432-3.321475 5.391914 13.098011 -4.197314 -0.556743 4.231205 -2.816637 2.314441 0.0979085.470914 -14.837020 23.615858 7.673471 -21.092440 27.753307 4.512612 -22.548071 22.498121-9.973310 2.851690 0.317673 -3.394011 -4.707254 0.580471 -7.337488 -5.517896 0.580886-6.088196 31.428537 20.126797 -8.675598 30.621349 25.196724 3.541741 33.579082 26.5897062.568558 1.979944 13.094726 4.437311 -1.139168 4.162669 4.493389 -3.505280 15.073405-9.548964 23.254120 29.225044 -8.675598 30.621349 25.196724 -6.992056 18.764214 14.803025-3.394011 -4.707254 0.580471 -2.816637 2.314441 0.097908 -4.197314 -0.556743 4.2312059.634606 20.370308 28.821838 5.745000 19.430000 35.221001 9.949561 3.404507 27.765171-9.973310 2.851690 0.317673 -5.766913 5.253135 0.308008 -2.816637 2.314441 0.0979083.750203 5.550569 12.976421 5.729996 5.236123 0.231954 2.540653 1.894426 0.0524132.540653 1.894426 0.052413 2.568558 1.979944 13.094726 3.750203 5.550569 12.976421-9.973310 2.851690 0.317673 -2.816637 2.314441 0.097908 -3.394011 -4.707254 0.580471-9.973310 2.851690 0.317673 -9.497246 6.212939 18.214367 -6.251345 6.789930 14.487438-12.201250 -3.276955 25.176874 -9.973310 2.851690 0.317673 -6.727471 -3.309624 13.4982518.300633 -0.977677 3.257643 9.185553 -2.071796 12.392843 4.437311 -1.139168 4.162669-7.461477 -1.419544 3.937480 -6.727471 -3.309624 13.498251 -9.973310 2.851690 0.3176732.749910 -29.238297 32.392220 -3.198527 -28.617718 32.912144 -1.801881 -30.712883 28.9948602.467273 -29.376026 30.516581 7.026054 -25.971077 28.496658 2.749910 -29.238297 32.3922209.335578 -4.656919 1.292057 8.300633 -0.977677 3.257643 4.437311 -1.139168 4.162669-9.973310 2.851690 0.317673 -7.337488 -5.517896 0.580886 -9.357018 -4.581838 1.821885-6.251345 6.789930 14.487438 -0.635238 13.785073 11.285372 -3.321475 5.391914 13.0980119.949561 3.404507 27.765171 5.745000 19.430000 35.221001 9.001225 -6.258841 32.9576875.729996 5.236123 0.231954 9.335578 -4.656919 1.292057 5.853446 -5.894573 0.555271-6.251345 6.789930 14.487438 -9.497246 6.212939 18.214367 -6.992056 18.764214 14.803025-9.973310 2.851690 0.317673 -9.357018 -4.581838 1.821885 -7.461477 -1.419544 3.9374801.823000 -15.287000 36.009998 3.073612 -19.620508 36.406162 5.799738 -18.587830 33.981400-1.126192 -3.419684 38.170231 5.745000 19.430000 35.221001 1.611036 28.018562 36.4783945.729996 5.236123 0.231954 5.853446 -5.894573 0.555271 2.540653 1.894426 0.0524132.540653 1.894426 0.052413 5.853446 -5.894573 0.555271 4.437311 -1.139168 4.1626699.335578 -4.656919 1.292057 4.437311 -1.139168 4.162669 5.853446 -5.894573 0.555271-1.126192 -3.419684 38.170231 -8.802338 2.144344 33.455635 -7.192000 -9.592000 32.3079991.823000 -15.287000 36.009998 -1.126192 -3.419684 38.170231 -1.268000 -15.890000 36.216999-3.986343 -18.089178 35.489517 -1.268000 -15.890000 36.216999 -7.192000 -9.592000 32.307999-1.126192 -3.419684 38.170231 9.001225 -6.258841 32.957687 5.745000 19.430000 35.221001-1.126192 -3.419684 38.170231 1.823000 -15.287000 36.009998 9.001225 -6.258841 32.9576875.883360 -21.588764 37.617104 7.587817 -21.846151 35.879978 5.799738 -18.587830 33.9814003.073612 -19.620508 36.406162 5.883360 -21.588764 37.617104 5.799738 -18.587830 33.981400-6.088196 31.428537 20.126797 -0.168664 26.795916 12.436431 -3.203568 30.760248 2.433594-1.268000 -15.890000 36.216999 3.073612 -19.620508 36.406162 1.823000 -15.287000 36.0099985.598054 -16.795719 30.787432 5.799738 -18.587830 33.981400 7.587817 -21.846151 35.879978-8.675598 30.621349 25.196724 -6.088196 31.428537 20.126797 -7.735860 28.520247 0.301335-7.735860 28.520247 0.301335 -7.432120 25.235868 4.101042 -8.675598 30.621349 25.1967243.387874 -23.262854 36.214340 6.618941 -22.322584 32.498806 5.883360 -21.588764 37.6171045.883360 -21.588764 37.617104 6.618941 -22.322584 32.498806 7.587817 -21.846151 35.8799788.413334 12.993277 15.513279 9.634606 20.370308 28.821838 9.949561 3.404507 27.7651718.413334 12.993277 15.513279 7.825946 19.754818 16.234695 9.634606 20.370308 28.821838-9.357018 -4.581838 1.821885 -7.337488 -5.517896 0.580886 -3.394011 -4.707254 0.5804712.467273 -29.376026 30.516581 -1.237524 -34.748291 25.755373 1.491632 -33.934464 24.0433165.598054 -16.795719 30.787432 7.587817 -21.846151 35.879978 6.618941 -22.322584 32.4988067.026054 -25.971077 28.496658 6.618941 -22.322584 32.498806 3.387874 -23.262854 36.2143402.467273 -29.376026 30.516581 -1.801881 -30.712883 28.994860 -1.237524 -34.748291 25.7553733.073612 -19.620508 36.406162 3.387874 -23.262854 36.214340 5.883360 -21.588764 37.61710410.108561 4.726177 14.141148 9.949561 3.404507 27.765171 11.984219 -2.770401 25.6219069.185553 -2.071796 12.392843 10.108561 4.726177 14.141148 11.984219 -2.770401 25.6219067.026054 -25.971077 28.496658 3.387874 -23.262854 36.214340 2.749910 -29.238297 32.3922203.005798 -16.558197 22.244383 1.947252 -24.253481 21.842985 -4.171048 -16.088728 22.005552-7.432120 25.235868 4.101042 -6.992056 18.764214 14.803025 -8.675598 30.621349 25.1967249.949561 3.404507 27.765171 10.108561 4.726177 14.141148 7.913428 6.677024 16.5911379.949561 3.404507 27.765171 7.913428 6.677024 16.591137 8.413334 12.993277 15.513279-3.986343 -18.089178 35.489517 -7.781418 -20.813440 34.652275 -5.717453 -21.281263 37.4464041.947252 -24.253481 21.842985 4.512612 -22.548071 22.498121 7.026054 -25.971077 28.4966584.512612 -22.548071 22.498121 7.673471 -21.092440 27.753307 7.026054 -25.971077 28.4966581.947252 -24.253481 21.842985 3.005798 -16.558197 22.244383 4.512612 -22.548071 22.498121-7.192000 -9.592000 32.307999 -6.105236 -17.728930 31.152744 -3.986343 -18.089178 35.489517-2.838426 20.122391 12.611211 -5.255217 24.236168 4.756802 -3.139372 25.984171 4.518518-2.838426 20.122391 12.611211 -7.432120 25.235868 4.101042 -5.255217 24.236168 4.7568024.512612 -22.548071 22.498121 3.005798 -16.558197 22.244383 5.470914 -14.837020 23.615858-12.201250 -3.276955 25.176874 -8.802338 2.144344 33.455635 -9.497246 6.212939 18.214367-6.992056 18.764214 14.803025 -2.838426 20.122391 12.611211 -0.635238 13.785073 11.285372-8.802338 2.144344 33.455635 -4.657000 18.834000 36.221001 -9.548964 23.254120 29.225044-3.769217 -23.078768 36.195969 -1.268000 -15.890000 36.216999 -3.986343 -18.089178 35.489517-8.802338 2.144344 33.455635 -12.201250 -3.276955 25.176874 -7.192000 -9.592000 32.307999-8.802338 2.144344 33.455635 -9.548964 23.254120 29.225044 -10.650911 12.062316 25.569427-9.548964 23.254120 29.225044 -6.992056 18.764214 14.803025 -10.650911 12.062316 25.5694273.387874 -23.262854 36.214340 3.073612 -19.620508 36.406162 -1.268000 -15.890000 36.216999-3.769217 -23.078768 36.195969 3.387874 -23.262854 36.214340 -1.268000 -15.890000 36.216999-6.680016 -22.311075 36.510719 -3.769217 -23.078768 36.195969 -5.717453 -21.281263 37.446404-10.650911 12.062316 25.569427 -9.497246 6.212939 18.214367 -8.802338 2.144344 33.455635-3.139372 25.984171 4.518518 -0.168664 26.795916 12.436431 -2.838426 20.122391 12.611211-5.717453 -21.281263 37.446404 -3.769217 -23.078768 36.195969 -3.986343 -18.089178 35.489517-0.168664 26.795916 12.436431 -3.139372 25.984171 4.518518 -3.203568 30.760248 2.433594-7.781418 -20.813440 34.652275 -6.680016 -22.311075 36.510719 -5.717453 -21.281263 37.4464043.461000 -28.247000 24.302000 2.467273 -29.376026 30.516581 1.491632 -33.934464 24.043316-3.203568 30.760248 2.433594 -7.735860 28.520247 0.301335 -6.088196 31.428537 20.1267977.026054 -25.971077 28.496658 2.467273 -29.376026 30.516581 3.461000 -28.247000 24.3020007.026054 -25.971077 28.496658 3.461000 -28.247000 24.302000 1.947252 -24.253481 21.8429851.947252 -24.253481 21.842985 -1.709026 -33.572163 23.526108 -3.969551 -24.561682 22.691885-9.973310 2.851690 0.317673 -12.201250 -3.276955 25.176874 -9.497246 6.212939 18.214367-10.650911 12.062316 25.569427 -6.992056 18.764214 14.803025 -9.497246 6.212939 18.2143679.634606 20.370308 28.821838 7.825946 19.754818 16.234695 7.727060 28.221897 0.8566803.461000 -28.247000 24.302000 1.491632 -33.934464 24.043316 1.947252 -24.253481 21.842985-3.203568 30.760248 2.433594 -3.139372 25.984171 4.518518 -1.977539 25.713514 -0.0422353.368739 30.890829 14.790194 3.541741 33.579082 26.589706 8.700079 29.983038 19.6247621.491632 -33.934464 24.043316 -1.709026 -33.572163 23.526108 1.947252 -24.253481 21.842985-1.977539 25.713514 -0.042235 -7.735860 28.520247 0.301335 -3.203568 30.760248 2.433594-7.046159 -26.464823 29.696983 -3.769217 -23.078768 36.195969 -7.099590 -21.549801 31.906393-7.099590 -21.549801 31.906393 -3.769217 -23.078768 36.195969 -6.680016 -22.311075 36.510719-7.735860 28.520247 0.301335 -6.179287 19.685888 1.037878 -8.938938 21.844803 0.747445-2.404496 20.981260 0.766503 -7.735860 28.520247 0.301335 -1.977539 25.713514 -0.042235-3.986343 -18.089178 35.489517 -6.105236 -17.728930 31.152744 -7.781418 -20.813440 34.652275-7.099590 -21.549801 31.906393 -6.680016 -22.311075 36.510719 -7.781418 -20.813440 34.652275-6.105236 -17.728930 31.152744 -7.099590 -21.549801 31.906393 -7.781418 -20.813440 34.652275-7.735860 28.520247 0.301335 -8.938938 21.844803 0.747445 -7.432120 25.235868 4.101042-7.099590 -21.549801 31.906393 -6.105236 -17.728930 31.152744 -7.898045 -21.120445 27.6306593.387874 -23.262854 36.214340 -3.198527 -28.617718 32.912144 2.749910 -29.238297 32.3922203.387874 -23.262854 36.214340 -3.769217 -23.078768 36.195969 -3.198527 -28.617718 32.912144-3.769217 -23.078768 36.195969 -7.046159 -26.464823 29.696983 -3.198527 -28.617718 32.9121449.949561 3.404507 27.765171 9.001225 -6.258841 32.957687 11.984219 -2.770401 25.6219063.368739 30.890829 14.790194 3.608516 31.380711 2.404709 -0.168664 26.795916 12.436431-7.432120 25.235868 4.101042 -2.838426 20.122391 12.611211 -6.992056 18.764214 14.8030255.470914 -14.837020 23.615858 9.001225 -6.258841 32.957687 5.598054 -16.795719 30.7874329.001225 -6.258841 32.957687 1.823000 -15.287000 36.009998 5.598054 -16.795719 30.7874321.823000 -15.287000 36.009998 5.799738 -18.587830 33.981400 5.598054 -16.795719 30.7874327.825946 19.754818 16.234695 8.413334 12.993277 15.513279 2.265023 20.382215 12.7687918.413334 12.993277 15.513279 -0.635238 13.785073 11.285372 2.265023 20.382215 12.768791-2.838426 20.122391 12.611211 2.265023 20.382215 12.768791 -0.635238 13.785073 11.2853727.825946 19.754818 16.234695 2.265023 20.382215 12.768791 5.537637 24.126274 4.6266165.537637 24.126274 4.626616 2.265023 20.382215 12.768791 2.862655 25.812363 4.967522-2.838426 20.122391 12.611211 -0.168664 26.795916 12.436431 2.265023 20.382215 12.768791-3.139372 25.984171 4.518518 -6.179287 19.685888 1.037878 -2.404496 20.981260 0.7665037.825946 19.754818 16.234695 5.537637 24.126274 4.626616 7.727060 28.221897 0.8566803.368739 30.890829 14.790194 8.700079 29.983038 19.624762 3.608516 31.380711 2.4047093.608516 31.380711 2.404709 8.700079 29.983038 19.624762 7.727060 28.221897 0.856680-2.404496 20.981260 0.766503 -6.179287 19.685888 1.037878 -7.735860 28.520247 0.3013353.608516 31.380711 2.404709 2.862655 25.812363 4.967522 -0.168664 26.795916 12.4364312.862655 25.812363 4.967522 2.265023 20.382215 12.768791 -0.168664 26.795916 12.4364312.862655 25.812363 4.967522 3.608516 31.380711 2.404709 1.834158 25.688805 0.159938-1.977539 25.713514 -0.042235 -3.139372 25.984171 4.518518 -2.404496 20.981260 0.766503-3.139372 25.984171 4.518518 -5.255217 24.236168 4.756802 -6.179287 19.685888 1.037878-4.230879 -28.835491 26.188507 -1.709026 -33.572163 23.526108 -1.237524 -34.748291 25.755373-1.709026 -33.572163 23.526108 1.491632 -33.934464 24.043316 -1.237524 -34.748291 25.755373))
(define objects
  (append
    (list
      (sphere-create 1 (vec-create 0 0 0) (vec-create 1 0 0) 0))
    (mesh-create encoded-triangles (vec-create 0 0 1))))

; Main draw function
(define (draw)
  ; Loops over all the pixels in the image and sets each one's color
  (loop-range 0 (screen_width)
    (lambda (x)
      (loop-range 0 (screen_height)
        (lambda (y)
          (pixel x y (vec-rgb (pixel-trace x y)))))
      (display (quotient (* 100 x) (screen_width)))
      (display "%\n")))
  (exitonclick))

; Please leave this last line alone.  You may add additional procedures above
; this line.
(draw)
