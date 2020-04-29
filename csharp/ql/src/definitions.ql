/**
 * @name Jump-to-definition links
 * @description Generates use-definition pairs that provide the data
 *              for jump-to-definition in the code viewer.
 * @kind definitions
 * @id cs/jump-to-definition
 */

import csharp
import definitions

from Use use, Declaration definition
where
  definition = use.getDefinition() and
  definition.fromSource()
select use, definition, use.getUseType()
