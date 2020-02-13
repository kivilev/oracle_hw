-- Набор типов, которые понадобятся ниже. Глобально, так как они будут использоваться в SQL
create or replace  type t_rec  is object (val varchar2(100 char));
create or replace  type t_date is object (schedule_dtime date);
create or replace  type t_num  is object(x number);
create or replace  type t_varr is varray(5) of t_rec;
create or replace  type t_numbers  is table of t_num;
create or replace  type t_dates  is table of t_date;

create or replace function get_next_schedule_time (
    v_date date,
    v_schedule varchar2
) return date as
    v_varr t_varr;
v_next_date date;
v_days t_numbers;
v_day_of_weeks t_numbers;
v_months t_numbers;
v_hours t_numbers;
v_intervals t_numbers;
v_dates t_dates;
begin
    -- Разбиваем на исзодное расписание на типы: дни, часы, месяцы... Сохраняем к коллекцию
select
    t_rec(regexp_substr(str,reg, 1, level))
        bulk collect
into v_varr
from
    (select
         v_schedule as str,
         '[^;]+' as reg
     from dual)
        connect by level <= 5;

-- Парсим месяцы и сохраняем в коллекцию
select
    t_num(to_number(regexp_substr(str,reg, 1, level))) as x
    bulk collect
into v_months
from
    (
        select
            v_varr(5).val as str,
            '[^,]+' as reg
        from dual
    )
        connect by level <= 12;

-- Парсим дни и сохраняем в коллекцию
select
    t_num(to_number(regexp_substr(str,reg, 1, level))) as x
    bulk collect
into v_days
from
    (
        select
            v_varr(4).val as str,
            '[^,]+' as reg
        from dual
    )
        connect by level <= 31;

-- Парсим дни недели и сохраняем в коллекцию
select
    t_num(to_number(regexp_substr(str,reg, 1, level))) as x
    bulk collect
into v_day_of_weeks
from
    (
        select
            v_varr(3).val as str,
            '[^,]+' as reg
        from dual
    )
        connect by level <= 7;

-- Парсим часы и сохраняем в коллекцию
select
    t_num(to_number(regexp_substr(str,reg, 1, level))) as x
    bulk collect
into v_hours
from
    (
        select
            v_varr(2).val as str,
            '[^,]+' as reg
        from dual
    )
        connect by level <= 24;

-- Парсим минутные интервалы и сохраняем в коллекцию
select
    t_num(to_number(regexp_substr(str,reg, 1, level))) as x
    bulk collect
into v_intervals
from
    (
        select
            v_varr(1).val as str,
            '[^,]+' as reg
        from dual
    )
        connect by level <= 4;

-- Получаем дни, в которые нужно выполнять
select t_date(dt)
           bulk collect
into v_dates
from (
         -- Годы склеиваем с месяцами и с днями
         select TO_DATE( yy.x||'-'||mm.x||'-'||dd.x , 'YYYY-mm-dd') as dt
         from (
                  select to_number(to_char(v_date,'yyyy')) as x from dual)  yy
                  cross join (select x from table(v_months))  mm
                  cross join (select x from table(v_days))  dd
         where yy.x is not null
           and mm.x is not null
           and dd.x is not null

         intersect -- ищем те даты, которые попали и в расписание по дням месяца и по дням неделям

         -- Годы склеиваем с месяцами и с днями недели
         select bb.day + ww.x
         from (
                  select trunc(v_date, 'year') + level*7 - to_char(trunc(v_date, 'year'),'D')-1 as day
                  from dual
                           connect by LEVEL<=52
              ) bb
                  cross join (select x from table(v_day_of_weeks)) ww
         where ww.x is not null
     );

-- К датам приклеиваем часы и минуты и ищем все, минимальную дату, которая больше даты их параметра
select min(schedule_dtime + (1/24) * hh.x + (1/24/60) * mi.x)
into v_next_date
from table(v_dates)
         cross join (select x from table(v_hours))  hh
         cross join (select x from table(v_intervals))  mi
where hh.x is not null
  and mi.x is not null
  and schedule_dtime + (1/24) * hh.x + (1/24/60) * mi.x > v_date;

return v_next_date;
end;

begin
dbms_output.put_line
    (
        to_char(
        get_next_schedule_time
            (
            to_date('2010-09-09 23:36', 'yyyy-mm-dd hh24:mi'),
            '0,45;12;1,2,6;3,6,14,18,21,24,28;1,2,3,4,5,6,7,8,9,10,11,12;')
            ,  'yyyy-mm-dd hh24:mi'
        ));
end;