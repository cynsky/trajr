# Trajectory construction and modification functions


# Names of attributes
.TRAJ_FPS <- 'fps'
.TRAJ_NFRAMES <- 'numFrames'
.TRAJ_UNITS <- 'units'

# ---- Private functions ----

# Must be called whenever the cartesian coordinates of a trajectory are
# modified. Fills in polar coordinates and displacement.
.fillInTraj <- function(trj) {
  # Get polar coordinates
  trj$polar <- complex(real = trj$x, imaginary = trj$y)

  # Calculate displacements from each point to the next
  trj$displacement <- c(0, diff(trj$polar))

  # Give it a special class
  if (class(trj)[1] != "Trajectory")
    class(trj) <- c("Trajectory", class(trj))

  trj
}

.checkCoords <- function(coords) {
  # Remove NA values at the start or end of the coordinates
  for (startIdx in 1:nrow(coords)) {
    if (!anyNA(coords[startIdx,])) break
  }
  for (endIdx in nrow(coords):1) {
    if (!anyNA(coords[endIdx,])) break
  }
  coords <- coords[startIdx:endIdx,]
  # Shouldn't be any NAs remaining
  if (anyNA(coords)) {
    stop("Trajectory contains missing coordinate values")
  }
  coords
}

# ---- Trajectory creation and modification ----

#' Create a Trajectory Object
#'
#' \code{TrajFromCoords} creates a new trajectory object from a set of
#' 2-dimensional cartesian coordinates and some metadata.
#'
#' If \code{timeCol} is specified, it is assumed to contain the time (in
#' seconds) of each data point. Otherwise times are calculated for each point as
#' \code{(frame - 1) / fps} where \code{frame} is the index of the point.
#'
#' @param track data frame containing cartesian coordinates and optionally times
#'   for the poiints in the trajectory.
#' @param xCol Name or index of the \code{x} column in \code{track} (default 1).
#' @param yCol Name or index of the \code{y} column in \code{track} (default 2).
#' @param timeCol optional name or index of the column which contains frame
#'   times.
#' @param fps Frames per second - used to calculate relative frame times if
#'   \code{track} does not contain a \code{time} column.
#'
#' @return An object with class "\code{Trajectory}", which is a data.frame with
#'   the following components: \item{x}{X coordinates of trajectory points.}
#'   \item{y}{Y coordinates of trajectory points.} \item{time}{Time (secs) for
#'   each point. if \code{timeCol} is specified, values are
#'   \code{trj[,timeCol]}, otherwise values are calculated from \code{fps}.}
#'   \item{displacementTime}{Frame times, with frame 1 at time \code{0}.}
#'   \item{polar}{Coordinates represented as complex number, to simplify working
#'   with segment angles.} \item{displacement}{Displacements between each pair
#'   of consecutive points.}
#'
#' @export
TrajFromCoords <- function(track, xCol = 1, yCol = 2, timeCol = NULL, fps = 50) {

  trj <- track

  # Ensure column names are as expected
  renm <- function(col, name) {
    if (is.numeric(col)) {
      names(trj)[col] <- name
    } else {
      names(trj)[names(trj) == col] <- name
    }
    trj
  }
  trj <- renm(xCol, 'x')
  trj <- renm(yCol, 'y')
  if (!is.null(timeCol))
    trj <- renm(timeCol, 'time')

  # Allocate times if they aren't already known
  if (!('time' %in% names(trj))) {
    # Assign times to each frame, starting at 0
    trj$time <- 0:(nrow(trj) - 1) / fps
  }

  # Check coordinates are valid
  trj <- .checkCoords(trj)

  # Get times associated with displacements, with the first point at time 0,
  # i.e. time at each point in displacement, not time between points
  trj$displacementTime <- trj$time[1:nrow(trj)] - trj$time[1]

  # Save number of frames
  attr(trj, .TRAJ_NFRAMES) <- nrow(trj)

  # Save frame rate
  attr(trj, .TRAJ_FPS) <- fps

  trj <- .fillInTraj(trj)

  trj
}

#' Scale a trajectory
#'
#' Scales the cartesian coordinates in a trajectory, for example, to convert
#' units from pixels to metres.
#'
#' @param trj The trajectory to be scaled.
#' @param scale Scaling factor to be applied to the trajectory coordinates.
#' @param units Character specifying the new spatial units, e.g. "m" or "metres"
#' @param yScale Optional scaling factor to be applied to the y-axis, which may
#'   be specified if the original coordinates are not square. Defaults to
#'   \code{scale}.
#' @return new scaled trajectory.
#'
#' @examples
#' set.seed(42)
#' trj <- TrajGenerate()
#' # original trajectory units are pixels, measured as having
#' # 47 pixels in 10 mm, so to convert to metres, scale the
#' # trajectory by the approriate factor
#' scale <- 10 / 47 * 1000
#' scaled <- TrajScale(trj, scale, "m")
#'
#' @export
TrajScale <- function(trj, scale, units, yScale = scale) {
  trj$x <- trj$x * scale
  trj$y <- trj$y * scale

  # Save units
  attr(trj, .TRAJ_UNITS) <- units

  .fillInTraj(trj)
}

#' Rotate a trajectory
#'
#' Rotates a trajectory so that \code{angle(finish - start) == angle}
#'
#' @param trj The trajectory to be rotated.
#' @param angle The angle between the first and last points in the rotated trajectory.
#' @return A new trajectory which is a rotated version of the input trajectory.
#'
#' @export
TrajRotate <- function(trj, angle = 0) {
  # Calculate current orientation
  orient <- Arg(trj$polar[length(trj$polar)] - trj$polar[1])
  # Calculate required rotation
  alpha <- angle - orient
  # Rotation matrix
  rm <- matrix(c(cos(alpha), sin(alpha), -sin(alpha), cos(alpha)), ncol = 2)

  # New track is old track rotated
  nt <- as.data.frame(t(rm %*% (t(trj[,c('x', 'y')]))))
  colnames(nt) <- c('x', 'y')
  trj$x <- nt$x
  trj$y <- nt$y

  .fillInTraj(trj)
}

#' Smooth a trajectory using a Savitzky-Golay filter
#'
#' Smooths a trajectory using a Savitzky-Golay smoothing filter.
#'
#' @param trj The trajectory to be smoothed.
#' @param p polynomial order (passed to \code{\link[signal]{sgolayfilt}}).
#' @param n Filter length (or window size), must be an odd number.  Passed to
#'   \code{\link[signal]{sgolayfilt}}.
#' @return A new trajectory which is a smoothed version of the input trajectory.
#'
#' @seealso \code{\link[signal]{sgolayfilt}}
#' @examples
#' set.seed(3)
#' trj <- TrajGenerate(500, random = TRUE, angularErrorSd = .25)
#' smoothed <- TrajSmoothSG(trj, 3, 31)
#' plot(trj)
#' plot(smoothed, col = "red", add = TRUE)
#'
#' @export
TrajSmoothSG <- function(trj, p = 3, n = p + 3 - p%%2) {
  trj$x <- signal::sgolayfilt(trj$x, p, n)
  trj$y <- signal::sgolayfilt(trj$y, p, n)
  .fillInTraj(trj)
}

