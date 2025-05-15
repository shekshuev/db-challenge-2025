create or replace function caesar(input text, shift int)
returns text AS $$
declare
    result text := '';
    ch char;
    code int;
begin
    for i in 1..length(input) loop
        ch := substr(input, i, 1);
        code := ascii(ch);
        if code between 65 and 90 then  -- A-Z
            result := result || chr(65 + ((code - 65 + shift) % 26 + 26) % 26);
        elseif code between 97 and 122 then  -- a-z
            result := result || chr(97 + ((code - 97 + shift) % 26 + 26) % 26);
        elseif code between 48 and 57 then  -- 0-9
            result := result || chr(48 + ((code - 48 + shift) % 10 + 10) % 10);
        else
            result := result || ch; 
        end if;
    end loop;
    return result;
end;
$$ language plpgsql immutable strict;