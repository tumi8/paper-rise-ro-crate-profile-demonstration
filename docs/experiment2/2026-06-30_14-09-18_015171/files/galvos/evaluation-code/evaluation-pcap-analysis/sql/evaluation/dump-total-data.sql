create temp view export as

SELECT sum(len) as sum_length FROM pkt JOIN capture USING (capture_id)
WHERE
        capture.name = :'name'
     AND capture."type" = :'type';

\copy (select * from export) to pstdout csv header
;
