create temp view export as

SELECT sum(len-header_len) as sum_payload_length FROM pkt JOIN capture USING (capture_id)
WHERE
        capture.name = :'name'
  AND capture."type" = :'type';

\copy (select * from export) to pstdout csv header
;
