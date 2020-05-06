private import csharp
private import TaintTrackingPublic
private import DataFlowImplCommon
private import semmle.code.csharp.Caching
private import semmle.code.csharp.dataflow.internal.DataFlowPrivate
private import semmle.code.csharp.dataflow.internal.ControlFlowReachability
private import semmle.code.csharp.dataflow.LibraryTypeDataFlow
private import semmle.code.csharp.dispatch.Dispatch
private import semmle.code.csharp.commons.ComparisonTest
private import cil
private import dotnet
// import `TaintedMember` definitions from other files to avoid potential reevaluation
private import semmle.code.csharp.frameworks.JsonNET
private import semmle.code.csharp.frameworks.WCF

/**
 * Holds if `node` should be a barrier in all global taint flow configurations
 * but not in local taint.
 */
predicate defaultTaintBarrier(DataFlow::Node node) { none() }

/**
 * Holds if the additional step from `src` to `sink` should be included in all
 * global taint flow configurations.
 */
cached
predicate defaultAdditionalTaintStep(DataFlow::Node nodeFrom, DataFlow::Node nodeTo) {
  Stages::DataFlowStage::forceCachingInSameStage() and
  any(LocalTaintExprStepConfiguration x).hasNodePath(nodeFrom, nodeTo)
  or
  // Although flow through collections is modelled precisely using stores/reads, we still
  // allow flow out of a _tainted_ collection. This is needed in order to support taint-
  // tracking configurations where the source is a collection
  readStep(nodeFrom, TElementContent(), nodeTo)
  or
  localTaintStepCil(nodeFrom, nodeTo)
  or
  // Taint members
  exists(FieldOrProperty f |
    readStep(nodeFrom, f.getContent(), nodeTo) and
    f instanceof TaintedMember
  )
  or
  exists(LibraryCodeNode n | not n.preservesValue() |
    n = nodeTo and
    nodeFrom = n.getPredecessor(TContentNone())
    or
    n = nodeFrom and
    nodeTo = n.getSuccessor(TContentNone())
  )
  or
  nodeTo = nodeFrom.(DataFlow::NonLocalJumpNode).getAJumpSuccessor(false)
}

deprecated predicate localAdditionalTaintStep = defaultAdditionalTaintStep/2;

private CIL::DataFlowNode asCilDataFlowNode(DataFlow::Node node) {
  result = node.asParameter() or
  result = node.asExpr()
}

private predicate localTaintStepCil(DataFlow::Node nodeFrom, DataFlow::Node nodeTo) {
  asCilDataFlowNode(nodeFrom).getALocalFlowSucc(asCilDataFlowNode(nodeTo), any(CIL::Tainted t))
}

private class LocalTaintExprStepConfiguration extends ControlFlowReachabilityConfiguration {
  LocalTaintExprStepConfiguration() { this = "LocalTaintExprStepConfiguration" }

  override predicate candidate(
    Expr e1, Expr e2, ControlFlowElement scope, boolean exactScope, boolean isSuccessor
  ) {
    exactScope = false and
    (
      e1 = e2.(ElementAccess).getQualifier() and
      scope = e2 and
      isSuccessor = true
      or
      e1 = e2.(AddExpr).getAnOperand() and
      scope = e2 and
      isSuccessor = true
      or
      // A comparison expression where taint can flow from one of the
      // operands if the other operand is a constant value.
      exists(ComparisonTest ct, Expr other |
        ct.getExpr() = e2 and
        e1 = ct.getAnArgument() and
        other = ct.getAnArgument() and
        other.stripCasts().hasValue() and
        e1 != other and
        scope = e2 and
        isSuccessor = true
      )
      or
      e1 = e2.(UnaryLogicalOperation).getAnOperand() and
      scope = e2 and
      isSuccessor = false
      or
      e1 = e2.(BinaryLogicalOperation).getAnOperand() and
      scope = e2 and
      isSuccessor = false
      or
      // Taint from tuple argument
      e2 =
        any(TupleExpr te |
          e1 = te.getAnArgument() and
          te.isReadAccess() and
          scope = e2 and
          isSuccessor = true
        )
      or
      e1 = e2.(InterpolatedStringExpr).getAChild() and
      scope = e2 and
      isSuccessor = true
      or
      // Taint from tuple expression
      e2 =
        any(MemberAccess ma |
          ma.getQualifier().getType() instanceof TupleType and
          e1 = ma.getQualifier() and
          scope = e2 and
          isSuccessor = true
        )
      or
      e2 =
        any(OperatorCall oc |
          oc.getTarget().(ConversionOperator).fromLibrary() and
          e1 = oc.getAnArgument() and
          scope = e2 and
          isSuccessor = true
        )
    )
  }
}
