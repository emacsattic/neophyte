;;; NEOPHYTE.EL --- Makes it easier to learn emacs

;; Copyright (C) 1995 Alan Shutko <ats@hubert.wustl.edu>

;; Author: Alan Shutko <ats@hubert.wustl.edu>
;; Maintainer: Alan Shutko <ats@hubert.wustl.edu>
;; Created: Thu Jun 29 1995
;; Version: $Revision: 2.5 $
;; Keywords: help learn

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 1, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; A copy of the GNU General Public License can be obtained from this
;; program's author (send electronic mail to Alan Shutko
;; <ats@hubert.wustl.edu>) or from the Free Software Foundation, Inc.,
;; 675 Mass Ave, Cambridge, MA 02139, USA.
;;

;;; LCD Archive Entry:
;; neophyte|Alan Shutko|ats@hubert.wustl.edu
;; |Makes it easier to learn emacs
;; |$Date: 1996/03/28 20:34:55 $|$Revision: 2.5 $|

;;; Installation:
;; 
;; To install, put
;; (autoload 'neophyte-mode "neophyte")
;; in the site setup and 
;; (neophyte-mode)
;; in the .emacs of whoever needs it.

;; This package requires tmm.el, included with emacs 19.29 and
;; available from ftp://hubert.wustl.edu/pub/elisp/tmm.el .

;;; Commentary:
;; 
;; I created this mode to address a concern that emacs was "*very
;; hard*" to learn and use.  I personally think *very hard* is an
;; exaggeration, but there is a perception that emacs makes no
;; concessions to a novice user.  I created this mode to make things
;; easier.

;; First, it pops up a quick key reference buffer.  This will help
;; people access the tutorial and tell them how to quit, always a
;; tough thing for a new user.  Second, it will redefine M-x to show
;; the key (if any) a command is bound to as you use it.  Lastly, it
;; does some terminal specific things to make things nicer.  Under X,
;; we set up s-region and transient-mark mode.  Under ttys, we set up
;; tmm-menubar to make the menus accessible to users.

;; It also makes use of the Helper functions to make (most) help
;; functions more useful.

;; This code is not finished and I would like any comments on making
;; emacs easier to learn.  I want to help people learn emacs, so
;; suggestions like remapping all the keys and eliminating all buffer
;; changing commands will fall on deaf ears.
;; 
;; The latest version of this code is available from
;; ftp://hubert.wustl.edu/pub/elisp .

;; TODO
;; * Make it easier for novice to make menus
;; * help buffer ala Jed, but context sensitive
;; * Configuration package
;; * AI-like tips during work
;; * Change to using advice

;; For release 2.x:
;; * Start neophyte-configurator.  Support font-lock and common hooks.

;;; Changelog
;; $Log: neophyte.el,v $
;; Revision 2.5  1996/03/28  20:34:55  ats
;; Commented some stuff out which is duplicated under 19.30.  Will later
;; do a better job of merging.
;;
;; Revision 2.4  1995/07/22  22:18:37  ats
;; Fix formatting.
;;
;; Revision 2.3  1995/07/22  22:11:42  ats
;; Changed keywords to fit finder.el.  Fixed formatting of Key Summary.
;;
;; Revision 2.2  1995/07/22  21:59:19  ats
;; Fixed bug in turning off neophyte-mode.  Fixed typos in the key
;; summary.  Advised help functions ala Helper mode.
;;
;; Revision 2.1  1995/07/03  05:04:56  ats
;; Added specific goals for 2.x release.
;;
;; Revision 2.0  1995/07/03  04:45:06  ats
;; Changed TODO.  Changed version number to 2.0 for preparation for next
;; release.
;;
;; Revision 1.7  1995/07/02  08:35:32  ats
;; Added place to get tmm.el.
;;
;; Revision 1.6  1995/07/01  10:32:05  ats
;; Public Release
;;
;; Created code for static key reference.  Added commentary.  Added
;; mention of tmm.el.  Added a map for C-c m in X to tell the user to
;; look at the normal X menus.
;;
;; Revision 1.5  1995/06/30  06:36:03  ats
;; Added some commentary on installation.
;;
;; Revision 1.4  1995/06/30  06:30:41  ats
;; Many changes for beta release.  Supports different setups for X and
;; ttys.  Uses minor-mode modeline variables and keymaps.  Added the
;; delay into neophyte-execute-extended-command.
;;

;;; Code:

(defconst neophyte-version (substring "$Revision: 2.5 $" 11 -2)
  "$Id: neophyte.el,v 2.5 1996/03/28 20:34:55 ats Exp $

Report bugs to: Alan Shutko <ats@hubert.wustl.edu>")

(require 'advice)
(require 'helper)

;(defvar neophyte-extended-command-delay -1
;"*Seconds to wait during neophyte-execute-extended-command

;If neophyte-extended-command-delay is negative, show the key the command
;is bound to before executing it.  Otherwise, show the key afterwards.")

(defun neophyte-version () (interactive) 
  (message "Neophyte version %s" neophyte-version))

(defvar neophyte-saved-suggest suggest-key-bindings
  "Saved value of `suggest-key-bindings' prior to neophyte-mode")

(defvar neophyte-mode nil)
(defun neophyte-mode (&optional arg)
  "Toggle neophyte mode.
With arg, turn neophyte mode on if and only if arg is positive.
Neophyte mode is a minor mode which makes it easier to pick up 
Emacs.  Under X, it makes selected regions visible.  Under a
normal text terminal, it makes the menus accessible by hitting
C-c m.  Under both X and ttys, it will tell you what key a 
command is bound to when you M-x the command."
  (interactive "P")
  (let ((on-p (if arg (> (prefix-numeric-value arg) 0) (not neophyte-mode))))
    (set 'neophyte-mode on-p)
    (if (equal window-system 'x)
	(neophyte-setup-x on-p)
      (neophyte-setup-tty on-p))
    (if on-p
	(neophyte-create-help-buffer)
      (if (get-buffer-window "*Key Summary*")
	  (delete-window (get-buffer-window "*Key Summary*"))))))

(defun neophyte-create-help-buffer ()
  "Emacs keybindings:  `C-' means to use Ctrl key (e.g., C-x = Ctrl-x).
Press `M-` (ESC `)' for simple menus.
C-xC-c exit     C-V  PageDn C-x u Undo     C-xC-s save file   C-a beg of line
   C-l redraw ESC V  PageUp C-h t tutorial C-xC-f open a file C-e end of line"
  (save-excursion
    (set-buffer (get-buffer-create "*Key Summary*"))
    (set 'buffer-read-only nil)
    (if (not (equal (buffer-string) ;Check if buffer has been changed
		    (documentation 'neophyte-create-help-buffer)))
	(progn (erase-buffer)
	       (insert-string (documentation 'neophyte-create-help-buffer))))
    (if (get-buffer-window "*Key Summary*")
	(set 'buffer-read-only t)
      (set-window-buffer (split-window-vertically (- (window-height) 5)) 
			 "*Key Summary*")
      (set 'buffer-read-only t))))

;; Thanks to calc 2.02c for showing me how!
;(defun neophyte-execute-extended-command (n)
;  "Read function name, call it, and show what key it is bound to.
;Shows any keys the function is bound to with a delay specified in 
;neophyte-whereis-delay."
;  (interactive "P")
;  (let* ((prompt (concat (neophyte-num-prefix-name n) "M-x "))
;	 (cmd (intern (completing-read prompt obarray 'commandp t ""))))
;    (if (< neophyte-extended-command-delay 0)
;	(progn (where-is cmd)
;	       (sleep-for (- 0 neophyte-extended-command-delay))
;	       (setq prefix-arg n)
;	       (command-execute cmd))
;      (setq prefix-arg n)
;      (command-execute cmd)
;      (sleep-for neophyte-extended-command-delay)
;      (where-is cmd))))

;(defun neophyte-num-prefix-name (n)
;  (cond ((eq n '-) "- ")
;	((equal n '(4)) "C-u ")
;	((consp n) (format "%d " (car n)))
;	((integerp n) (format "%d " n))
;	(t "")))

(defun neophyte-setup-tty (arg)
  (if arg
      (neophyte-setup-generic t)
    (neophyte-setup-generic nil)))

(defun neophyte-setup-x (arg)
  (if arg
      (progn (transient-mark-mode 1)
	     (neophyte-setup-generic t))
    (transient-mark-mode 0)
    (neophyte-setup-generic nil)))

(defun neophyte-setup-generic (arg)
  (if arg
      (progn (ad-activate-regexp "^neophyte-")
	     (setq neophyte-saved-suggest suggest-key-bindings
		   suggest-key-bindings t))
    (ad-deactivate-regexp "^neophyte-")
    (setq suggest-key-bindings neophyte-saved-suggest)))

(defun neophyte-menu-x ()
  (interactive)
  (message "Use the normal X menus."))

(defvar neophyte-mode-map (make-sparse-keymap))

;(if (equal window-system 'x)
;    (progn (require 's-region)
;	   (define-key neophyte-mode-map "\C-cm" 'neophyte-menu-x))
;  (require 'tmm)
;  (define-key neophyte-mode-map "\C-cm" 'tmm-menubar)
;  )

;(define-key neophyte-mode-map "\M-x" 'neophyte-execute-extended-command)

;; Help routines
(defun neophyte-help-scroller (buffer)
  (let ((blurb (or (and (boundp 'Helper-return-blurb)
			Helper-return-blurb)
		   "return")))
    (save-window-excursion
      (goto-char (window-start (selected-window)))
      (if (get-buffer-window buffer)
	  (pop-to-buffer buffer)
	(switch-to-buffer buffer))
      (goto-char (point-min))
      (let ((continue t) state)
	(while continue
	  (setq state (+ (* 2 (if (pos-visible-in-window-p (point-max)) 1 0))
			 (if (pos-visible-in-window-p (point-min)) 1 0)))
	  (message
	    (nth state
		 '("Space forward, Delete back. Other keys %s"
		   "Space scrolls forward. Other keys %s"
		   "Delete scrolls back. Other keys %s"
		   "Type anything to %s"))
	    blurb)
	  (setq continue (read-char))
	  (cond ((and (memq continue '(?\ ?\C-v)) (< state 2))
		 (scroll-up))
		((= continue ?\C-l)
		 (recenter))
		((and (= continue ?\177) (zerop (% state 2)))
		 (scroll-down))
		(t (setq continue nil))))))))

(defadvice describe-bindings (around neophyte-describe-bindings)
  (save-window-excursion 
    ad-do-it)
  (neophyte-help-scroller "*Help*"))

(defadvice describe-function (around neophyte-describe-function)
  (save-window-excursion 
    ad-do-it)
  (neophyte-help-scroller "*Help*"))

(defadvice describe-key (around neophyte-describe-key)
  (save-window-excursion 
    ad-do-it)
  (neophyte-help-scroller "*Help*"))

(defadvice describe-mode (around neophyte-describe-mode)
  (save-window-excursion 
    ad-do-it)
  (neophyte-help-scroller "*Help*"))

(defadvice describe-variable (around neophyte-describe-variable)
  (save-window-excursion 
    ad-do-it)
  (neophyte-help-scroller "*Help*"))

(defadvice command-apropos (around neophyte-help-command-apropos )
  (save-window-excursion 
    ad-do-it)
  (neophyte-help-scroller "*Help*"))

(defadvice view-emacs-FAQ (around neophyte-view-emacs-FAQ)
  (save-window-excursion 
    ad-do-it)
  (neophyte-help-scroller "FAQ"))
  
(defadvice view-lossage (around neophyte-view-lossage)
  (save-window-excursion 
    ad-do-it)
  (neophyte-help-scroller "*Help*"))

(defadvice view-emacs-news (around neophyte-view-emacs-news)
  (save-window-excursion 
    ad-do-it)
  (neophyte-help-scroller "NEWS"))

(defadvice describe-keyword (around neophyte-describe-keyword)
  (save-window-excursion 
    ad-do-it)
  (neophyte-help-scroller "*Help*"))

(defadvice describe-copying (around neophyte-describe-copying)
  (save-window-excursion 
    ad-do-it)
  (neophyte-help-scroller "COPYING"))

(defadvice describe-distribution (around neophyte-describe-distribution)
  (save-window-excursion 
    ad-do-it)
  (neophyte-help-scroller "DISTRIB"))

(defadvice view-emacs-news (around neophyte-view-emacs-news)
  (save-window-excursion 
    ad-do-it)
  (neophyte-help-scroller "NEWS"))
 
(defadvice describe-project (around neophyte-describe-project)
  (save-window-excursion 
    ad-do-it)
  (neophyte-help-scroller "GNU"))

(defadvice describe-no-warranty (around neophyte-describe-no-warranty)
  (save-window-excursion 
    ad-do-it)
  (neophyte-help-scroller "COPYING"))

;; Add neophyte mode to minor-mode-alist
(or (assq 'neophyte-mode minor-mode-alist)
    (setq minor-mode-alist
	  (cons (list 'neophyte-mode 
		      (if (equal window-system 'x)
			  " Neophyte"
			" (C-c m for Menu)"))
		minor-mode-alist)))

;; Add the minor-mode keymaps
(or (assq 'neophyte-mode-map minor-mode-map-alist)
    (setq minor-mode-map-alist
	  (cons (cons 'neophyte-mode neophyte-mode-map) minor-mode-map-alist)))

(provide 'neophyte)
;;; NEOPHYTE.EL ends here
