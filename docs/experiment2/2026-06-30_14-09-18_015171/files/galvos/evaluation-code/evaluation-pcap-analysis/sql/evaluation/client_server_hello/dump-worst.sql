create temp view export as

WITH

    pre AS (

        select ts,
               session_id,
               tls_type,
               lead(ts) over (order by ts) as next_client_hello
        from (SELECT ts, session_id, tls_type, row_number() over (partition by session_id) as c
              FROM pkt
                       JOIN capture USING (capture_id)
              WHERE capture.name = :'name'
                AND capture."type" = 'pre'
                AND pkt.tls_type = 'ClientHello'
              ORDER BY ts ASC) as yolo
        where c = 1
    )
   , post AS (
    select ts,
           session_id,
           tls_prot

    from (SELECT ts, session_id, tls_prot, row_number() over (partition by session_id) as c
          FROM pkt
                   JOIN capture USING (capture_id)
          WHERE capture.name = :'name'
            AND capture."type" = 'post'
            AND pkt.tls_type = 'ServerHello'
          ORDER BY ts DESC) as yolo
    where c = 1
)

, match AS (
	SELECT
		post.ts - pre.ts as latency,
		pre.ts AS prets,
		post.ts as postts,
		pre.session_id
	FROM  pre JOIN  post USING (session_id)
	WHERE post.ts > pre.ts
		AND post.ts < pre.ts + 5 * 1e9
		AND post.ts >= (1000000::bigint * (:'trim_ms')::bigint + (SELECT MIN(ts) from post))::bigint
)

SELECT * 
FROM match 
ORDER BY latency DESC, prets, postts ASC LIMIT :'num_worst';

\copy (select * from export) to pstdout csv header
