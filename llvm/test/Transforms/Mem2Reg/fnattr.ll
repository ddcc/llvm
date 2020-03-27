; RUN: opt -S < %s -mem2reg | FileCheck %s

declare void @foo1a(i8* readnone nocapture, i8) local_unnamed_addr
declare void @foo1b(i8* nocapture, i8) local_unnamed_addr readnone
declare void @foo1c(i8* nocapture, i8) local_unnamed_addr inaccessiblememonly

; Doesn't read from pointer argument, promotable
define i32 @a() norecurse {
; CHECK-LABEL: @a
; CHECK-NOT: %g1
; CHECK: alloca
; CHECK-NEXT: bitcast
; CHECK: ret i32 42
; CHECK: }
    %g1 = alloca i32
    store i32 42, i32 *%g1
    %p = bitcast i32* %g1 to i8*
    call void @foo1a(i8* %p, i8 0)
    call void @foo1b(i8* %p, i8 0)
    call void @foo1c(i8* %p, i8 0)
    %a = load i32, i32* %g1
    ret i32 %a
}

declare void @foo2a(i8*, i8) local_unnamed_addr readnone
declare void @foo2b(i8* nocapture, i8) local_unnamed_addr

; May-capture and may-read, not promotable
define i32 @b() norecurse {
; CHECK-LABEL: @b
; CHECK: %g2 = alloca
; CHECK: store
; CHECK: load
; CHECK: }
    %g2 = alloca i32
    store i32 42, i32 *%g2
    %p = bitcast i32* %g2 to i8*
    call void @foo2a(i8* %p, i8 0)
    call void @foo2b(i8* %p, i8 0)
    %b = load i32, i32* %g2
    ret i32 %b
}

define i1 @is_aligned(i32* readnone nocapture) norecurse {
    %int = ptrtoint i32* %0 to i64
    %and = and i64 %int, 31
    %cmp = icmp ne i64 %and, 0
    ret i1 %cmp
}

; No non-bitcasts/qualifying calls, not promotable
define i1 @is_stack_aligned() norecurse {
; CHECK-LABEL: @is_stack_aligned
; CHECK: alloca
; CHECK: call
; CHECK: }
    %var = alloca i32, align 4
    %ret = call zeroext i1 @is_aligned(i32* nonnull %var)
    ret i1 %ret
}

define i1 @is_same(i32* readnone, i16* readnone) norecurse {
    %cast = bitcast i16* %1 to i32*
    %cmp = icmp eq i32* %cast, %0
    ret i1 %cmp
}

; No non-bitcasts/qualifying calls, not promotable
define i1 @return_true() norecurse {
; CHECK-LABEL: @return_true
; CHECK: alloca
; CHECK-NEXT: bitcast
; CHECK-NEXT: call
; CHECK: }
    %var = alloca i32, align 4
    %cast = bitcast i32* %var to i16*
    %ret = call zeroext i1 @is_same(i32* nonnull %var, i16* nonnull %cast)
    ret i1 %ret
}

; Bitcast dominates loads/stores, not promotable
define i32 @c() norecurse {
; CHECK-LABEL: @c
; CHECK: alloca
; CHECK: store
; CHECK: load
; CHECK: }
    %var = alloca i32, align 4
    %cast = bitcast i32* %var to i32*
    store i32 42, i32* %cast
    %cast2 = bitcast i32* %var to i16*
    %ret = call zeroext i1 @is_same(i32* nonnull %var, i16* nonnull %cast2)
    %c = load i32, i32* %cast
    ret i32 %c
}

; Bitcast only dominates qualifying calls, promotable
define i32 @d() norecurse {
; CHECK-LABEL: @d
; CHECK: alloca
; CHECK-NEXT: bitcast
; CHECK-NEXT: call
; CHECK: ret i32 42
; CHECK: }
    %var = alloca i32, align 4
    store i32 42, i32* %var
    %cast = bitcast i32* %var to i16*
    %ret = call zeroext i1 @is_same(i32* nonnull %var, i16* nonnull %cast)
    %d = load i32, i32* %var
    ret i32 %d
}
