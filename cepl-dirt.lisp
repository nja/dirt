;;;; cepl-dirt.lisp

(in-package #:cepl-dirt)

(defun check-formats (format)
  (if (find format '(:rgba :rgb))
      t
      (error "Format must be either :rgb, :rgba or :auto~%Given ~s" format)))

(defun dirt-format-to-cepl-format (format)
  (case format
    (:rgb :uint8-vec3)
    (:rgba :uint8-vec4)))
(defun dirt-format-to-texture-internal (format)
  (case format
    (:rgb :rgb8)
    (:rgba :rgba8)))

(defun load-image (filepath &optional (format :rgba))
  "Load image from disk to c-array"
  (when (check-formats format)
    (destructuring-bind (pointer width height channels)
        (cl-soil:load-image filepath format)
      (values (cgl:make-c-array-from-pointer
               (list width height)
               (dirt-format-to-cepl-format format)
               pointer)
              channels))))

(defun load-image-to-texture (filepath &optional texture (format :rgba))
  (let ((data (load-image filepath format))
        (internal-format (dirt-format-to-texture-internal format)))
    (unwind-protect
         (cond ((typep texture 'null) (cgl:make-texture
                                       data :internal-format internal-format))
               ((typep texture 'cgl:gl-texture) (cgl:gl-push
                                                 (cgl:texref texture) data))
               ((typep texture 'cgl:gpu-array-t) (cgl:gl-push texture data)))
      (cgl:free-c-array data))))
