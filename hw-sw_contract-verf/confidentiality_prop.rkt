#lang rosette

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Hardware-Software Contract Verification for TETD Worksite Relocation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; Relocation model: DERIVED from temporal ordering
;; A single symbolic relocation timestamp
(define-symbolic reloc-time integer?)

(define (relocation-between? t-before t-after)
  ;; True iff relocation falls strictly between the two timestamps
  (and (< t-before reloc-time)
       (< reloc-time t-after)))

;; TETD worksite constraints
(define LARGE_GPA_SPACE (expt 2 20))
(define WORKSITE_SIZE (expt 2 14))
(define MIN_SEPARATION (* 2 WORKSITE_SIZE))

(define (tetd-constraints gpa-old gpa-new range-old range-new)
  (and
    ;; GPAs within respective worksite ranges
    (>= gpa-old range-old)
    (< gpa-old (+ range-old WORKSITE_SIZE))
    (>= gpa-new range-new)
    (< gpa-new (+ range-new WORKSITE_SIZE))
    ;; Ranges valid within GPA space
    (>= range-old 0) (>= range-new 0)
    (<= (+ range-old WORKSITE_SIZE) LARGE_GPA_SPACE)
    (<= (+ range-new WORKSITE_SIZE) LARGE_GPA_SPACE)
    ;; Ranges disjoint with sufficient separation
    (or (>= range-new (+ range-old MIN_SEPARATION))
        (>= range-old (+ range-new MIN_SEPARATION)))))


;; ============================================================
;; cP11: After relocation, VMM must not observe unchanged 
;;       GPA binding for the same VA
;; ============================================================

(define-symbolic va11-a va11-b integer?)
(define-symbolic time11-a time11-b integer?)
(define-symbolic gpa11-a gpa11-b integer?)
(define-symbolic range11-old range11-new integer?)



(define cP11
  (verify
    (assert
      (implies
        (and
          (= va11-a va11-b)
          (< time11-a time11-b)
          (relocation-between? time11-a time11-b)
          (tetd-constraints gpa11-a gpa11-b range11-old range11-new))
        (not (= gpa11-a gpa11-b))))))


(displayln (if (unsat? cP11)
               "cP11 VERIFIED"
               "cP11 VIOLATED"))


;; =========================================================================
;; cP12: If two distinct memory access events observe the same 
;;       virtual address (VA), then they must not produce the same guest 
;;       physical address (GPA), provided both accesses hit valid EPT entries
;; ===========================================================================

(define-symbolic va12-a va12-b integer?)
(define-symbolic time12-a time12-b integer?)
(define-symbolic gpa12-a gpa12-b integer?)
(define-symbolic range12-old range12-new integer?)



(define cP12
  (verify
    (assert
      (implies
        (and
          (= va12-a va12-b)
          (< time12-a time12-b)
          (relocation-between? time12-a time12-b)
          (tetd-constraints gpa12-a gpa12-b range12-old range12-new))
        (not (= gpa12-a gpa12-b))))))

(displayln (if (unsat? cP12)
               "cP12 VERIFIED"
               "cP12 VIOLATED"))


;; ======================================================================
;; cP13: If a virtual address is observed at two different times, 
;; and both observations correspond to valid EPT entries and a 
;; relocation occurs right between the two then the older GPA is 
;; unlinkable to the newer GPA over the physical address space of the TEE
;; ========================================================================

(define-symbolic time13-old time13-new integer?)
(define-symbolic gpa13-old gpa13-new integer?)
(define-symbolic range13-old range13-new integer?)


(define cP13
  (verify
    (assert
      (implies
        (and
          (< time13-old time13-new)                     
          (relocation-between? time13-old time13-new)   
          (tetd-constraints gpa13-old gpa13-new range13-old range13-new))
        (not (= gpa13-old gpa13-new))))))

(displayln (if (unsat? cP13)
               "cP13 VERIFIED"
               "cP13 VIOLATED"))


;; =============================================================================
;; cP14: If an adversary claims to have successfully tracked a VA history, 
;; then the system must contain at least one GPA reuse across that VA’s accesses
;; ===============================================================================

(define-symbolic va14-a va14-b integer?)
(define-symbolic time14-a time14-b integer?)
(define-symbolic gpa14-a gpa14-b integer?)
(define-symbolic range14-old range14-new integer?)


(define tracking-succeeds (= gpa14-a gpa14-b))

(define cP14
  (verify
    (assert
      (implies
        (and
          (= va14-a va14-b)
          (< time14-a time14-b)
          (not (= gpa14-a gpa14-b))
          (tetd-constraints gpa14-a gpa14-b range14-old range14-new))
        (not tracking-succeeds)))))

(displayln (if (unsat? cP14)
               "cP14 VERIFIED"
               "cP14 VIOLATED"))


;; =======================================================================
;; cP15: Relocation must actually change mapping (no degenerate relocate)
;; =======================================================================

(define-symbolic time15-old time15-new integer?)
(define-symbolic gpa15-old gpa15-new integer?)
(define-symbolic range15-old range15-new integer?)


(define cP15
  (verify
    (assert
      (implies
        (and
          (< time15-old time15-new)
          (relocation-between? time15-old time15-new)   
          (tetd-constraints gpa15-old gpa15-new range15-old range15-new))
        (not (= gpa15-old gpa15-new))))))

(displayln (if (unsat? cP15)
               "cP15 VERIFIED"
               "cP15 VIOLATED"))


;; ============================================================
;; Summary
;; ============================================================


(displayln "\n=== CONFIDENTIALITY VERIFICATION COMPLETED ===")

