# function to evaluate dots in a tidyselect-style and return
# the variable names as character vector
.get_dot_data <- function(dat, dots, verbose = TRUE) {

  if (!is.data.frame(dat) || length(dots) == 0) {
    return(dat)
  }

  columns <- colnames(dat)

  x <- unlist(lapply(dots, function(i) {

    # contains-token
    if (grepl("^contains\\(", i)) {
      pattern <- gsub("contains\\(\"(.*)\"\\)", "\\1", i)
      columns[string_contains(pattern, columns)]

      # starts-with token
    } else if (grepl("^starts\\(", i) || grepl("^starts_with\\(", i)) {
      pattern <- gsub("(.*)\\(\"(.*)\"\\)", "\\2", i)
      columns[string_starts_with(pattern, columns)]

      # ends-with token
    } else if (grepl("^ends\\(", i) || grepl("^ends_with\\(", i)) {
      pattern <- gsub("(.*)\\(\"(.*)\"\\)", "\\2", i)
      columns[string_ends_with(pattern, columns)]

    } else if (grepl("^one_of\\(", i)) {
      pattern <- gsub("(\"|\\s)", "", unlist(strsplit(gsub("one_of\\(\"(.*)\"\\)", "\\1", i), ",")))
      columns[string_one_of(pattern, columns)]

      # from-to token
    } else if (grepl(":", i, fixed = TRUE)) {

      tmp <- unlist(strsplit(i, ":", fixed = TRUE))

      start <- if (.is_num_chr(tmp[1]))
        as.numeric(tmp[1])
      else
        which(columns == tmp[1])

      end <- if (.is_num_chr(tmp[2]))
        as.numeric(tmp[2])
      else
        which(columns == tmp[2])

      columns[start:end]

      # simple name
    } else {
      i
    }
  }))

  x <- unlist(lapply(x, function(i) {
    if (.is_num_chr(i))
      columns[as.numeric(i)]
    else if (.is_num_fac(i))
      columns[as.numeric(as.character(i))]
    else
      i
  }))

  not_found <- setdiff(x, columns)

  if (length(not_found) && isTRUE(verbose)) {
    insight::print_color(sprintf(
      "%i variables were not found in the dataset: %s\n",
      length(not_found),
      paste0(not_found, collapse = ", ")
    ),
    color = "red")
  }

  dat[, intersect(x, columns), drop = FALSE]
}

#' @importFrom stats na.omit
.is_num_chr <- function(x) {
  is.character(x) && !anyNA(suppressWarnings(as.numeric(stats::na.omit(x))))
}

.is_num_fac <- function(x) {
  is.factor(x) && !anyNA(suppressWarnings(as.numeric(levels(x))))
}
