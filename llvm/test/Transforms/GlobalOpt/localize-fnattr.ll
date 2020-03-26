; RUN: opt -S < %s -globalopt | FileCheck %s

declare void @foo1a(i8* readnone nocapture, i8) local_unnamed_addr
declare void @foo1b(i8* nocapture, i8) local_unnamed_addr readnone
declare void @foo1c(i8* nocapture, i8) local_unnamed_addr inaccessiblememonly

@G1 = internal global i32 0

; Doesn't read from pointer argument
define i32 @a() norecurse {
; CHECK-LABEL: @a
; CHECK: alloca
; CHECK-NOT: @G1
; CHECK: }
    store i32 42, i32 *@G1
    %p = bitcast i32* @G1 to i8*
    call void @foo1a(i8* %p, i8 0)
    call void @foo1b(i8* %p, i8 0)
    call void @foo1c(i8* %p, i8 0)
    %a = load i32, i32* @G1
    ret i32 %a
}

declare void @foo2a(i8* readonly nocapture, i8) local_unnamed_addr
declare void @foo2b(i8* nocapture, i8) local_unnamed_addr readonly

@G2 = internal global i32 0

; Reads from pointer argument, 8-bit call/load is less than 32-bit store
define i32 @b() norecurse {
; CHECK-LABEL: @b
; CHECK: alloca
; CHECK-NOT: @G2
; CHECK: }
    store i32 42, i32 *@G2
    %p = bitcast i32* @G2 to i8*
    call void @foo2a(i8* %p, i8 0)
    call void @foo2b(i8* %p, i8 0)
    ret i32 0
}

declare void @foo3a(i32* writeonly nocapture, i8) local_unnamed_addr
declare void @foo3b(i32* nocapture, i8) local_unnamed_addr writeonly
declare void @foo3c(i32* writeonly, i8) local_unnamed_addr writeonly

@G3 = internal global i32 0

; May-write to pointer argument, not supported
define i32 @c() norecurse {
; CHECK-LABEL: @c
; CHECK-NOT: alloca
; CHECK: @G3
; CHECK: }
    call void @foo3a(i32* @G3, i8 0)
    call void @foo3b(i32* @G3, i8 0)
    call void @foo3c(i32* @G3, i8 0)
    %c = load i32, i32* @G3
    ret i32 %c
}

declare void @foo4a(i8* readnone nocapture, i8) local_unnamed_addr
declare void @foo4b(i8* readnone, i8) local_unnamed_addr
declare void @llvm.assume(i1 %cond)

@G4 = internal global i32 0

; Operand bundle and may-capture not supported
define i32 @d() norecurse {
; CHECK-LABEL: @d
; CHECK-NOT: alloca
; CHECK: @G4
; CHECK: }
    store i32 42, i32 *@G4
    call void @llvm.assume(i1 true) ["align"(i32 *@G4, i64 128)]
    %p = bitcast i32* @G4 to i8*
    call void @foo4a(i8* %p, i8 0)
    call void @foo4b(i8* %p, i8 0)
    %d = load i32, i32* @G4
    ret i32 %d
}

declare void @foo5(i32, i8) local_unnamed_addr readnone

@G5 = internal global i32 0

; Doesn't read from casted pointer argument
define i32 @e() norecurse {
; CHECK-LABEL: @e
; CHECK: alloca
; CHECK-NOT: @G5
; CHECK: }
    store i32 42, i32 *@G5
    %p = ptrtoint i32* @G5 to i8
    call void @foo5(i32 ptrtoint (i32* @G5 to i32), i8 %p)
    %e = load i32, i32* @G5
    ret i32 %e
}
