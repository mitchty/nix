;; Note since emacs byte compilation loads, use-package macros may not get
;; definitions without these requires and you end up with undefined variables
;; like:
;;Debugger entered--Lisp error: (void-variable personal-keybindings)
(require 'bind-key)
(require 'org)
(require 'use-package)

;; So we don't get flicker on macos/nextstep emacs set this in early init.
(setq use-package-verbose t
      tool-bar-mode -1
      scroll-bar-mode -1)

(when (not (display-graphic-p))
  (menu-bar-mode -1))

(setq-default debug-on-error t)
