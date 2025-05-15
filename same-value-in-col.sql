do $$
declare
    tbl_name constant text := 'table_86911';
    col record;
    dyn_sql text;
begin
    for col in
        select column_name
        from information_schema.columns
        where table_schema = 'challenge'
          and table_name = tbl_name
          and data_type in ('text', 'character varying')
    loop
        dyn_sql := format(
            'select ctid from challenge.%I where %I = %L limit 1',
            tbl_name, col.column_name, col.column_name
        );

        begin
            execute dyn_sql into strict dyn_sql;
            raise notice 'match found: table=%, column=%, ctid=%',
                tbl_name, col.column_name, dyn_sql;
        exception when no_data_found then
            null;
        end;
    end loop;
end
$$;