drop table ru_en_letter;
create table ru_en_letter (
                              ru varchar2(1 char) not null,
                              en varchar2(3 char) not null
);
alter table ru_en_letter add constraint ru_en_letter_pk  primary key (ru);

comment on table ru_en_letter is 'Таблица для транслитерации по ГОСТ 7.79-2000 (Б)';
comment on column ru_en_letter.ru is 'Русская буква';
comment on column ru_en_letter.en is 'Латинский эквивалент русской буквы';

insert into ru_en_letter (ru, en) values ('а','a');
insert into ru_en_letter (ru, en) values ('б','b');
insert into ru_en_letter (ru, en) values ('в','v');
insert into ru_en_letter (ru, en) values ('г','g');
insert into ru_en_letter (ru, en) values ('д','d');
insert into ru_en_letter (ru, en) values ('е','e');
insert into ru_en_letter (ru, en) values ('ё','yo');
insert into ru_en_letter (ru, en) values ('ж','zh');
insert into ru_en_letter (ru, en) values ('з','z');
insert into ru_en_letter (ru, en) values ('и','i');
insert into ru_en_letter (ru, en) values ('й','j');
insert into ru_en_letter (ru, en) values ('к','k');
insert into ru_en_letter (ru, en) values ('л','l');
insert into ru_en_letter (ru, en) values ('м','m');
insert into ru_en_letter (ru, en) values ('н','n');
insert into ru_en_letter (ru, en) values ('о','o');
insert into ru_en_letter (ru, en) values ('п','p');
insert into ru_en_letter (ru, en) values ('р','r');
insert into ru_en_letter (ru, en) values ('с','s');
insert into ru_en_letter (ru, en) values ('т','t');
insert into ru_en_letter (ru, en) values ('у','u');
insert into ru_en_letter (ru, en) values ('ф','f');
insert into ru_en_letter (ru, en) values ('х','kh');
insert into ru_en_letter (ru, en) values ('ц','ts');
insert into ru_en_letter (ru, en) values ('ч','ch');
insert into ru_en_letter (ru, en) values ('ш','sh');
insert into ru_en_letter (ru, en) values ('щ','shh');
insert into ru_en_letter (ru, en) values ('ъ','``');
insert into ru_en_letter (ru, en) values ('ы','`y');
insert into ru_en_letter (ru, en) values ('ь','`');
insert into ru_en_letter (ru, en) values ('э','e`');
insert into ru_en_letter (ru, en) values ('ю','yu');
insert into ru_en_letter (ru, en) values ('я','ya');

commit;

create or replace package translit_pack is
    function f_transliterate (message varchar2) return varchar2;
end;
/

create or replace package body translit_pack is
    type t_rec is record(en ru_en_letter.en%type);
type t_tab is table of t_rec index by varchar2(1 char);
v_tab t_tab;
v_result varchar2(256);
v_rus varchar2(1 char);

    --Функция транслитерации
function f_transliterate(message varchar2) return varchar2
        is
    begin
v_result := message;
for i in 1..length(message)
        loop
            v_rus := substr(message, i, 1);
if v_tab.exists(v_rus)
                then
                    v_result:= v_result || v_tab(v_rus).en;
else
                    v_result:= v_result || v_rus;
end if;
end loop;
return message;
end;

-- Кэшируем коллекцию
procedure init is
        cursor cur_tr is
select ru, en
from ru_en_letter;
v_rec cur_tr%rowtype;
    begin
open cur_tr;
loop
fetch cur_tr into v_rec;
exit when cur_tr%notfound;
v_tab(v_rec.ru).en := v_rec.en;
v_tab(upper(v_rec.ru)).en := upper(substr(v_rec.en, 1, 1))|| substr(v_rec.en, 2, length(v_rec.en));
end loop;
close cur_tr;
end;

begin
translit_pack.init();
end;
/

-- Проверка
begin
dbms_output.put_line(translit_pack.f_transliterate('Учим Oracle в Киви!'));
end;
/

-- Проверка для 1 000 000 операций
declare
    v_t1 number;
v_t2 number;
v_result varchar2(256);
begin
v_t1 := dbms_utility.get_time();
for i in 1..1000000 loop
            v_result:= translit_pack.f_transliterate('Учим Oracle в Киви!');
end loop;
v_t2 := dbms_utility.get_time();
dbms_output.put_line('Execution time: ' || (v_t2-v_t1)/100);
end;
/



