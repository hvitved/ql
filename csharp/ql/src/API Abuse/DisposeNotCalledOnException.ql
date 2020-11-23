/**
 * @name Dispose may not be called if an exception is thrown during execution
 * @description Methods that create objects of type 'IDisposable' should call 'Dispose()' on those
 *              objects, even during exceptional circumstances, otherwise unmanaged resources may
 *              not be released.
 * @kind problem
 * @problem.severity warning
 * @precision medium
 * @id cs/dispose-not-called-on-throw
 * @tags efficiency
 *       maintainability
 *       external/cwe/cwe-404
 *       external/cwe/cwe-459
 *       external/cwe/cwe-460
 */

import csharp
import cil
import Dispose
import semmle.code.csharp.frameworks.System

predicate cilMethodThrows(CIL::Method m, Type t) {
  exists(CIL::Instruction i | i = m.getImplementation().getAnInstruction() |
    t.matchesHandle(i.(CIL::Throw).getExpr().getType())
    or
    cilMethodThrows(i.(CIL::Call).getARuntimeTarget(), t)
  )
}

pragma[noinline]
private predicate calls(Method a, Method b) {
  exists(Call c |
    c.getEnclosingCallable() = a and
    b = c.getARuntimeTarget() and
    not c = any(TryStmt try).getATriedElement()
  )
}

private class TriedCall extends Call {
  TriedCall() { not this = any(TryStmt try).getATriedElement() }
}

/**
 * Gets an exception type that may be thrown during the execution of method `m`.
 * Assumes any exception may be thrown by library types.
 */
Class getAThrownException(Method m) {
  m.fromLibrary() and
  exists(CIL::Method cm |
    m.matchesHandle(cm) and
    cilMethodThrows(cm, result)
  )
  or
  exists(ThrowElement te |
    result = te.getExpr().getType() and
    te.getEnclosingCallable() = m and
    not isTriedAgainstException(te, result)
  )
  or
  exists(Method callee |
    calls(m, callee) and
    result = getAThrownException(callee)
  )
  or
  exists(TriedCall tc |
    tc.getEnclosingCallable() = m and
    result = getAThrownException(tc.getARuntimeTarget()) and
    not isTriedAgainstException(tc, result)
  )
}

/**
 * Holds if control flow element is tried against throwing an exception of type
 * `ec`.
 */
pragma[noinline]
predicate isTriedAgainstException(ControlFlowElement cfe, ExceptionClass ec) {
  (cfe instanceof ThrowElement or cfe instanceof MethodCall) and
  exists(TryStmt ts |
    ts.getATriedElement() = cfe and
    exists(ts.getAnExceptionHandler(ec))
  )
}

private class DisposeCall extends MethodCall {
  DisposeCall() { this.getTarget() instanceof DisposeMethod }
}

private predicate localFlowStep(DataFlow::Node nodeFrom, DataFlow::Node nodeTo) {
  DataFlow::localFlowStep(nodeFrom, nodeTo) and
  not exists(AssignableDefinition def, UsingStmt us |
    nodeTo.asExpr() = def.getAReachableRead() and
    def.getTargetAccess() = us.getAVariableDeclExpr().getAccess()
  )
}

private predicate reachesDisposeCall(DisposeCall disposeCall, DataFlow::Node node) {
  localFlowStep(node, DataFlow::exprNode(disposeCall.getQualifier()))
  or
  exists(DataFlow::Node mid | reachesDisposeCall(disposeCall, mid) | localFlowStep(node, mid))
}

/**
 * Holds if `disposeCall` disposes the object created by `disposableCreation`.
 */
predicate disposeReachableFromDisposableCreation(DisposeCall disposeCall, Expr disposableCreation) {
  // The qualifier of the Dispose call flows from something that introduced a disposable into scope
  (
    disposableCreation instanceof LocalScopeDisposableCreation or
    disposableCreation instanceof MethodCall
  ) and
  reachesDisposeCall(disposeCall, DataFlow::exprNode(disposableCreation))
}

class MethodCallThatMayThrow extends MethodCall {
  MethodCallThatMayThrow() { exists(getAThrownException(this.getARuntimeTarget())) }
}

ControlFlowElement getACatchOrFinallyClauseChild() {
  exists(TryStmt ts | result = ts.getACatchClause() or result = ts.getFinally())
  or
  result = getACatchOrFinallyClauseChild().getAChild()
}

from DisposeCall disposeCall, Expr disposableCreation, MethodCallThatMayThrow callThatThrows
where
  disposeReachableFromDisposableCreation(disposeCall, disposableCreation) and
  // The dispose call is not, itself, within a dispose method.
  not disposeCall.getEnclosingCallable() instanceof DisposeMethod and
  // Dispose call not within a finally or catch block
  not getACatchOrFinallyClauseChild() = disposeCall and
  // At least one method call exists between the allocation and disposal that could throw
  disposableCreation.getAReachableElement() = callThatThrows and
  callThatThrows.getAReachableElement() = disposeCall
select disposeCall, "Dispose missed if exception is thrown by $@.", callThatThrows,
  callThatThrows.toString()
