import semmle.code.csharp.dataflow.LibraryTypeDataFlow
import semmle.code.csharp.frameworks.EntityFramework::EntityFramework

query predicate callableFlow(string callable, string flow, boolean preservesValue) {
  exists(EFLibraryTypeDataFlow x, CallableFlowSource source, CallableFlowSink sink, Callable c |
    callable = c.getQualifiedNameWithTypes() and
    flow = source + " -> " + sink
  |
    x.callableFlow(source, sink, c, preservesValue)
    or
    x.callableFlow(source, AccessPath::empty(), sink, AccessPath::empty(), c, preservesValue)
  )
}

query predicate callableFlowAccessPath(string callable, string flow, boolean preservesValue) {
  exists(
    EFLibraryTypeDataFlow x, CallableFlowSource source, AccessPath sourceAp, CallableFlowSink sink,
    AccessPath sinkAp, Callable c
  |
    x.callableFlow(source, sourceAp, sink, sinkAp, c, preservesValue) and
    callable = c.getQualifiedNameWithTypes() and
    flow = source + " [" + sourceAp + "] -> " + sink + " [" + sinkAp + "]"
  |
    sourceAp.length() > 0
    or
    sinkAp.length() > 0
  )
}
