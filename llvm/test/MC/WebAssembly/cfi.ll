; RUN: llc -O2 -filetype=obj %s -o - | obj2yaml | FileCheck %s

target triple = "wasm32-unknown-unknown"

declare i32 @import1()
declare !absolute_symbol !0 i32 @import2()
declare i32 @import3()

; call the imports to make sure they are included in the imports section
define hidden void @call_imports() {
entry:
  %call1 = call i32 @import1()
  %call3 = call i32 @import3()
  ret void
}

define i32 @define1() !absolute_symbol !1 {
    ret i32 0
}

; take the address of the second import and the first definition. they should be
; placed at indices 1 and 2 in the table.
define hidden void @call_indirect() {
entry:
  %addr_i2 = alloca i32 ()*, align 4
  %addr_d1 = alloca i32 ()*, align 4
  store i32 ()* @import2, i32 ()** %addr_i2, align 4
  store i32 ()* @define1, i32 ()** %addr_d1, align 4
  ret void
}

!0 = !{i64 1, i64 2}
!1 = !{i64 2, i64 3}

; CHECK:  - Type:            ELEM
; CHECK-NEXT:  Segments:
; CHECK-NEXT:    - Offset:
; CHECK-NEXT:        Opcode:          I32_CONST
; CHECK-NEXT:        Value:           1
; CHECK-NEXT:      Functions:       [ 2, 4 ]

; CHECK:  - Type:            CUSTOM
; CHECK-NEXT:    Name:            linking
; CHECK-NEXT:    Version:         2
; CHECK-NEXT:    SymbolTable:
; CHECK:      - Index:           3
; CHECK-NEXT:        Kind:            FUNCTION
; CHECK-NEXT:        Name:            define1
; CHECK-NEXT:        Flags:           [  ]
; CHECK-NEXT:        Function:        4
; CHECK:          - Index:           6
; CHECK-NEXT:        Kind:            FUNCTION
; CHECK-NEXT:        Name:            import2
; CHECK-NEXT:        Flags:           [ UNDEFINED ]
; CHECK-NEXT:        Function:        2
