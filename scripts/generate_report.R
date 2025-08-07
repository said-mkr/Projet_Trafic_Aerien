library(rmarkdown)

generate_report <- function(output_format = "html_document") {
  rmarkdown::render(
    input = "../scripts/report_template.Rmd",
    output_format = output_format,
    output_file = paste0("../rapport_trafic_", Sys.Date(), ".html")
  )
}
