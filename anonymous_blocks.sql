-- 1. For each employee, display their name, surname and commission information:
-- – "No commission" if the employee has no commission specified,
-- – "Unknown commission" in case the employee's commission cannot be compared to other employees in the same department,
-- – "Low commission" if the product of the commission and the minimum salary for the employee's position is less than the
-- average salary of all employees in this employee's department reduced by PLN 5,000,
-- – "High commission" in other cases.
-- Name the column with commission information commission_info. Sort the result by the last information. Use a conditional
-- statement in your solution.
SELECT e.first_name, e.last_name,
       CASE
           WHEN e.commission_pct IS NULL THEN 'No commission'
           WHEN (SELECT count(employee_id) FROM employees WHERE department_id = e.department_id) <= 1 THEN 'Unknown commission'
           WHEN e.commission_pct * j.min_salary < (SELECT avg(salary) FROM employees WHERE department_id = e.department_id) - 5000 THEN 'Low commission'
           ELSE 'High commission'
       END AS commission_info
FROM employees e
JOIN jobs j ON e.job_id = j.job_id
ORDER BY commission_info;

-- 2. View country names, region names, and the number of departments located in each country. Limit the results depending
-- on the number of departments as follows:
-- – include only those countries from the Europe region that have more than 1 department,
-- – only include those countries in the Americas region that have more than 3 departments.
-- In the solution, use the CASE conditional statement in the HAVING clause.
SELECT c.country_name, r.region_name, count(d.department_id) AS departments_count
FROM countries c
JOIN locations l ON c.country_id = l.country_id
JOIN departments d ON l.location_id = d.location_id
JOIN regions r ON r.region_id = c.region_id
GROUP BY c.country_id, r.region_id, r.region_name
HAVING count(d.department_id) >
     CASE
         WHEN r.region_name = 'Europe' THEN 1
         WHEN r.region_name = 'Americas' THEN 3
     END;

-- 3. Analyze the following sequence of values and find the relationships:
--       5.
--       4.
--       4.1.
--       4.3.
--       4.4.
--       3.
--       3.1.
--       3.3.
--       2.
--       2.1.
--       1.
--       1.1.
-- Write an anonymous block that will print the above values. Use a LOOP and exit, continue and/or interrupt iteration
-- functions in your solution.
-- Attention! If a LOOP does not exist in a system, use another available type of loop.
DO $$
DECLARE
    i INT := 4;
    j INT := 0;
BEGIN
    RAISE NOTICE '5.';
    LOOP
        EXIT WHEN i < 1;
        LOOP
            EXIT WHEN j > i;
            IF j = 2 THEN
                j := j + 1;
                CONTINUE;
            END IF;
            IF j = 0 THEN
                RAISE NOTICE '%.', i;
            ELSE
                RAISE NOTICE '%.%.', i, j;
            END IF;
            j := j + 1;
        END LOOP;
        j := 0;
        i := i - 1;
    END LOOP;
END $$;

-- 4. Create an anonymous block and declare appropriate variables in it. List the names of subsequent cities, starting
-- with the location with ID equal to 1500 and ending with the location with ID equal to 2500. Assume that the database
-- does not miss any location ID values in the above range, where the step is 100. For each city, write additionally
-- that many pairs of square brackets ([]), how many departments there are in it.
-- Attention! If your system allows it, use two types of loops in the solution: the FOR loop and the WHILE loop.
DO $$
DECLARE
    city_info VARCHAR;
    departments_count INT;
BEGIN
    FOR i IN 1500..2500 BY 100 LOOP
        SELECT city INTO city_info
        FROM locations
        WHERE location_id = i;

        SELECT count(d.department_id) INTO departments_count
        FROM locations l
        LEFT JOIN departments d ON l.location_id = d.location_id
        WHERE l.location_id = i;

        city_info := city_info || ' ';

        WHILE departments_count > 0 LOOP
            city_info := city_info || '[]';
            departments_count := departments_count - 1;
        END LOOP;

        RAISE NOTICE '%', city_info;
    END LOOP;
END $$;

-- 5. Create an anonymous block and declare variables for the department name and city name in it. Display the name of the
-- department located in the selected city. Catch system exceptions by their names in cases where such a department does
-- not exist or there is more than 1 such department - write appropriate information. Try your solution for the cities of
-- Venice, Munich and Seattle.
-- Attention! If there are no system exceptions in a system for missing results or too many results, propose the simplest
-- solution possible to catch such errors.
DO $$
DECLARE
    department_name departments.department_name%TYPE;
    city_name locations.city%TYPE := 'Seattle';
BEGIN
    SELECT d.department_name INTO STRICT department_name
    FROM departments d
    JOIN locations l ON d.location_id = l.location_id
    WHERE l.city = city_name;

    RAISE NOTICE '% has % department.', city_name, department_name;

    EXCEPTION
        WHEN too_many_rows THEN RAISE NOTICE '% has more than one department.', city_name;
        WHEN no_data_found THEN RAISE NOTICE '% has not any departments.', city_name;
END $$;

-- 6. Create an anonymous block and declare variables for the sum of salaries and the limit salary. Display the
-- total salaries of all employees. If this number is greater than the specified limit, just raise your exception and
-- print the appropriate information. Try your solution for the limit amounts of 500,000 and 700,000.
DO $$
DECLARE
    salary_sum employees.salary%TYPE;
    salary_limit employees.salary%TYPE = 500000;
BEGIN
    SELECT sum(salary) INTO salary_sum
    FROM employees;

    IF salary_sum > salary_limit THEN
        RAISE EXCEPTION 'Total salary of all employees is greater than specified limit.';
    END IF;

    RAISE NOTICE 'Total salary of all employees = $%', salary_sum;
END $$;

-- 7. Create an anonymous block and declare appropriate variables and a cursor with a parameter referring to the country
-- name. List the location ID numbers and city names of the United States of America country whose name is sent to the cursor.
-- Attention! If a cursor with a parameter does not exist in some system, save the name of the given country in a variable
-- and use it in the cursor.
DO $$
DECLARE
    country_name countries.country_name%TYPE = 'United States of America';
    country_cities_cursor CURSOR (c_name VARCHAR)
    FOR SELECT l.location_id, l.city
        FROM locations l
        JOIN countries c ON l.country_id = c.country_id
        WHERE c.country_name = c_name;
BEGIN
    FOR record IN country_cities_cursor(country_name) LOOP
        RAISE NOTICE 'ID: %, city: %', record.location_id, record.city;
    END LOOP;
END $$;

-- 8. Create an anonymous block and declare appropriate variables and cursor in it. Delete all locations where there is
-- no department. In your solution, use the WHERE CURRENT OF clause regarding the cursor.
DO $$
DECLARE
    locations_departments_cursor CURSOR
    FOR SELECT *
        FROM locations l
        WHERE l.location_id NOT IN (SELECT DISTINCT d.location_id
                                    FROM departments d
                                    WHERE d.location_id IS NOT NULL);
BEGIN
    FOR record IN locations_departments_cursor LOOP
        DELETE FROM locations
        WHERE CURRENT OF locations_departments_cursor;
    END LOOP;
END $$;

-- 9. Create an anonymous block and declare appropriate variables in it. For each location, list all the data about it
-- along with the descriptions you added. The order of data in one message is: Location ID, ZIP Code, City, State/Province,
-- and Country. Please note that descriptions are not displayed if there are no values. Use the FOR LOOP cursor in your solution.
-- Attention! If a FOR LOOP cursor does not exist on a system, skip the solution for that system.
DO $$
DECLARE
    location_data VARCHAR;
    location_data_cursor CURSOR
    FOR SELECT l.location_id, l.postal_code, l.city, l.state_province, c.country_name
        FROM locations l
        JOIN countries c ON l.country_id = c.country_id;
BEGIN
    FOR record IN location_data_cursor LOOP
        location_data := record.location_id;

        IF record.postal_code IS NOT NULL THEN
            location_data := location_data || ', ' || record.postal_code;
        END IF;
        IF record.city IS NOT NULL THEN
            location_data := location_data || ', ' || record.city;
        END IF;
        IF record.state_province IS NOT NULL THEN
            location_data := location_data || ', ' || record.state_province;
        END IF;
        IF record.country_name IS NOT NULL THEN
            location_data := location_data || ', ' || record.country_name;
        END IF;

        RAISE NOTICE '%', location_data;
    END LOOP;
END $$;