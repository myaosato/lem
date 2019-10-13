(in-package :lem-tests.lisp-indent)

(defmacro define-indent-test (name before after)
  `(defun ,name ()
     (run-indent-test ',name ,before ,after)))

(define-indent-test cond-1
"
(cond ((foo 1
2)))
"
"
(cond ((foo 1
            2)))
")

(define-indent-test defclass-1
"
`(defclass foo ()
,(mapcar x
y))"
"
`(defclass foo ()
   ,(mapcar x
            y))
")

(defun indent-line (p)
  (let ((indent (lem-lisp-syntax:calc-indent p)))
    (lem:back-to-indentation p)
    (lem:with-point ((start p))
      (lem:line-start start)
      (lem:delete-between-points start p))
    (lem:insert-string p (make-string indent :initial-element #\space))))

(defun indent-buffer (buffer)
  (lem:with-point ((p (lem:buffer-point buffer)))
    (lem:buffer-start p)
    (loop
      (indent-line p)
      (unless (lem:line-offset p 1)
        (return)))))

(define-condition test-error (simple-error)
  ((description
    :initarg :description
    :reader test-error-description))
  (:report (lambda (condition stream)
             (write-line (test-error-description condition) stream))))

(defmacro test (form description)
  `(unless ,form
     (cerror "skip" (make-condition 'test-error
                                    :description ,description))))

(defun run-indent-test (name before-text after-text)
  (let ((buffer (lem:make-buffer (format nil "*indent-test ~A*" name)
                                 :syntax-table lem-lisp-syntax:*syntax-table*)))
    (lem:erase-buffer buffer)
    (lem:with-point ((p (lem:buffer-point buffer)))
      (lem:insert-string p before-text))
    (indent-buffer buffer)
    (test (string= after-text (lem:buffer-text buffer))
          (format nil "# error: ~A~%actual: ~S~%expected: ~S~%"
                  name
                  (lem:buffer-text buffer)
                  after-text))))

(defun run-test (test-fn)
  (handler-bind ((test-error (lambda (e)
                               (format t "~&~A~%" e)
                               (invoke-restart 'continue))))
    (funcall test-fn)))