;; Just enough to load the "real" init file
(require 'org)
(require 'use-package)
(setq use-package-verbose t)
(defvar my/init-el (concat user-emacs-directory "readme.el"))


(tool-bar-mode -1)
(scroll-bar-mode -1)
(when (not (window-system))
  (menu-bar-mode -1))

(find-file (concat user-emacs-directory "readme.org"))
(org-babel-tangle)
(load-file my/init-el)
(byte-compile-file my/init-el)
