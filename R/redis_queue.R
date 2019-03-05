#' @importFrom R6 R6Class
#' @import redux
NULL

#' RedisQueue object
#'
#' This object establishes an interface for Redis as a message broker
#'
#' @section Usage:
#' ```
#' queue <- RedisQueue$new(host='localhost',
#'                         port=6379, name='celery')
#' msg <- queue$pull()
#' queue$push(msg)
#' ```
#' @param name The name of the queue.
#' @param host Message broker instance address.
#' @param port Message broker port.
#'
#' @name RedisQueue
NULL

#' @export 
RedisQueue <- R6::R6Class(
    'RedisQueue',
    public = list(
        host = NULL,
        port = NULL,
        name = NULL,

        initialize = function(name='celery', host='localhost', port=6379) {
            self$host = host
            self$port = port
            if(missing(name)) {
                   stop('Must provide Queue name')
            } else {
                self$name = name
            }
        },

        pull = function() {
            msg = private$channel$LPOP(self$name)
            return(msg)
        },

        push = function(msg) {
            private$channel$LPUSH(self$name, msg)
        },

        connect = function() {
            private$channel = redux::hiredis(host=self$host,
                                             port=self$port)
        }
    ),

    private = list(
        channel = NULL
    )
)

#' RedisQueueSSL object
#'
#' This object extends RedisQueue to support making a secure connection to
#' Redis for use as a message broker
#'
#' @section Usage:
#' Using the RedisQueueSSL class to make an SSL connection to a redis backend
#' requires details of a cient key and certificate, and an associated CA 
#' certificate. This information is used by the underlying redux library 
#' that is used by rworker to make a connection to redis. The environment 
#' variables that must be set are:
#' 
#' REDIS_SSL_CERT_PATH: Full path to the certificate used for the connection
#' REDIS_SSL_KEY_PATH: Full path to the key used for the connection
#' REDIS_SSL_CA_PATH: Full path to the CA certificate
#' 
#' ```
#' queue <- RedisQueueSSL$new(host='localhost', port=6380, name='celery')
#' msg <- queue$pull()
#' queue$push(msg)
#' ```
#' 
#' @param name The name of the queue.
#' @param host Message broker instance address.
#' @param port Message broker port.#'
#' @name RedisQueueSSL
NULL

#' @export 
RedisQueueSSL <- R6::R6Class(
		'RedisQueueSSL',
		inherit = RedisQueue,
		public = list(
				
				connect = function() {
					url <- paste('rediss://', self$host, ':', self$port,
							sep="")
					private$channel = redux::hiredis(url = url)
				}
		)
)
