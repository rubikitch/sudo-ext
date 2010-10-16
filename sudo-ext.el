;;;; sudo-ext.el --- minimal sudo wrapper
;; Time-stamp: <2010-10-16 12:49:17 rubikitch>

;; Copyright (C) 2010  rubikitch

;; Author: rubikitch <rubikitch@ruby-lang.org>
;; Keywords: unix
;; URL: http://www.emacswiki.org/cgi-bin/wiki/download/sudo-ext.el

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; 

;;; Commands:
;;
;; Below are complete command list:
;;
;;
;;; Customizable Options:
;;
;; Below are customizable option list:
;;

;;; Installation:
;;
;; Put sudo-ext.el to your load-path.
;; The load-path is usually ~/elisp/.
;; It's set in your ~/.emacs like this:
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;;
;; And the following to your ~/.emacs startup file.
;;
;; (require 'sudo-ext)
;;
;; No need more.

;;; Customize:
;;
;;
;; All of the above can customize by:
;;      M-x customize-group RET sudo-ext RET
;;


;;; History:

;; See http://www.rubyist.net/~rubikitch/gitlog/sudo-ext.txt

;;; Code:

(defvar sudo-ext-version "0.1")
(eval-when-compile (require 'cl))
(defgroup sudo-ext nil
  "sudo-ext"
  :group 'emacs)

(defun sudo-internal (continuation)
  (with-current-buffer (get-buffer-create " *sudo-process*")
    (erase-buffer)
    
    (let ((proc (start-process "sudo" (current-buffer) "sudo" "-v")))
      (lexical-let ((continuation continuation)
                    (return-value 'sudo--undefined))

        (set-process-filter proc 'sudo-v-process-filter)
        (set-process-sentinel
         proc
         (lambda (&rest args) (setq return-value (funcall continuation))))
        (while (eq return-value 'sudo--undefined)
          (sit-for 0.01))
        return-value))))
(defun sudo-v ()
  (sudo-internal 'ignore))

(defun sudo-v-process-filter (proc string)
  (when (string-match "password" string)
    (process-send-string proc (concat (read-passwd "Sudo Password: ") "\n"))))

(defmacro sudo-wrapper (args &rest body)
  `(lexical-let ,(mapcar (lambda (arg) (list arg arg)) args)
     (sudo-internal
      (lambda () ,@body))))
(put 'sudo-wrapper 'lisp-indent-function 1)

(defun sudo-K ()
  (interactive)
  (shell-command-to-string "sudo -K"))

(defun sudoedit (file)
  (interactive "fSudoedit: ")
  (sudo-wrapper (file)
    (start-process "sudoedit" (get-buffer-create " *sudoedit*")
                   "sudoedit" file)))
;; (sudoedit "/etc/fstab")
;; (sudo-K)

(defmacro sudo-advice (func)
  `(defadvice ,func (before sudo-advice activate)
     (when (string-match "\\bsudo\\b" (ad-get-arg 0))
       (sudo-v))))
;; (sudo-K)
;; (shell-command "sudo sh -c 'echo $USER'")
;; (async-shell-command "sudo sh -c 'echo $USER'")
(sudo-advice shell-command)
(sudo-advice async-shell-command)

(provide 'sudo-ext)

;; How to save (DO NOT REMOVE!!)
;; (progn (git-log-upload) (emacswiki-post "sudo-ext.el"))
;;; sudo-ext.el ends here
