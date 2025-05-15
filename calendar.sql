create or replace function generate_month_calendar(p_year int, p_month int)
returns table(n int, calendar text) as $$
    with dates as (
    select
        d.start_date,
        d.start_date + interval '1 month' - interval '1 day' as stop_date,
        to_char(d.start_date, 'ID')::int as first_num_of_week
    from (
        select to_timestamp(p_year || '-' || p_month, 'YYYY-MM') as start_date
    ) d
    ),
    calendar_data as (
    select
        extract(day from dt) as day_of_month,
        to_char(dt, 'TMDy') as day_of_week,
        to_char(dt, 'ID')::int as num_day_of_week,
        d.first_num_of_week
    from dates d
    cross join generate_series(d.start_date, d.stop_date, interval '1 day') as dt
    ),
    calendar_lines as (
    select
        cd.num_day_of_week,
        cd.day_of_week,
        concat(
        case when cd.num_day_of_week < cd.first_num_of_week then '   ' end,
        string_agg(lpad(cd.day_of_month::text, 2, ' '), ' ' order by cd.day_of_month)
        ) as calendar_str
    from calendar_data cd
    group by cd.num_day_of_week, cd.day_of_week, cd.first_num_of_week
    )
    select
    cl.num_day_of_week as n,
    format('%s %s', cl.day_of_week, cl.calendar_str) as calendar
    from calendar_lines cl
    order by cl.num_day_of_week;
$$ language sql;