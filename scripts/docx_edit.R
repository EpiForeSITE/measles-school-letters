#' Edit text in a Word document using regular expressions
#'
#' This function takes a Word document (.docx), finds text using a regular expression,
#' replaces it with new text, and saves the result to a new file.
#'
#' @param input_path Character string. Path to the input .docx file
#' @param find_pattern Character string. Regular expression pattern to find in the document
#' @param replacement Character string. Text to replace the found pattern with
#' @param output_path Character string. Path where the edited document should
#' be saved
#'
#' @return Nothing (invisible NULL). The function creates a new .docx file at output_path
#'
#' @examples
#' # Replace all instances of "old text" with "new text"
#' docx_edit("input.docx", "old text", "new text", "output.docx")
#' 
#' # Use regex to find and replace with backreferences
#' docx_edit("input.docx", "Hello (\\w+)", "Hi \\1", "output.docx")
#'
docx_edit <- function(
  input_path, find_pattern, replacement, output_path) {
  
  # Validate input parameters
  if (!is.character(input_path) || length(input_path) != 1) {
    stop("input_path must be a single character string")
  }
  
  if (!is.character(output_path) || length(output_path) != 1) {
    stop("output_path must be a single character string")
  }
  
  # Check if input file exists
  if (!file.exists(input_path)) {
    stop("Input file does not exist: ", input_path)
  }
  
  # Check if input file is a .docx file
  if (!grepl("\\.docx$", input_path, ignore.case = TRUE)) {
    warning("Input file does not have .docx extension")
  }
  
  # Create temporary directory for extraction
  temp_dir <- tempdir()
  temp_extract_dir <- tempfile(pattern = "docx_extract_")
  
  # Ensure cleanup happens even if function fails
  on.exit({
    if (dir.exists(temp_extract_dir)) {
      unlink(temp_extract_dir, recursive = TRUE)
    }
  }, add = TRUE)
  
  # Extract the .docx file (which is a ZIP archive)
  tryCatch({
    unzip(input_path, exdir = temp_extract_dir)
  }, error = function(e) {
    stop("Failed to extract the Word document. The file may be corrupted or not a valid .docx file: ", e$message)
  })
  
  # Locate the main document XML file
  doc_xml_path <- file.path(temp_extract_dir, "word", "document.xml")
  
  if (!file.exists(doc_xml_path)) {
    stop("Invalid Word document: document.xml not found in word/ directory")
  }
  
  # Read the document XML content
  tryCatch({
    doc_xml_content <- readLines(doc_xml_path, warn = FALSE)
    doc_xml_text <- paste(doc_xml_content, collapse = "\n")
  }, error = function(e) {
    stop("Failed to read document.xml: ", e$message)
  })
  
  # Perform the text replacement using regex
  tryCatch({

    n_replaces <- length(find_pattern)
    if (n_replaces != length(replacement)) {
      stop("find_pattern and replacement must have the same length")
    }

    modified_xml <- doc_xml_text

    for (r in seq_along(find_pattern)) {
      modified_xml <- gsub(
        pattern = find_pattern[r],
        replacement = replacement[r],
        x = modified_xml,
        perl = TRUE
        )
    }

  }, error = function(e) {
    stop("Failed to perform text replacement. Check your regular expression pattern: ", e$message)
  })
  
  # Write the modified content back to document.xml
  tryCatch({
    writeLines(strsplit(modified_xml, "\n")[[1]], doc_xml_path)
  }, error = function(e) {
    stop("Failed to write modified content to document.xml: ", e$message)
  })
  
  # Create the output .docx file by zipping the contents
  tryCatch({
    # Store current working directory
    original_wd <- getwd()
    on.exit(setwd(original_wd), add = TRUE)
    
    # Change to the extraction directory
    setwd(temp_extract_dir)
    
    # Get all files and directories to zip
    files_to_zip <- list.files(
      ".", recursive = TRUE, all.files = TRUE, include.dirs = FALSE)
    
    # Create the ZIP file (which becomes our .docx file)
    zip_result <- zip(
      zipfile = file.path(original_wd, output_path),
      files = files_to_zip,
      flags = "-q"
      )
    
    if (zip_result != 0) {
      stop("Failed to create ZIP archive")
    }
    
  }, error = function(e) {
    stop("Failed to create the output document: ", e$message)
  })
  
  message("Successfully created edited document: ", output_path)
  invisible(NULL)
}

#' A wrapper of docx_edit for bold red text
#' @param input_path Path to the input .docx file
#' @param find_pattern Regular expression pattern to find in the document
#' @param replacement Text to replace the found pattern with
#' @param output_path Path where the edited document should be saved
#'
#' @details 
#' This function formats the replacement text to be bold and red in the 
#' Word document.
#' @return 
#' Nothing (invisible NULL). The function creates a new .docx file at 
#' output_path.
docx_edit_bold_red <- function(
  input_path, 
  find_pattern,
  replacement,
  output_path
  ) {

  replacement <- paste0(
    '<w:rPr><w:b w:val="true"/><w:color w:val=\"FF0000\"/></w:rPr><w:t xml:space="preserve">',
    replacement,
    '</w:t><w:rPr><w:b w:val="false"/><w:color w:val="#000000"/></w:rPr><w:t xml:space="preserve"></w:t>'
    )

  docx_edit(
    input_path = input_path,
    find_pattern = find_pattern,
    replacement = replacement,
    output_path = output_path
  )

}

# Example usage:
# docx_edit("example-doc.docx", "This text is\\s*([a-zA-Z]+)", "This text is (XX) \\1", "edited-doc.docx")

if (FALSE) {
  docx_edit(
    input_path = "measles_Water_Canyon_School.docx",
    find_pattern = "([0-9]+) infections",
    replacement = paste0(
      # Need to split the paragraph to insert bold red text
      '</w:t></w:r>',
      to_wml(ftext("\\1 infections", fp_text(bold = TRUE, color = "red"))),
      # This starts the next paragraph
      '<w:r><w:t xml:space="preserve">'
    ),
    output_path = "measles_bold_red.docx"
  )

  # This is a more general solution

  docx_edit(
    input_path = "measles_Water_Canyon_School.docx",
    find_pattern = "([0-9]+) infections",
    replacement = paste0(
    '<w:rPr><w:b w:val="true"/><w:color w:val=\"FF0000\"/></w:rPr><w:t xml:space="preserve">',
    " \\1 InfectionSSS",
    '</w:t><w:rPr><w:b w:val="false"/><w:color w:val="#000000"/></w:rPr><w:t xml:space="preserve"></w:t>'
    ),
    #paste0(
      # # Need to split the paragraph to insert bold red text
      # '</w:t></w:r>',
      # to_wml(ftext("\\1 infections", fp_text(bold = TRUE, color = "red"))),
      # # This starts the next paragraph
      # '<w:r><w:t xml:space="preserve">'
    #),
    output_path = "measles_bold_red.docx"
  )

  docx_edit(
    input_path = "measles_Water_Canyon_School.docx",
    find_pattern = "([0-9.%]+) of the ([0-9]+) students",
    replacement = paste0(
    '<w:rPr><w:b w:val="true"/><w:color w:val=\"FF0000\"/></w:rPr><w:t xml:space="preserve">',
    " \\1 of the \\2 students",
    '</w:t><w:rPr><w:b w:val="false"/><w:color w:val="#000000"/></w:rPr><w:t xml:space="preserve"></w:t>'),
    #paste0(
      # # Need to split the paragraph to insert bold red text
      # '</w:t></w:r>',
      # to_wml(ftext("\\1 infections", fp_text(bold = TRUE, color = "red"))),
      # # This starts the next paragraph
      # '<w:r><w:t xml:space="preserve">'
    #),
    output_path = "measles_bold_red.docx"
  )

}