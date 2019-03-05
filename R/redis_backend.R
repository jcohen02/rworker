#' @importFrom R6 R6Class
#' @import redux
NULL

#' RedisBackend object
#'
#' This object establishes an interface with Redis as a results backend.
#'
#' @section Usage:
#' ```
#' backend <- RedisBackend$new(host='localhost', port=6379)
#' backend$store_result(123, TRUE)
#' ```
#' @param host Character. Message broker instance address.
#' @param port Numeric. Message broker port.
#' @name RedisBackend
NULL

#' @export 
RedisBackend <- R6::R6Class(
    'RedisBackend',
    public = list(
        host = NULL,
        port = NULL,

        initialize = function(host, port) {
            self$host = host
            self$port = port
            private$redis_client = redux::hiredis(host=host,
                                                  port=port)
        },

        store_result = function(id, msg) {
            if (msg$status == 'FAILURE') {
                msg = list(status=msg$status,
                       result=list(exc_message=msg$errors, exc_type='ValueError'),
                       task_id=msg$id,
                       traceback=msg$errors,
                       children=NULL)
            } else {
                # Prepare the result data - add a result property to 
                # the list if result data is present
                res_data <- list(progress=msg$progress)
                if(!is.null(msg$result)) {
                    res_data$result <- msg$result
                }
                msg = list(status=msg$status,
                       result=res_data,
                       task_id=msg$id,
                       traceback=msg$errors,
                       children=NULL)
            }
            msg = jsonlite::toJSON(msg, auto_unbox=TRUE, null='null')
            key = glue::glue('celery-task-meta-{id}')
            private$redis_client$SET(key, msg)
            return(NULL)
        }
    ),

    private = list(
        redis_client = NULL
    )
)


#' RedisBackendSSL object
#'
#' This object establishes an interface with Redis, via an SSL connection, 
#' as a results backend.
#'
#' @section Usage:
#' Using the RedisBackendSSL class to make an SSL connection to a redis 
#' backend requires details of a cient key and certificate, and an  
#' associated CA certificate. This information is used by the underlying  
#' redux library that is used by rworker to make a connection to redis.  
#' The environment variables that must be set are:
#' 
#' REDIS_SSL_CERT_PATH: Full path to the certificate used for the connection
#' REDIS_SSL_KEY_PATH: Full path to the key used for the connection
#' REDIS_SSL_CA_PATH: Full path to the CA certificate
#' 
#' ```
#' backend <- RedisBackend$new(host='localhost', port=6379)
#' backend$store_result(123, TRUE)
#' ```
#' @param host Character. Message broker instance address.
#' @param port Numeric. Message broker port.
#' @name RedisBackendSSL
NULL

#' @export 
RedisBackendSSL <- R6::R6Class(
		'RedisBackendSSL',
		inherit = RedisBackend,
		public = list(
				initialize = function(host, port) {
					self$host = host
					self$port = port
					url <- paste('rediss://', self$host, ':', self$port,
							sep="")
					private$redis_client = redux::hiredis(url = url)
				}
		)
)
