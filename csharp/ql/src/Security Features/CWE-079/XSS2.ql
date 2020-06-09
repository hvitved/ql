/**
 * @name Cross-site scripting
 * @description Writing user input directly to a web page
 *              allows for a cross-site scripting vulnerability.
 * @kind path-problem
 * @problem.severity error
 * @precision high
 * @id cs/web/xss2
 * @tags security
 *       external/cwe/cwe-079
 *       external/cwe/cwe-116
 */

import csharp
import semmle.code.csharp.security.dataflow.XSS::XSS
import semmle.code.csharp.dataflow.DataFlow2
import DataFlow2::PartialPathGraph

from TaintTrackingConfiguration config, DataFlow2::PartialPathNode source, DataFlow2::PartialPathNode sink
where config.hasPartialFlow(source, sink, _)
and source.getNode().getLocation().getStartLine() = 56
and sink.getNode().toString().matches("%SaveChanges%")
and sink.getNode().toString().matches("%exit%")
//and sink.getNode().getLocation().getFile().getStem() = "BlogEntryRepository"
select sink, source, sink, "Flow"
