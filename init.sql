do $$
declare
    n_tables int = 10;
    rows_per_table int = 100;
	random_range int = 100000;
    columns_per_table int = 50;
    used_col_ids int[] = '{}';
    used_table_ids int[] = '{}';
    rand_col_id int;
    rand_table_id int;
    i int;
    j int;
    col_name text;
    column_defs text;
    table_name text;
    create_stmt text;
    col_id_is_unique boolean;
    tbl_id_is_unique boolean;
    orig_table text;
    new_table text;
    random_table_idx int;
    chosen_col text;
    new_col text;
    renamed_column_defs text;
    col_names text[];
    rand_col_index int;
   	value_col_name text;
  	target_ctid TID;
begin
	perform setseed(0.391);
    execute 'drop schema if exists challenge cascade';
    execute 'create schema challenge';

    -- create N tables
    for i in 1..n_tables loop
        loop
            rand_table_id := floor(random() * random_range)::int;
            tbl_id_is_unique := not (rand_table_id = any(used_table_ids));
            exit when tbl_id_is_unique;
        end loop;
        used_table_ids := array_append(used_table_ids, rand_table_id);

        table_name := format('table_%05s', rand_table_id);
        column_defs := '';
        col_names := array[]::text[];

        for j in 1..columns_per_table loop
            loop
                rand_col_id := floor(random() * random_range)::int;
                col_id_is_unique := not (rand_col_id = ANY(used_col_ids));
                exit when col_id_is_unique;
            end loop;
            used_col_ids := array_append(used_col_ids, rand_col_id);

            col_name := format('col_%05s', rand_col_id);
            column_defs := column_defs || format('%I TEXT, ', col_name);
            col_names := array_append(col_names, col_name);
        end loop;

        column_defs := left(column_defs, length(column_defs) - 2);
        create_stmt := format('create table challenge.%I (%s);', table_name, column_defs);
        execute create_stmt;
    end loop;

    -- select random table
    random_table_idx := floor(random() * array_length(used_table_ids, 1))::int + 1;
    orig_table := format('table_%05s', used_table_ids[random_table_idx]);

    -- get columns list and select random column
    select array_agg(attname order by attnum)
    into col_names
    from pg_attribute
    where attrelid = format('challenge.%I', orig_table)::regclass
      and attnum > 0 and not attisdropped;

    rand_col_index := floor(random() * array_length(col_names, 1))::int + 1;
    chosen_col := col_names[rand_col_index];

    -- generate new table name
    loop
        rand_table_id := floor(random() * random_range)::int;
        tbl_id_is_unique := not (rand_table_id = ANY(used_table_ids));
        exit when tbl_id_is_unique;
    end loop;
    used_table_ids := array_append(used_table_ids, rand_table_id);
    new_table := format('table_%05s', rand_table_id);

    -- generate new coumn name
    loop
        rand_col_id := floor(random() * random_range)::int;
        col_id_is_unique := not (rand_col_id = ANY(used_col_ids));
        exit when col_id_is_unique;
    end loop;
    used_col_ids := array_append(used_col_ids, rand_col_id);
    new_col := format('col_%05s', rand_col_id);

    -- prepare create table statement
    renamed_column_defs := '';
    for j in 1..array_length(col_names, 1) loop
        if col_names[j] = chosen_col THEN
            renamed_column_defs := renamed_column_defs || format('%I text, ', new_col);
        else
            renamed_column_defs := renamed_column_defs || format('%I text, ', col_names[j]);
        end if;
    end loop;
    renamed_column_defs := left(renamed_column_defs, length(renamed_column_defs) - 2);
    create_stmt := format('create table challenge.%I (%s);', new_table, renamed_column_defs);
    execute create_stmt;

    -- send result to console
    raise notice 'Original table: %, New table: %, Renamed column: % → %',
        orig_table, new_table, chosen_col, new_col;
       
    -- insert rows
    for i in 1..array_length(used_table_ids, 1) loop
        table_name := format('table_%05s', used_table_ids[i]);

        -- get columns list
        select array_agg(attname ORDER BY attnum)
        inTO col_names
        from pg_attribute
        where attrelid = format('challenge.%I', table_name)::regclass
          and attnum > 0 and not attisdropped;

        -- insert rows
        for j in 1..rows_per_table loop
            column_defs := '';
            create_stmt := '';

            for col_name in select unnest(col_names) loop
			    -- generate unique value
			    loop
			        rand_col_id := floor(random() * random_range)::int;
			        col_id_is_unique := not (rand_col_id = ANY(used_col_ids));
			        exit when col_id_is_unique;
			    end loop;
			    used_col_ids := array_append(used_col_ids, rand_col_id);
			    value_col_name := format('col_%05s', rand_col_id); 
			
			    column_defs := column_defs || format('%I, ', col_name);
			    create_stmt := create_stmt || quote_literal(value_col_name) || ', '; 
			end loop;

            column_defs := left(column_defs, length(column_defs) - 2);
            create_stmt := left(create_stmt, length(create_stmt) - 2);

            execute format('insert into challenge.%I (%s) values (%s);', table_name, column_defs, create_stmt);
        end loop;
    end loop;

    -- replace one unique value for column name for task 2

    -- select random table
    random_table_idx := floor(random() * array_length(used_table_ids, 1))::int + 1;
    table_name := format('table_%05s', used_table_ids[random_table_idx]);

    -- get columns list
    select array_agg(attname ORDER BY attnum)
    inTO col_names
    from pg_attribute
    where attrelid = format('challenge.%I', table_name)::regclass
    and attnum > 0 and not attisdropped;

    -- select random column
    rand_col_index := floor(random() * array_length(col_names, 1))::int + 1;
    chosen_col := col_names[rand_col_index];

    -- get random row
    execute format(
        'select ctid from challenge.%I ORDER BY random() LIMIT 1',
        table_name
    ) inTO target_ctid;

    -- change value for column name
    execute format(
        'UPDATE challenge.%I SET %I = %L where ctid = $1',
        table_name, chosen_col, chosen_col
    ) USinG target_ctid;

    RAISE notICE 'Updated table: %, column: %, ctid: %',
        table_name, chosen_col, target_ctid;
    end
$$;
