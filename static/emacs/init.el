;; Just enough to load the "real" init file
(require 'org)
(require 'use-package)
(defvar my/init-el (concat user-emacs-directory "readme.el"))

(find-file (concat user-emacs-directory "readme.org"))
(org-babel-tangle)
(load-file my/init-el)
(byte-compile-file my/init-el)
