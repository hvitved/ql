/**
 * @name Cross-site scripting
 * @description Writing user input directly to a web page
 *              allows for a cross-site scripting vulnerability.
 * @kind path-problem
 * @problem.severity error
 * @precision high
 * @id cs/web/xss
 * @tags security
 *       external/cwe/cwe-079
 *       external/cwe/cwe-116
 */

import csharp
import semmle.code.csharp.security.dataflow.XSS::XSS
//import PathGraph
import DataFlow::PartialPathGraph

from TaintTrackingConfiguration c, DataFlow::PartialPathNode source, DataFlow::PartialPathNode sink, int dist
where c.hasPartialFlow(source, sink, dist)
  and source.getNode().getLocation().getFile().getStem() = "BlogEntryReply.aspx"
  //and sink.getNode().getLocation().getFile().getStem() = "Blog.aspx"
  //and sink.getNode().getLocation().getStartLine() in [40 .. 45]
select sink, source, sink, "$@ flows to here", source, "User-provided value"
