/**
 * @name Jump-to-definition links
 * @description Generates use-definition pairs that provide the data
 *              for jump-to-definition in the code viewer.
 * @kind definitions
 * @id csharp/ide-find-references
 * @tags ide-contextual-queries/local-definitions
 */

import csharp
import definitions

external string selectedSourceFile();

from Declaration def, Use use
where def = use.getDefinition() and use.getEncodedFilePath() = selectedSourceFile()
select use, def, use.getUseType()
