#' Get projects
#'
#' Gets list of available projects
#'
#' @return structure with parsed projects and http response
#' @export
get_projects <- function() {
  api_url_projects <- paste(MLAR_API_PATH, API_VERSION, "/projects" , sep="")
  rp <- .get_json_from_get_query(api_url_projects)
  resp <- rp$resp
  parsed <- rp$parsed
  structure(
    list(
      projects = parsed,
      response = resp
    ),
    class = "get_projects"
  )
}

print.get_projects <- function(x, ...) {
  cat("<MLJAR projects >\n", sep = "")
  str(x$projects)
  invisible(x)
}

#' Print all projects
#'
#' Gives data.frame with basic information about existing projects
#'
#' @return data.frame with projects
#' @export
print_all_projects <- function() {
  columns = c("hid", "title", "task", "description")
  projects <- get_projects()
  if (length(projects$projects) == 0) return(data.frame())
  tmp_sa <- sapply(projects$projects,
                   function(x) c(x$hid, x$title, x$task,
                                 ifelse(!is.null(x$description), x$description, "")),
                   simplify = FALSE, USE.NAMES = TRUE)
  df_proj <- t(as.data.frame(tmp_sa,
                            row.names = columns,
                            col.names = 1:length(tmp_sa)))
  df_proj <- data.frame(df_proj, row.names = NULL)
  return(df_proj)
}

#' Get project
#'
#' Get data from a project of specified hid
#'
#' @param hid character with project unique identifier
#'
#' @return structure with parsed project and http response
#' @export
get_project <- function(hid) {
  api_url_project_hid <- paste(MLAR_API_PATH, API_VERSION, "/projects/", hid, sep="")
  rp <- .get_json_from_get_query(api_url_project_hid)
  resp <- rp$resp
  parsed <- rp$parsed

  structure(
    list(
      project = parsed,
      response = resp
    ),
    class = "get_project"
  )
}

print.get_project <- function(x, ...) {
  cat("<MLJAR project >\n", sep = "")
  str(x$project)
  invisible(x)
}

#' Creates a new project
#'
#' @param title character with project title
#' @param task character with project task
#' @param description optional description
#'
#' @return project details structure
#' @export
create_project <-function(title, task, description=""){
  .verify_if_project_exists(title, task)
  token <- .get_token()
  api_url_projects <- paste(MLAR_API_PATH, API_VERSION, "/projects" , sep="")
  data <- list(title = title,
               hardware = 'cloud',
               scope = 'private',
               task = task,
               compute_now = 0,
               description = description)
  resp <- POST(api_url_projects, add_headers(Authorization = paste("Token", token)),
               body = data, encode = "form")
  .check_response_status(resp, 201)
  if (status_code(resp)==201){
    print(sprintf("Project <%s> succesfully created!", title))
  }
  project_details <- jsonlite::fromJSON(content(resp, "text", encoding = "UTF-8"), simplifyVector = FALSE)
  return(project_details)
}

#' Delete project
#'
#' @param hid charceter with project identifier
#'
#' @export
#' @importFrom httr DELETE status_code
delete_project <-function(hid){
  token <- .get_token()
  api_url_project_hid <- paste(MLAR_API_PATH, API_VERSION, "/projects/", hid, sep="")
  resp <- DELETE(api_url_project_hid, add_headers(Authorization = paste("Token", token)))
  if (status_code(resp)==204 || status_code(resp)==200){
    print(sprintf("Project <%s> succesfully deleted!", hid))
  }
}

# Helper project functions

#' Verify if project exists
#'
#' Checks if there is no project with the same name and task.
#'
#' @param projtitle character with project title
#' @param task characeter with project task
#'
#' @return TRUE if okay, stops if such a project exists.
.verify_if_project_exists <- function(projtitle, task){
  gp <- get_projects()
  for (proj in gp$projects){
    if (proj$title==projtitle && proj$task==task){
      stop("Project with the same title and task already exists, change name.")
    }
  }
  return(TRUE)
}

#' Checks if project exists
#'
#' It bases only on title and returns project's hid if it exists.
#'
#' @param project_title character with project title
#'
#' @return character of project with its identifier or NULL
.check_if_project_exists <- function(project_title) {
  projects <- get_projects()
  proj_hid <- NULL
  if (length(projects$projects) == 0) return(NULL)
  for(i in 1:length(projects$projects)) {
    if (projects$projects[[i]]$title == project_title){
      proj_hid <- projects$projects[[i]]$hid
      break
    }
  }
  return(proj_hid)
}
