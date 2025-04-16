Run Rscript R/write_index_html.R
  Rscript R/write_index_html.R
  shell: /bin/bash -e {0}
  env:
    GITHUB_PAT: ***
    R_KEEP_PKG_SOURCE: yes
    R_LIBS_USER: /Users/runner/work/_temp/Library
    TZ: UTC
    _R_CHECK_SYSTEM_CLOCK_: FALSE
    NOT_CRAN: true
Error in sprintf("<div class=\"chart-card\">\n    <img src=\"%s\" alt=\"%s\" />\n  </div>",  : 
  too few arguments
Calls: mapply -> <Anonymous> -> sprintf
Execution halted
Error: Process completed with exit code 1.
