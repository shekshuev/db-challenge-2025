with cols as (
  select table_name, column_name, data_type, ordinal_position
  from information_schema.columns
  where table_schema = 'challenge'
),
table_cols as (
  select table_name, count(*) as col_count
  from cols
  group by table_name
),
pairs as (
  select t1.table_name as t1, t2.table_name as t2
  from table_cols t1
  join table_cols t2
    on t1.col_count = t2.col_count
   and t1.table_name < t2.table_name
),
column_comparison as (
  select
    p.t1,
    p.t2,
    c1.ordinal_position,
    c1.column_name as col1,
    c2.column_name as col2,
    c1.data_type as type1,
    c2.data_type as type2
  from pairs p
  join cols c1 on c1.table_name = p.t1
  join cols c2 on c2.table_name = p.t2 and c1.ordinal_position = c2.ordinal_position
),
diffs as (
  select
    t1,
    t2,
    count(*) filter (
      where col1 <> col2 or type1 <> type2
    ) as diff_count
  from column_comparison
  group by t1, t2
),
final as (
  select c.*
  from column_comparison c
  join diffs d on c.t1 = d.t1 and c.t2 = d.t2
  where (c.col1 <> c.col2 or c.type1 <> c.type2)
    and d.diff_count = 1
)
select
  t1 as table_1,
  col1 as table_1_column,
  t2 as table_2,
  col2 as table_2_column,
  (substring(t1 FROM '\d+')::int + substring(t2 FROM '\d+')::int) % 128 as key
from final;