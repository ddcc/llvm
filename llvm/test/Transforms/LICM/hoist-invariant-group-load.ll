; RUN: opt -licm -disable-basicaa -S < %s | FileCheck %s

%struct.A = type { i32 (...)** }

; CHECK-LABEL: @hoist(
define void @hoist(%struct.A*  %arg) {
entry:
  br i1 undef, label %while.end, label %while.body.lr.ph

; CHECK: while.body.lr.ph:
while.body.lr.ph:                                 ; preds = %entry
; CHECK:    [[VTABLE:%.*]] = load void (%struct.A*)**, void (%struct.A*)*** [[B:%.*]], align 8, !invariant.group
; CHECK-NEXT:    [[TMP:%.*]] = load void (%struct.A*)*, void (%struct.A*)** [[VTABLE]], align 8, !invariant.load
; CHECK-NEXT:    br label [[WHILE_BODY:%.*]]
  %b = bitcast %struct.A* %arg to void (%struct.A*)***
  br label %while.body

while.body:                                       ; preds = %while.body, %while.body.lr.ph
; CHECK:       while.body:

  %vtable = load void (%struct.A*)**, void (%struct.A*)*** %b, align 8, !invariant.group !1
  %tmp = load void (%struct.A*)*, void (%struct.A*)** %vtable, align 8, !invariant.load !1
  tail call void %tmp(%struct.A* %arg)
  %call = tail call i32 @bar()
  %tobool = icmp eq i32 %call, 0
  br i1 %tobool, label %while.end.loopexit, label %while.body

while.end.loopexit:                               ; preds = %while.body
  br label %while.end

while.end:                                        ; preds = %while.end.loopexit, %entry
  ret void
}

; CHECK-LABEL: @hoist2(
define void @hoist2(i8** %arg) {
entry:
  %call1 = tail call i32 @bar()
  %tobool2 = icmp eq i32 %call1, 0
  br i1 %tobool2, label %while.end, label %while.body.lr.ph

while.body.lr.ph:                                 ; preds = %entry
; CHECK:       while.body.lr.ph:
; CHECK-NEXT:    [[X:%.*]] = load i8*, i8** [[ARG:%.*]], align 8, !invariant.group
; CHECK-NEXT:    br label [[WHILE_BODY:%.*]]
  br label %while.body

; CHECK:       while.body:
while.body:                                       ; preds = %while.body, %while.body.lr.ph
  %x = load i8*, i8** %arg, align 8, !invariant.group !1
  call void @foo(i8* %x)
  %call = tail call i32 @bar()
  %tobool = icmp eq i32 %call, 0
  br i1 %tobool, label %while.end.loopexit, label %while.body

while.end.loopexit:                               ; preds = %while.body
  br label %while.end

while.end:                                        ; preds = %while.end.loopexit, %entry
  ret void
}

declare void @foo(i8*)

declare i32 @bar()

; CHECK-LABEL: @dontHoist(
define void @dontHoist(%struct.A** %a) {

entry:
  %call4 = tail call i32 @bar()
  %cmp5 = icmp sgt i32 %call4, 0
  br i1 %cmp5, label %for.body.preheader, label %for.cond.cleanup

for.body.preheader:                               ; preds = %entry
  br label %for.body

for.cond.cleanup.loopexit:                        ; preds = %for.body
  br label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond.cleanup.loopexit, %entry
  ret void

; CHECK:       for.body:
for.body:
; CHECK:    [[VTABLE:%.*]] = load void (%struct.A*)**, void (%struct.A*)*** {{.*}}, align 8, !dereferenceable !{{.*}}, !invariant.group
; CHECK-NEXT:    [[TMP2:%.*]] = load void (%struct.A*)*, void (%struct.A*)** [[VTABLE]], align 8, !invariant.load
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ 0, %for.body.preheader ]
  %arrayidx = getelementptr inbounds %struct.A*, %struct.A** %a, i64 %indvars.iv
  %tmp = load %struct.A*, %struct.A** %arrayidx, align 8
  %tmp1 = bitcast %struct.A* %tmp to void (%struct.A*)***
  %vtable = load void (%struct.A*)**, void (%struct.A*)*** %tmp1, align 8, !dereferenceable !0, !invariant.group !1
  %tmp2 = load void (%struct.A*)*, void (%struct.A*)** %vtable, align 8, !invariant.load !1
  tail call void %tmp2(%struct.A* %tmp)
  %indvars.iv.next = add nuw i64 %indvars.iv, 1
  %call = tail call i32 @bar()
  %tmp3 = sext i32 %call to i64
  %cmp = icmp slt i64 %indvars.iv.next, %tmp3
  br i1 %cmp, label %for.body, label %for.cond.cleanup.loopexit
}

; CHECK-LABEL: @donthoist2(
define void @donthoist2(i8** dereferenceable(8) %arg) {
entry:
  br i1 undef, label %while.end, label %while.body.lr.ph

while.body.lr.ph:                                 ; preds = %entry
  br label %while.body

; CHECK:       while.body:
while.body:                                       ; preds = %while.body, %while.body.lr.ph
; CHECK:    [[X:%.*]] = load i8*, i8** [[ARG:%.*]], align 8, !invariant.group
  %call = tail call i32 @bar()
  %x = load i8*, i8** %arg, align 8, !invariant.group !1
  call void @foo(i8* %x)

  %tobool = icmp eq i32 %call, 0
  br i1 %tobool, label %while.end.loopexit, label %while.body

while.end.loopexit:                               ; preds = %while.body
  br label %while.end

while.end:                                        ; preds = %while.end.loopexit, %entry
  ret void
}

!0 = !{i64 8}
!1 = !{}
