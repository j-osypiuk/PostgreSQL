-- 1. Create a new interns table called interns that contains the following fields:
-- – employee_id – primary key and foreign key to the employee table referring to the intern's data,
-- – supervisor_id – foreign key to the employee table referring to the data of the intern's supervisor,
-- – university – name of the intern's university,
-- – student_number – intern's album number,
-- – avg_grade – average grade of the intern from the last semester,
-- – end_date – internship end date.
-- Additionally, take care of:
-- – necessity to provide a value in the supervisor_id field,
-- – setting the default value of "TUL" in the university field,
-- – ensuring the uniqueness of the value in the student_number field,
-- – introducing a value restriction in the avg_grade field that it must be greater than or equal to 3.5 and less than or equal to 5.0.
CREATE TABLE interns(
	employee_id SERIAL,
	supervisor_id INT NOT NULL,
	university VARCHAR(100) DEFAULT 'TUL',
	student_number INT,
	avg_grade FLOAT,
	end_date DATE,
	CONSTRAINT employee_id_pk PRIMARY KEY (employee_id),
	CONSTRAINT employee_id_fk FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    CONSTRAINT supervisor_id_fk FOREIGN KEY (supervisor_id) REFERENCES employees(employee_id),
	CONSTRAINT student_number_unique UNIQUE (student_number),
	CONSTRAINT avg_grade_check CHECK (avg_grade >= 3.5 AND avg_grade <= 5.0)
);

-- Add intern details:
-- – name and surname: Mike Thompson,
-- – e-mail: I_MTHOMP,
-- – internship period: 01/07-30/09/2022,
-- – department: IT,
-- – position: Programmer,
-- – salary: half of the minimum salary for the position of Programmer,
-- – manager: IT department manager,
-- – supervisor: Bruce Ernst,
-- – album number: 200654,
-- – average rating: 4.35.
-- Make sure your trainee ID is calculated correctly.
INSERT INTO employees(employee_id, first_name, last_name, email, hire_date, job_id, salary, manager_id, department_id)
VALUES ((SELECT MAX(employee_id) + 1 FROM employees),
        'Mike',
        'Thompson',
        'I_MTHOMP',
        '2022-07-01',
        (SELECT job_id FROM jobs WHERE job_title = 'Programmer'),
        (SELECT min_salary / 2 FROM jobs WHERE job_title = 'Programmer'),
        (SELECT manager_id FROM departments WHERE department_name = 'IT'),
        (SELECT department_id FROM departments WHERE department_name = 'IT')
       );

INSERT INTO interns(employee_id, supervisor_id, student_number, avg_grade, end_date)
VALUES (
        (SELECT employee_id FROM employees WHERE first_name = 'Mike' AND last_name = 'Thompson'),
        (SELECT employee_id FROM employees WHERE first_name = 'Bruce' AND last_name = 'Ernst'),
        200654,
        4.35,
        '2022-09-30'
       );

-- Add a birth_date field to the intern table storing their date of birth.
ALTER TABLE interns
ADD COLUMN birth_date DATE;

-- Enter Mike Thompson's date of birth, assuming he began his internship on his 20th birthday.
UPDATE interns
SET birth_date = (SELECT hire_date FROM employees WHERE first_name = 'Mike' AND last_name = 'Thompson') - interval '20 years'
WHERE employee_id = (SELECT employee_id FROM employees WHERE first_name = 'Mike' AND last_name = 'Thompson');

-- Delete all information about Mike Thompson.
DELETE FROM interns
WHERE employee_id = (SELECT employee_id FROM employees WHERE first_name = 'Mike' AND last_name = 'Thompson');

DELETE FROM employees
WHERE first_name = 'Mike' AND last_name = 'Thompson';

-- Delete the intern table in the simplest way possible.
DROP TABLE interns;

-- 2. Display the current date (name this column date) and the current time without specifying milliseconds (name this column time).
SELECT current_date AS date, TO_CHAR(NOW(), 'HH24:MI:SS') AS time;

-- 3. Display information about all employees in the four columns listed:
-- – employee's name and surname separated by a space,
-- – name of the employee's position (if its element is the word Clerk, replace it with Assistant),
-- – employee's salary with the currency symbol ($) added at the beginning,
-- – employee's phone number with dashes (-) instead of dots (.).
-- Name these columns name, job, salary and phone_number.
SELECT first_name || ' ' ||  last_name AS name,
       REPLACE(j.job_title, 'Clerk', 'Assistant') AS job,
       '$' || salary AS salary,
       REPLACE(phone_number, '.', '-')
FROM employees e
JOIN jobs j ON e.job_id = j.job_id;

-- 4. Display:
-- – the lowest value of employee commissions,
-- – the lowest value of the employee's commission, taking into account that the lack of a given value means that the employee's commission is 0.
SELECT MIN(commission_pct) AS lowest_commission_1,
       MIN(COALESCE(commission_pct, 0)) AS lowest_commission_2
FROM employees;

-- 5. Display:
-- – the number of unique departments in which employees are employed,
-- – the number of unique departments in which employees are employed, excluding the Human Resources department.
SELECT COUNT(DISTINCT d.department_id) AS departments_with_emp_1,
       COUNT(DISTINCT NULLIF(d.department_id, (SELECT d1.department_id
                                               FROM departments d1
                                               WHERE d1.department_name = 'Human Resources'))) AS departments_with_emp_2
FROM departments d
JOIN employees e ON d.department_id = e.department_id;

-- 6. Display the names of cities that have more departments than the average number of departments in all cities. Use the WITH clause in the solution.
WITH avg_departments_count AS (
    SELECT CAST((SELECT COUNT(DISTINCT department_id) FROM departments) AS FLOAT) / CAST((SELECT COUNT(DISTINCT location_id) FROM locations) AS FLOAT) AS avg
)
SELECT city
FROM locations l
JOIN departments d ON l.location_id = d.location_id
GROUP BY l.location_id
HAVING COUNT(d.department_id) > (SELECT avg FROM avg_departments_count);

-- 7. For each department, display its name and information about the number of employees in it:
-- – "none" if no employee works in a given department,
-- – "X employee(s)" if there are X employees working in a given department (the X value should be converted to an actual number).
-- Use the sum of sets operator in your solution.
SELECT d.department_name, COUNT(e.employee_id) || ' employee(s)' AS empl_number
FROM departments d
JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id
UNION
SELECT d.department_name, 'none' AS empl_number
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id
HAVING COUNT(e.employee_id) = 0;

-- 8. Display the names of employees who changed positions at least once during their employment with the company.
--    Sort the results alphabetically by surname and first name. Use the set intersection operator in the solution.
SELECT first_name, last_name
FROM employees
INTERSECT
SELECT e.first_name, e.last_name
FROM employees e
JOIN job_history jh ON e.employee_id = jh.employee_id
ORDER BY last_name, first_name;

-- 9. Display the names of cities where no department is located. Use the set difference operator in the solution.
SELECT city
FROM locations
EXCEPT
SELECT l.city
FROM locations l
JOIN departments d ON l.location_id = d.location_id;