-- 7. Create a trigger that checks if the hire date is a future date before adding the employee. If the condition
-- is not met, it will only display the message "Operation not allowed!". If the condition is met, it will add an employee.
-- Confirm the operation for two test cases.
CREATE OR REPLACE FUNCTION on_employee_insert() RETURNS TRIGGER
AS $$
BEGIN
    IF NEW.hire_date < CURRENT_DATE THEN
        RAISE EXCEPTION 'Operation not allowed!';
    ELSE
        RETURN NEW;
    END IF;
end;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER employee_insert
    BEFORE INSERT ON employees
    FOR EACH ROW
    EXECUTE FUNCTION on_employee_insert();

INSERT INTO employees(employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary,  manager_id, department_id)
VALUES (9999, 'Alan', 'Davis', 'ala@mail.com', '143.353.4564', '2023-11-30', 'AD_PRES', 20000.00, 100, 90);

INSERT INTO employees(employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary,  manager_id, department_id)
VALUES (9999, 'Alan', 'Davis', 'ala@mail.com', '143.353.4564', '2040-11-30', 'AD_PRES', 20000.00, 100, 90);

-- 8. Create a trigger that, when you remove multiple cities with a single command, displays their names and the names of
-- their countries. Confirm the action by removing all cities where no department is located.
CREATE OR REPLACE FUNCTION on_cities_delete() RETURNS TRIGGER
AS $$
DECLARE
    country VARCHAR;
BEGIN
    SELECT country_name INTO country
    FROM countries
    WHERE country_id = OLD.country_id;

    RAISE NOTICE '%, %', OLD.city, country;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER location_delete
    BEFORE DELETE ON locations
    FOR EACH ROW
    EXECUTE FUNCTION on_cities_delete();

DELETE FROM locations
WHERE location_id NOT IN (SELECT location_id
                          FROM departments
                          WHERE location_id IS NOT NULL);

-- 9. Create a trigger that, before increasing the department manager's commission, will check its new value and prevent
-- it from being set twice as high as the previous value. If the department manager did not previously assign a value for
-- commission, the new value can be a maximum of 0.1. Confirm the trigger by updating selected employees from departments
-- with id 20 and 80.
CREATE OR REPLACE FUNCTION on_emp_commission_update() RETURNS TRIGGER
AS $$
BEGIN
    IF NEW.commission_pct > 2 * OLD.commission_pct THEN
        RAISE EXCEPTION 'New commission_pct cannot be twice as high as the previous value.';
    END IF;
    IF OLD.commission_pct IS NULL AND NEW.commission_pct > 0.1 THEN
        RAISE EXCEPTION 'New commission_pct cannot be higher than 0.1 if the previous commission_pct was null.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER commission_pct_update
    BEFORE UPDATE OF commission_pct ON employees
    FOR EACH ROW
    EXECUTE FUNCTION on_emp_commission_update();

UPDATE employees
SET commission_pct = 0.5
WHERE department_id = 80;

UPDATE employees
SET commission_pct = 0.5
WHERE department_id = 20;

