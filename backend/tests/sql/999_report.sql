-- Prints every result, then raises (non-zero exit under ON_ERROR_STOP=1, which
-- the runner script uses) if anything failed. This is the file that makes the
-- suite CI-usable rather than just "read the output and hope."

select test.act_as_service();

select
  case when passed then 'PASS' else 'FAIL' end as result,
  name,
  detail
from test.results
order by id;

do $$
declare
  v_total int;
  v_failed int;
begin
  select count(*), count(*) filter (where not passed) into v_total, v_failed from test.results;
  raise notice '% / % assertions passed', v_total - v_failed, v_total;
  if v_failed > 0 then
    raise exception '% assertion(s) FAILED — see the table above', v_failed;
  end if;
end $$;
