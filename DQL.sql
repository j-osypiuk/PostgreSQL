-- 1. Display the names and surnames of employees working in the IT department. Sort the results descending by salary and alphabetically
--    by surname.
SELECT e.first_name, e.last_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE d.department_name = 'IT'
ORDER BY e.salary DESC, e.last_name;

-- 2. Display the names of departments whose first letter is the same as the last letter of the country in which they are located.
SELECT d.department_name
FROM departments d
JOIN locations l ON d.location_id = l.location_id
JOIN countries c ON l.country_id = c.country_id
WHERE LOWER(LEFT(d.department_name, 1)) = LOWER(RIGHT(c.country_name, 1));

-- 3. Display the employees' names and the day of the week they were hired in their current position (name this column hired_weekday).
--    Only include employees who were hired on Monday or Friday.
SELECT first_name, last_name, TO_CHAR(DATE(hire_date), 'DAY') AS hired_weekday
FROM employees
WHERE TO_CHAR(DATE(hire_date), 'D') IN ('2', '6');

-- 4. Display the names of positions where no employee is employed.
SELECT j.job_title
FROM jobs j
LEFT JOIN employees e ON j.job_id = e.job_id
GROUP BY j.job_id
HAVING COUNT(e.employee_id) = 0;

-- 5. For each employee, display their name and the number of colleagues who report directly to them. Also include those employees who
--    have no subordinates.
SELECT m.first_name, m.last_name, COUNT(e.employee_id) AS subordinates_count
FROM employees m
LEFT JOIN employees e ON m.employee_id = e.manager_id
GROUP BY m.employee_id;

-- 6. Display the names of cities where more than one department is located.
SELECT l.city
FROM locations l
JOIN departments d ON l.location_id = d.location_id
GROUP BY l.location_id
HAVING COUNT(d.department_id) > 1;

-- 7. Display the names of employees who earn more than the average salary of employees employed at least 20 years ago.
SELECT first_name, last_name
FROM employees
WHERE salary > (SELECT AVG(salary)
                FROM employees
                WHERE EXTRACT(YEAR FROM (AGE(hire_date))) >= 20);

-- 8. Display the names of the departments with the most employees.
SELECT d.department_name
FROM departments d
JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id
ORDER BY COUNT(e.employee_id) DESC
FETCH FIRST 1 ROWS WITH TIES;

-- 9. For each position, display its name and the names of current employees who have been employed there for the shortest time.
--    Also include those positions where no employee is employed.
SELECT j.job_title, e.first_name, e.last_name
FROM jobs j
LEFT JOIN employees e ON j.job_id = e.job_id
WHERE e.employee_id IN (SELECT e1.employee_id
                        FROM employees e1
                        WHERE e1.job_id = j.job_id
                        ORDER BY e1.hire_date DESC
                        FETCH FIRST 1 ROWS WITH TIES)
      OR e.employee_id IS NULL;