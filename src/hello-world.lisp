;(in-package :example)
;(hunchentoot:start (make-instance 'hunchentoot:easy-acceptor :port 4242))
;; Utils
;; (defun heroku-getenv (target)
;;   #+ccl (ccl:getenv target)
;;   #+sbcl (sb-posix:getenv target))

;; ;; Database
;; (defvar *database-url* (heroku-getenv "DATABASE_URL"))

;; (defun db-params ()
;;   "Heroku database url format is postgres://username:password@host/database_name.
;; TODO: cleanup code."
;;   (let* ((url (second (cl-ppcre:split "//" *database-url*)))
;; 	 (user (first (cl-ppcre:split ":" (first (cl-ppcre:split "@" url)))))
;; 	 (password (second (cl-ppcre:split ":" (first (cl-ppcre:split "@" url)))))
;; 	 (host (first (cl-ppcre:split "/" (second (cl-ppcre:split "@" url)))))
;; 	 (database (second (cl-ppcre:split "/" (second (cl-ppcre:split "@" url))))))
;;     (list database user password host)))

;; Handlers
(push (hunchentoot:create-folder-dispatcher-and-handler "/static/" "/app/public/")
	 hunchentoot:*dispatch-table*)

(defvar *iberlibro* "http://www.iberlibro.com/servlet/SearchResults")

(defun find-price (div)
  (let (price-str (price 0))
   (stp:do-recursively (elem div)
     (when (and (typep elem 'stp:element)
                (equal (stp:local-name elem) "span")
                (equal (stp:attribute-value elem "class") "price"))
       (setq price-str (stp:data (stp:first-child elem)))
       (setq price (+ price (read-from-string (subseq price-str 4))))))
   price))

;;; http://www.iberlibro.com/servlet/SearchResults?sts=t&tn=lisp+in+small+pieces&x=0&y=0
(defun show-iberlibro-hits (term)
  (let* ((query (list (cons "tn" term)))
         (str (drakma:http-request *iberlibro* :parameters query))
         (document (chtml:parse str (cxml-stp:make-builder))))
    (stp:do-recursively (a document)
      (when (or (and (typep a 'stp:element)
                     (equal (stp:local-name a) "div")
                     (or (equal (stp:attribute-value a "class") "result-addToBasketContainer")
                         (equal (stp:attribute-value a "class") "result-pricing")))
                (and (typep a 'stp:element)
                     (equal (stp:local-name a) "td")
                     (or (equal (stp:attribute-value a "class") "result-addToBasketContainer")
                         (equal (stp:attribute-value a "class") "result-pricing")))
                )
        (return (find-price a))))))

(defvar *books* '("thinking forth" "compiling with continuations" "the scheme programming language"
                  "higher order perl" "lisp in small pieces"))

(hunchentoot:define-easy-handler (hello-sbcl :uri "/") ()
  (cl-who:with-html-output-to-string (s)
    (:html
     (:head
      (:title "Heroku CL Example App"))
     (:body
      (:h1 "Heroku CL Example App")
      (:h1 (dolist (book *books*)
             (cl-who:htm (format s "~a: ~a" book (show-iberlibro-hits book)) :br ) ))
      (:h3 "Using")
      (:ul
       (:li (format s "~A ~A" (lisp-implementation-type) (lisp-implementation-version)))
       (:li (format s "Hunchentoot ~A" hunchentoot::*hunchentoot-version*))
       (:li (format s "CL-WHO")))
      (:div
       (:a :href "static/lisp-glossy.jpg" (:img :src "static/lisp-glossy.jpg" :width 100)))
      (:div
       (:a :href "static/hello.txt" "hello"))
      (:h3 "App Database")
      (:div
       (:pre "SELECT version();"))
      ;; (:div (format s "~A" (postmodern:with-connection (db-params)
      ;;                        (postmodern:query "select version()"))))
      (:div (:p "raimonster@gmail.com"))))))
