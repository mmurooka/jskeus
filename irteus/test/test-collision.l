(require :unittest "lib/llib/unittest.l")
(init-unit-test)

(defun test-collision-sphere-analytical
    ()
  (let* ((radius1 100)
         (radius2 200)
         (obj1 (make-sphere radius1))
         (obj2 (make-sphere radius2))
         (cnt 0)
         (dist)
         (analy-dist)
         (ret)
         )
    (send obj1 :set-color (float-vector 1 0 0) 0.5)
    (send obj2 :set-color (float-vector 0 1 0) 0.4)
    (objects (list obj1 obj2))
    (do-until-key
     ;; move object
     (incf cnt)
     (send obj1 :newcoords (make-coords :pos (float-vector (* 500.0 (sin (/ cnt 20.0))) 50 0)))
     (send *irtviewer* :draw-objects)
     ;; get bullet distance
     (setq ret (collision-distance obj1 obj2))
     (setq dist (elt ret 0))
     ;; get analytical distance and compare
     (setq analy-dist (- (norm (send obj1 :worldpos)) (+ radius1 radius2)))
     (cond ((eq *collision-algorithm* *collision-algorithm-pqp*)
            ;; very large tolerance for pqp algorithm because
            ;; 1) pqp does not return correct collision distance when collision occurs.
            ;; 2) pqp does not return correct collision detection (i.e., 0 or 1 detection) when if one object is completely contained in the other object.
            ;; 3) euspqp.c and CPQP.c do not treat euslisp sphere model as sphere but treat as polyhedron mesh.
            (assert (eps= dist analy-dist 1e3))
            )
           ((eq *collision-algorithm* *collision-algorithm-bullet*)
            (assert (eps= dist analy-dist 1e-3))
            )
           (t
            (error "invalid collision algorithm: ~a~%" *collision-algorithm*)
            ))
     ;; draw
     (send (elt ret 1) :draw-on :flush nil :width 16 :size 50 :color (float-vector 1 0.4 0.4))
     (send (elt ret 2) :draw-on :flush nil :width 16 :size 50 :color (float-vector 0.4 1 0.4))
     (send (make-line (elt ret 1) (elt ret 2)) :draw-on :flush nil
           :width 8 :color (if (> (elt ret 0) 0) (float-vector 0 1 1) (float-vector 1 1 0)))
     (send *irtviewer* :viewer :flush)
     (unix::usleep (* 20 1000))
     (when (> cnt 100)
       (return-from nil nil))
     )
    ))

(deftest test-collision-sphere-analytical-pqp
  (select-collision-algorithm *collision-algorithm-pqp*)
  (test-collision-sphere-analytical)
  )

(deftest test-collision-sphere-analytical-bullet
  (select-collision-algorithm *collision-algorithm-bullet*)
  (test-collision-sphere-analytical)
  )

(defun test-collision-object-approx
    (obj1 obj2)
  (let* ((bbox-radius1
          (norm (v- (send (send obj1 :box) :center) (send (send obj1 :box) :maxpoint))))
         (bbox-radius2
          (norm (v- (send (send obj2 :box) :center) (send (send obj2 :box) :maxpoint))))
         (cnt 0)
         (dist)
         (approx-dist-min)
         (approx-dist-max)
         (ret)
         )
    (send obj1 :set-color (float-vector 1 0 0) 0.5)
    (send obj2 :set-color (float-vector 0 1 0) 0.4)
    (objects (list obj1 obj2))
    (do-until-key
     ;; move object
     (incf cnt)
     (send obj1 :newcoords
           (make-coords :pos (float-vector (* 750.0 (sin (/ cnt 20.0))) 50 0)
                        :rpy (list (* pi (sin (/ cnt 200.0))) (+ (* pi (sin (/ cnt 400.0))) pi/2) 0)))
     (send *irtviewer* :draw-objects)
     ;; get bullet distance
     (setq ret (collision-distance obj1 obj2))
     (setq dist (elt ret 0))
     ;; get approximate distance and compare
     (setq approx-dist-max
           (norm (v- (send (send obj1 :box) :center) (send (send obj2 :box) :center))))
     (setq approx-dist-min
           (- approx-dist-max (+ bbox-radius1 bbox-radius2)))
     ;; (format t "[result: ~a] ~a < ~a < ~a~%"
     ;;         (< approx-dist-min dist approx-dist-max)
     ;;         approx-dist-min dist approx-dist-max)
     (assert (< approx-dist-min dist approx-dist-max))
     ;; draw
     (send (elt ret 1) :draw-on :flush nil :width 16 :size 50 :color (float-vector 1 0.4 0.4))
     (send (elt ret 2) :draw-on :flush nil :width 16 :size 50 :color (float-vector 0.4 1 0.4))
     (send (make-line (elt ret 1) (elt ret 2)) :draw-on :flush nil
           :width 8 :color (if (> (elt ret 0) 0) (float-vector 0 1 1) (float-vector 1 1 0)))
     (send *irtviewer* :viewer :flush)
     (unix::usleep (* 20 1000))
     (when (> cnt 100)
       (return-from nil nil))
     )
    ))

(deftest test-collision-cube-approx-pqp
  (select-collision-algorithm *collision-algorithm-pqp*)
  (test-collision-object-approx
   (make-cube 100 150 200) (make-cube 200 200 300))
  )

(deftest test-collision-cube-approx-bullet
  (select-collision-algorithm *collision-algorithm-bullet*)
  (test-collision-object-approx
   (make-cube 100 150 200) (make-cube 200 200 300))
  )

(deftest test-collision-cylinder-approx-pqp
  (select-collision-algorithm *collision-algorithm-pqp*)
  (test-collision-object-approx
   (make-cylinder 100 200) (make-cube 200 200 300))
  )

(deftest test-collision-cylinder-approx-bullet
  (select-collision-algorithm *collision-algorithm-bullet*)
  (test-collision-object-approx
   (make-cylinder 100 200) (make-cube 200 200 300))
  )

(deftest test-collision-mesh-approx-pqp
  (select-collision-algorithm *collision-algorithm-pqp*)
  (test-collision-object-approx
   (make-cone (float-vector 0 0 200) (list (float-vector -200 -200 0) (float-vector 200 -200 0) (float-vector 0 250 0))) ;; cone is treated as mesh
   (make-cube 200 200 300))
  )

(deftest test-collision-mesh-approx-bullet
  (select-collision-algorithm *collision-algorithm-bullet*)
  (test-collision-object-approx
   (make-cone (float-vector 0 0 200) (list (float-vector -200 -200 0) (float-vector 200 -200 0) (float-vector 0 250 0))) ;; cone is treated as mesh
   (make-cube 200 200 300))
  )

(eval-when (load eval)
  (run-all-tests)
  (exit 0))