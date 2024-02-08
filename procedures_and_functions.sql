-- 1. Create the proc1 procedure which, using the cursor, will print the names of cities where the real maximum earnings
-- of employees are lower than the given amount. Call it with parameter 10000.
CREATE OR REPLACE PROCEDURE proc1(amount employees.salary%TYPE)
LANGUAGE plpgsql
AS $$
DECLARE
    cur CURSOR
    FOR SELECT l.city
        FROM locations l
        JOIN departments d ON l.location_id = d.location_id
        JOIN employees e ON d.department_id = e.department_id
        GROUP BY l.city
        HAVING max(e.salary) < amount;
BEGIN
    FOR rec IN cur LOOP
        RAISE NOTICE '%', rec.city;
    END LOOP;
END;
$$;

CALL proc1(10000);

-- 2. Create a proc2 procedure that adds information about the new department to the database. The ID of the new department
-- must be automatically calculated in accordance with the principle of assigning IDs to departments. The department name
-- must be provided as a procedure parameter. Manager ID has no value entered by default, but it can be provided as a
-- procedure parameter. The location ID has a default value of 2000, but you can also provide a different value as a
-- procedure parameter. Call the proc2 procedure in all possible ways to test the operation of the default parameters.
CREATE OR REPLACE PROCEDURE proc2(dep_name departments.department_name%TYPE,
                                  mng_id departments.manager_id%TYPE DEFAULT NULL,
                                  loc_id departments.location_id%TYPE DEFAULT 2000)
LANGUAGE plpgsql
AS $$
DECLARE
    max_id departments.department_id%TYPE;
BEGIN
    SELECT MAX(department_id) INTO max_id FROM departments;

    INSERT INTO departments(department_id, department_name, manager_id, location_id)
    VALUES (max_id + 10, dep_name, mng_id, loc_id);
END;
$$;

CALL proc2('dep_1');
CALL proc2('dep_2', 100);
CALL proc2('dep_3', loc_id := 1200);
CALL proc2('dep_4', 100, 1200);

-- 3. Create the proc3 procedure, which will increase the commission by a given number of percentage points for employees
-- employed before the given year and return the number of modified records via the output parameter. Call it with parameters
-- 2004 and 5.
CREATE OR REPLACE PROCEDURE proc3(percent_inc INT, year INT, OUT rows_modified INT)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE employees
    SET commission_pct = coalesce(commission_pct, 0) + cast(percent_inc AS NUMERIC) / 100.0
    WHERE extract(YEAR FROM hire_date) < year;

    GET DIAGNOSTICS rows_modified = ROW_COUNT;
END;
$$;

DO $$
DECLARE row_count INT;
BEGIN
    CALL proc3(5, 2004, row_count);
    RAISE NOTICE '% row(s) affected.', row_count;
END $$;

-- 4. Create the function func4, which will return the percentage of the number of employees employed in the given department
-- in the total number of all employees. Round the result to the nearest hundredth. Call it for all departments inside a
-- query that produces three columns: department_id, department_name, percentage.
CREATE OR REPLACE FUNCTION func4(dep_id departments.department_id%TYPE) RETURNS NUMERIC
AS $$
DECLARE
    dep_emp_count NUMERIC;
    all_emp_count NUMERIC;
BEGIN
    SELECT count(employee_id) INTO dep_emp_count
    FROM employees
    WHERE department_id = dep_id;

    SELECT count(employee_id) INTO all_emp_count
    FROM employees;

    RETURN CASE
               WHEN all_emp_count = 0 THEN 0
               ELSE ROUND(dep_emp_count / all_emp_count * 100, 2)
           END;
END;
$$ LANGUAGE plpgsql;

SELECT department_id, department_name, func4(department_id) AS percentage
FROM departments;

-- 5. Create a func5 function that will return all information about departments located in the specified country. Call it
-- with the Canada parameter inside a query that produces two columns: department_id, department_name.
CREATE OR REPLACE FUNCTION func5(country countries.country_name%TYPE) RETURNS
TABLE(
        id departments.department_id%TYPE,
        dep_name departments.department_name%TYPE,
        mng_id departments.manager_id%TYPE,
        loc_id departments.location_id%TYPE
     )
AS $$
BEGIN
    RETURN QUERY SELECT d.*
                 FROM departments d
                 JOIN locations l ON d.location_id = l.location_id
                 JOIN countries c ON l.country_id = c.country_id
                 WHERE c.country_name = country;
END;
$$ LANGUAGE plpgsql;

SELECT id AS department_id, dep_name AS department_name
FROM func5('Canada');

-- 6. Create a func6 function that will return a cursor with information about employees (name, surname and job title)
-- whose manager is the given employee. Call it with the parameters "Matthew" and "Weiss". Then list only those employees
-- (their names and surnames) who hold the position of Stock Clerk.
-- Attention! If a system does not have a function that returns a cursor, skip the solution for that system.
CREATE OR REPLACE FUNCTION func6(f_name employees.first_name%TYPE, l_name employees.last_name%TYPE) RETURNS REFCURSOR
AS $$
DECLARE
    ref REFCURSOR;
BEGIN
    OPEN ref FOR SELECT e.first_name, e.last_name, j.job_title
                 FROM employees e
                 JOIN jobs j ON e.job_id = j.job_id
                 WHERE e.manager_id = (SELECT e2.employee_id
                                       FROM employees e2
                                       WHERE e2.first_name = f_name AND e2.last_name = l_name);

    RETURN ref;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    cur REFCURSOR;
    rec RECORD;
BEGIN
    cur := func6('Matthew','Weiss');
    LOOP
        FETCH cur INTO rec;
        IF rec.job_title = 'Stock Clerk' THEN
            RAISE NOTICE '% %', rec.first_name, rec.last_name;
        END IF;
        EXIT WHEN NOT FOUND;
    END LOOP;
    CLOSE cur;
END $$;
