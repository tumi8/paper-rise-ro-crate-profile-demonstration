#!/bin/bash
DEFAULT_BUCKET_SIZE=100   # default bucket size of the histogram
DEFAULT_TRIM_MS=0         # default cut the first TRIM_MS ms from evaluation
DEFAULT_NUM_WORST=5000    # default number of worst latencies to evaluate

BUCKET_SIZE="$(pos_get_variable bucket_size || true)"
if [ "$BUCKET_SIZE" = '' ]; then
	BUCKET_SIZE=$DEFAULT_BUCKET_SIZE
fi

TRIM_MS="$(pos_get_variable trim_ms || true)"
if [ "$TRIM_MS" = '' ]; then
	TRIM_MS=$DEFAULT_TRIM_MS
fi

NUM_WORST="$(pos_get_variable num_worst || true)"
if [ "$NUM_WORST" = '' ]; then
	NUM_WORST=$DEFAULT_NUM_WORST
fi

BASENAME="$(readlink -f "$0")"
BASEDIR="$(dirname "$BASENAME")"
BASENAME="$(basename "$BASENAME")"

PYTHON=$HOME/.venv/bin/python3

[[ -x "$PYTHON" ]] || PYTHON=python3

log () {
	printf "%s\n" "$*" >&2
}

err() {
	log "$*"
	exit 2
}

help() {
	err usage: "$BASENAME" capturename
}

analysis() {
	local name="$1"

	[[ -e "$name" ]] && name="$(realpath "$name")"

	local bname="$(basename "$name")"

	# histogram
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "bucket_size=$BUCKET_SIZE" -v "trim_ms=$TRIM_MS" -f "$BASEDIR/sql/evaluation/client_server_hello/latency-hist.sql" > "${bname}.bucket_size$BUCKET_SIZE.trim_ms$TRIM_MS.client_server_hello.hist.csv"
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "bucket_size=$BUCKET_SIZE" -v "trim_ms=$TRIM_MS" -f "$BASEDIR/sql/evaluation/client_hello_change_cipher/latency-hist.sql" > "${bname}.bucket_size$BUCKET_SIZE.trim_ms$TRIM_MS.client_hello_change_cipher.hist.csv"
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "bucket_size=$BUCKET_SIZE" -v "trim_ms=$TRIM_MS" -f "$BASEDIR/sql/evaluation/server_hello_change_cipher/latency-hist.sql" > "${bname}.bucket_size$BUCKET_SIZE.trim_ms$TRIM_MS.server_hello_change_cipher.hist.csv"

	# worst-of-latency
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -v "num_worst=$NUM_WORST" -f "$BASEDIR/sql/evaluation/client_server_hello/dump-worst.sql" > "${bname}.trim_ms$TRIM_MS.num_worst$NUM_WORST.client_server_hello.worst.csv"
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -v "num_worst=$NUM_WORST" -f "$BASEDIR/sql/evaluation/client_hello_change_cipher/dump-worst.sql" > "${bname}.trim_ms$TRIM_MS.num_worst$NUM_WORST.client_hello_change_cipher.worst.csv"

	# percentiles (hdr)
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -f "$BASEDIR/sql/evaluation/client_server_hello/dump-percentiles.sql" > "${bname}.trim_ms$TRIM_MS.client_server_hello.percentiles.csv"
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -f "$BASEDIR/sql/evaluation/client_hello_change_cipher/dump-percentiles.sql" > "${bname}.trim_ms$TRIM_MS.client_hello_change_cipher.percentiles.csv"
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -f "$BASEDIR/sql/evaluation/server_hello_change_cipher/dump-percentiles.sql" > "${bname}.trim_ms$TRIM_MS.server_hello_change_cipher.percentiles.csv"

	# Get TCP Segments in handshake
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -f "$BASEDIR/sql/evaluation/dump-tcp-segments.sql" > "${bname}.trim_ms$TRIM_MS.dump-tcp-segments.csv"

  # Get median latency
  psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -f "$BASEDIR/sql/evaluation/client_server_hello/latency-median.sql" > "${bname}.bucket_size$BUCKET_SIZE.trim_ms$TRIM_MS.client_server_hello.median.csv"
  psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -f "$BASEDIR/sql/evaluation/client_hello_change_cipher/latency-median.sql" > "${bname}.bucket_size$BUCKET_SIZE.trim_ms$TRIM_MS.client_hello_change_cipher.median.csv"
  psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -f "$BASEDIR/sql/evaluation/server_hello_change_cipher/latency-median.sql" > "${bname}.bucket_size$BUCKET_SIZE.trim_ms$TRIM_MS.server_hello_change_cipher.median.csv"
  
  # Get average latency
  psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -f "$BASEDIR/sql/evaluation/client_server_hello/latency-avg.sql" > "${bname}.bucket_size$BUCKET_SIZE.trim_ms$TRIM_MS.client_server_hello.avg.csv"
  psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -f "$BASEDIR/sql/evaluation/client_hello_change_cipher/latency-avg.sql" > "${bname}.bucket_size$BUCKET_SIZE.trim_ms$TRIM_MS.client_hello_change_cipher.avg.csv"
  psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -f "$BASEDIR/sql/evaluation/server_hello_change_cipher/latency-avg.sql" > "${bname}.bucket_size$BUCKET_SIZE.trim_ms$TRIM_MS.server_hello_change_cipher.avg.csv"

	# stats
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -f "$BASEDIR/sql/evaluation/client_server_hello/stats.sql" > "${bname}.trim_ms$TRIM_MS.client_server_hello.stats.csv"
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -f "$BASEDIR/sql/evaluation/client_hello_change_cipher/stats.sql" > "${bname}.trim_ms$TRIM_MS.client_hello_change_cipher.stats.csv"

  # packetrate
  psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -v "type=pre" -f "$BASEDIR/sql/evaluation/dump-packetrate.sql" > "${bname}.trim_ms$TRIM_MS.packetratepre.csv"
  psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -v "type=post" -f "$BASEDIR/sql/evaluation/dump-packetrate.sql" > "${bname}.trim_ms$TRIM_MS.packetratepost.csv"

  # Payload sum of sizes
  psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "type=pre" -f "$BASEDIR/sql/evaluation/dump-payload-data.sql" > "${bname}.payload_length_pre.csv"
  psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "type=post" -f "$BASEDIR/sql/evaluation/dump-payload-data.sql" > "${bname}.payload_length_post.csv"

  # inter-packet gap jitter histogram
  psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "type=pre" -f "$BASEDIR/sql/evaluation/dump-total-data.sql" > "${bname}.length_pre.csv"
  psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "type=post" -f "$BASEDIR/sql/evaluation/dump-total-data.sql" > "${bname}.length_post.csv"

	# inter-packet gap jitter histogram
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "bucket_size=$BUCKET_SIZE" -v "trim_ms=$TRIM_MS" -v "type=pre" -f "$BASEDIR/sql/evaluation/jitter-hist.sql" > "${bname}.bucket_size$BUCKET_SIZE.trim_ms$TRIM_MS.jitterpre.csv"
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "bucket_size=$BUCKET_SIZE" -v "trim_ms=$TRIM_MS" -v "type=post" -f "$BASEDIR/sql/evaluation/jitter-hist.sql" > "${bname}.bucket_size$BUCKET_SIZE.trim_ms$TRIM_MS.jitterpost.csv"
}

test $# -lt 1 && help

analysis "$@"
