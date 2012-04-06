(asdf:defsystem #:example
  :serial t
  :description "Example cl-heroku application"
  :depends-on (#:hunchentoot
	       #:cl-who
               #:drakma
               #:closure-html
               #:cxml-stp
	       #:postmodern)
  :components ((:file "package")
	       (:module :src
			:serial t
			:components ((:file "hello-world")))))
