; C:\CPEN412\ASN6\ASN6B_THREADS\OS_MUTEX.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; file c:\cpen412\asn6\asn6b_threads\os_mutex.c
; line 88
       section   code
       xdef      _OSMutexAccept
_OSMutexAccept:
       link      A6,#0
       move.l    A2,-(A7)
       lea       (null)_UNDEFINED.L,A2
; line 89
; line 89
; line 91
; line 91
       clr.l     (A2)
; line 104
       move.l    (A2),D0
       cmp.l     8(A6),D0
       bne       OSMutexAccept_1
OSMutexAccept_1:
; line 106
       move.l    (A2),D0
       move.l    (A7)+,A2
       unlk      A6
       rts
; line 109
; line 179
       xdef      _OSMutexCreate
_OSMutexCreate:
       link      A6,#0
       movem.l   A2/A3,-(A7)
       lea       (null)_UNDEFINED.L,A2
       lea       _OS_EVENT.L,A3
; line 180
       move.l    (A3),-(A7)
       move.l    _pevent.L,-(A7)
       jsr       LMUL
       move.l    (A7),D0
       addq.w    #8,A7
; line 182
; line 182
       clr.l     (A2)
; line 202
       move.l    (A2),D0
       cmp.l     _OS_PRIO_MUTEX_CEIL_DIS.L,D0
       beq.s     OSMutexCreate_3
; line 203
; line 203
       move.l    _prio.L,D0
       cmp.l     (A2),D0
       blt.s     OSMutexCreate_3
; line 204
; line 204
       move.l    _perr.L,A0
       move.l    (A2),(A0)
; line 205
       move.l    (A3),D0
       bra.s     OSMutexCreate_5
OSMutexCreate_3:
; line 209
       move.l    _OSIntNesting.L,D0
       cmp.l     #0,D0
       bls.s     OSMutexCreate_6
; line 210
; line 210
       move.l    _perr.L,A0
       move.l    (A2)