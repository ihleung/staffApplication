-- ***********************
-- Name: Ivan Leung
-- ID: 032657132
-- Date: August 15, 2023
-- Purpose: Final Project DBS501NSB
-- ***********************

-- Question 2 – 
-- Q2 SOLUTION --  
--Write a stored procedure called staff_add that will add a new row to the STAFF table as described below

CREATE OR REPLACE PROCEDURE staff_add (staffName IN STAFF.NAME%TYPE, staffJob IN STAFF.JOB%TYPE, staffSalary IN STAFF.SALARY%TYPE, staffComm IN STAFF.COMM%TYPE)
AS 
    --declared variable to the type
    largestId NUMBER(38,0);
    newId NUMBER(38,0);
BEGIN
    --get the max id from staff table
    SELECT MAX(ID) INTO LARGESTID FROM STAFF;
    --calculate as 10 higher than the highest ID currently in the STAFF table
    newId := largestId + 10;
    --check if it job is under sales, cleark or mgr or else it will error
    IF staffJob = 'Sales' OR staffJob = 'Clerk' OR staffJob = 'Mgr' THEN
    --data will inserted into the staff table
        INSERT INTO STAFF (ID, NAME, DEPT, JOB, YEARS, SALARY, COMM) VALUES (newId, staffName, 90, staffJob, 1, staffSalary, staffComm);
    ELSE
    --error handling
        RAISE VALUE_ERROR;
    END IF;
--Error handling
EXCEPTION
    --When it is not sales or clerk or mgr, it will error
    WHEN VALUE_ERROR THEN
        Raise_application_error(-20001, 'Job is not valid!');
END;

/
--Test Procedure
BEGIN
    staff_add('Tyler', 'Sales', 60000, 1000);   
END;
/
BEGIN
    staff_add('Jake', 'Clerk', 70000, 2000);   
END;
/
BEGIN
    staff_add('Mike', 'Mgr', 80000, 3000);   
END;
/

BEGIN
    staff_add('Tarik','cs', 10000.00, 200.00);
END;


-- Question 3 – 
-- Q3 SOLUTION --  
--Create an INSERT trigger ins_job to enhance the error checking on the JOB column. 

DROP TABLE STAFFAUDTBL;

--create STAFFAUDTBL table
CREATE TABLE STAFFAUDTBL
(
  ID NUMBER(38,0),
  INCJOB VARCHAR2(100)
);

-- Create the trigger
CREATE OR REPLACE TRIGGER ins_job
AFTER INSERT ON staff
FOR EACH ROW
DECLARE
    --declared variable to the type
    staffId NUMBER(38,0);
    staffIncJob CHAR(5);
BEGIN
    --when inserting values move the staff table id and job value to the variables
    IF INSERTING THEN
        staffId := :NEW.ID;
        staffIncJob := :NEW.JOB;
        --if it is not clerk, sales or mgr, it would be recored in the STAFFAUDTBL table
        IF staffIncJob = 'Clerk' OR staffIncJob = 'Sales' OR staffIncJob = 'Mgr' THEN
            NULL;
        ELSE 
            INSERT INTO STAFFAUDTBL(ID, INCJOB) VALUES(staffId, staffIncJob);
        END IF;
    END IF;
--Error handling
EXCEPTION
    --When the data is not found
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20100,'Error...');
END;
/

--Test Trigger
INSERT INTO staff (ID, NAME, DEPT, JOB, YEARS, SALARY, COMM) VALUES (390, 'Haerin', 1, 'Clerk', 1, 50000.00, 500.00);
INSERT INTO staff (ID, NAME, DEPT, JOB, YEARS, SALARY, COMM) VALUES (400, 'Danielle', 1, 'Sales', 1, 40000.00, 400.00);
INSERT INTO staff (ID, NAME, DEPT, JOB, YEARS, SALARY, COMM) VALUES (410, 'Minji', 1, 'Mgr', 1, 30000.00, 300.00);
INSERT INTO staff (ID, NAME, DEPT, JOB, YEARS, SALARY, COMM) VALUES (420, 'Hanni', 1, 'Dance', 1, 20000.00, 200.00);
INSERT INTO staff (ID, NAME, DEPT, JOB, YEARS, SALARY, COMM) VALUES (430, 'Hyein', 1, 'Sing', 1, 10000.00, 100.00);


-- Question 4 – 
-- Q4 SOLUTION --  
--Create a function called total_cmp which returns the total compensation (the sum of SALARY and COMM) and takes ID as input.

CREATE OR REPLACE FUNCTION total_cmp (inputId IN NUMBER)
RETURN NUMBER IS 
    --declared variable to the type
    compensation NUMBER;
    staffSalary NUMBER;
    staffComm NUMBER;
BEGIN
    --get the salary and commission from the staff table into the variables
    SELECT SALARY INTO STAFFSALARY FROM STAFF WHERE ID = INPUTID;
    SELECT COMM INTO STAFFCOMM FROM STAFF WHERE ID = INPUTID;
    --calculate the compensation
    compensation := staffSalary + staffComm;
    --check if the id exist if the compensation has no value
    IF compensation IS NOT NULL THEN
        --return the compensation result
        RETURN compensation;
    ELSE
    --error handling
        RAISE VALUE_ERROR;
    END IF;
--Error handling
EXCEPTION
    --When the id is incorrect 
    WHEN VALUE_ERROR THEN
        RAISE_APPLICATION_ERROR(-20001,'Incorrect ID');
END;
        
--Test Function
SELECT total_cmp(390) as Compensation FROM dual;
SELECT * FROM STAFF WHERE ID = 390;

-- Question 5 – 
-- Q5 SOLUTION --  
--Create a stored procedure called set_comm which will go through each record in the STAFF table and set the COMM columns as follows:

DROP TABLE STAFFAUDTBL;

--create STAFFAUDTBL table
CREATE TABLE STAFFAUDTBL
(
    ID NUMBER(38,0),
    INCJOB VARCHAR2(100),
    OLDCOMM NUMBER(7,2),
    NEWCOMM NUMBER(7,2)
);

CREATE OR REPLACE PROCEDURE set_comm AS
BEGIN
    --update the commission depending on the job and calculate by multiplying the salary and percent of the salary of the specific job
    UPDATE STAFF SET COMM = SALARY * 0.2 WHERE JOB = 'Mgr';
    UPDATE STAFF SET COMM = SALARY * 0.1 WHERE JOB = 'Clerk';
    UPDATE STAFF SET COMM = SALARY * 0.3 WHERE JOB = 'Sales';
    UPDATE STAFF SET COMM = SALARY * 0.5 WHERE JOB = 'Prez';
--Error handling
EXCEPTION
    --When the data is not found
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20100,'Error...');
END;
/ 

-- Create the trigger
CREATE OR REPLACE TRIGGER upd_comm
AFTER UPDATE OF COMM ON STAFF
FOR EACH ROW
BEGIN
    --insert the data in the STAFFAUDTBL table
    INSERT INTO STAFFAUDTBL (ID, INCJOB, OLDCOMM, NEWCOMM) VALUES (:OLD.ID, NULL, :OLD.COMM, :NEW.COMM);
--Error handling
EXCEPTION
    --When the data is not found
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20100,'Error...');
END;
/

--Test Procedure and Trigger
SELECT * FROM STAFF;
/
BEGIN
  set_comm;
END;
/
SELECT * FROM STAFFAUDTBL;
/

-- Question 6 – 
-- Q6 SOLUTION --  
--Take the 2 triggers you have previously created and combine them into a single trigger called staff_trig which continues to provide all
--the functionality of the previous triggers – and – also handles a DELETE by recording (INSERT) a record into the STAFFAUDTBL when a DELETE
--occurs. 

DROP TABLE STAFFAUDTBL;

--create STAFFAUDTBL table
CREATE TABLE STAFFAUDTBL 
(
    ID NUMBER,
    ACTION VARCHAR2(100),
    INCJOB VARCHAR2(100),
    OLDCOMM NUMBER,
    NEWCOMM NUMBER
);

ALTER TRIGGER ins_job DISABLE;
ALTER TRIGGER upd_comm DISABLE;

-- Create the trigger
CREATE OR REPLACE TRIGGER staff_trig
AFTER INSERT OR UPDATE OR DELETE ON STAFF
FOR EACH ROW
DECLARE
    --declared variable to the type
    staffId NUMBER(38,0);
    staffAction CHAR(1);
    staffIncJob CHAR(5);
BEGIN
    --when inserting values move the staff table id and job value to the variables and action becomes I
    IF INSERTING THEN
        staffId := :NEW.ID;
        staffAction := 'I';
        staffIncJob := :NEW.JOB;
        --if it is not clerk, sales or mgr, it would be recored in the STAFFAUDTBL table
        IF staffIncJob = 'Clerk' OR staffIncJob = 'Sales' OR staffIncJob = 'Mgr' THEN
            NULL;
        ELSE 
            --Insert the data into the STAFFAUDTBL
            INSERT INTO STAFFAUDTBL(ID, ACTION, INCJOB) VALUES(staffId, staffAction, staffIncJob);
        END IF;
    --when updating values move the staff table id to the variables and action becomes U
    ELSIF UPDATING THEN
        staffId := :OLD.ID;
        staffAction := 'U';
        --Insert the data into the STAFFAUDTBL
        INSERT INTO STAFFAUDTBL(ID, ACTION, OLDCOMM, NEWCOMM) VALUES(staffId, staffAction, :OLD.COMM, :NEW.COMM);  
    --when deleting values move the staff table id to the variables and action becomes D
    ELSIF DELETING THEN
        staffId := :OLD.ID;
        staffAction := 'D';
        --Insert the data into the STAFFAUDTBL
        INSERT INTO STAFFAUDTBL(ID, ACTION, OLDCOMM, NEWCOMM) VALUES(:OLD.ID, staffAction,:OLD.COMM, :NEW.COMM);
        --delete data from vacation table
        DELETE FROM VACATION WHERE staffId = :OLD.ID;
    END IF;
--Error handling
EXCEPTION
    --When the data is not found
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20100, 'Error...');
END;
/

--Test Trigger
INSERT INTO staff (ID, NAME, DEPT, JOB, YEARS, SALARY, COMM) VALUES (440, 'Harvey', 1, 'Mgr', 1, 5000.00, 100);
INSERT INTO staff (ID, NAME, DEPT, JOB, YEARS, SALARY, COMM) VALUES (450, 'Louis', 1, 'Dev', 1, 4500.00, NULL);

UPDATE STAFF SET COMM = 1000 WHERE ID = 440;
UPDATE STAFF SET COMM = 2000 WHERE ID = 450;
DELETE FROM STAFF WHERE ID = 440;


-- Question 7 – 
-- Q7 SOLUTION --  
--Create a new function called fun_name which will take the NAME as input and provide an output of the name which alternates
--between upper case and lower case characters.

CREATE OR REPLACE FUNCTION fun_name(inputName VARCHAR2) 
RETURN VARCHAR2 IS
    --declared variable to the type
    outputName VARCHAR2(1000);
BEGIN
    --going through every letter of the input value by using the for loop
    FOR i IN 1..LENGTH(inputName) LOOP
        --if the index is gets mod by 2 and is equal to zero then letter value in that index becomes lowercase
        IF i MOD 2 = 0 THEN
            outputName := outputName || LOWER(SUBSTR(inputName, i, 1));
        --but if it gets mod by 2 and is equal to one then letter value in that index becomes uppercase
        ELSE
            outputName := outputName || UPPER(SUBSTR(inputName, i, 1));
        END IF;
    END LOOP;
    --return the changed name as output
    RETURN outputName;
--Error handling
EXCEPTION
    --When the data is not found
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20100,'Error...');
END;
/

--Test Function
SELECT fun_name('Smith') as FunName from dual; 
SELECT fun_name('Robertson') as FunName from dual;



-- Question 8 – 
-- Q8 SOLUTION --  
--Create a new function called vowel_cnt which will take multiple NAME values as input and count the number of vowels (only
--count “A”, “a”, “E”, “e”, “I”, “I”, “O”, “o”, “U”, “u”). This is a multi-row function. 

CREATE OR REPLACE FUNCTION vowel_cnt(staffInput IN VARCHAR2) 
RETURN NUMBER IS
    --declared variable to the type
    vowelCount NUMBER(38,0) := 0;
BEGIN
    --going through every letter of the input value by using the for loop
    FOR i IN 1..LENGTH(staffInput) LOOP
        --count the number of vowels if it is only “A”, “a”, “E”, “e”, “I”, “I”, “O”, “o”, “U”, “u”
        IF SUBSTR(staffInput, i, 1) = 'A' OR SUBSTR(staffInput, i, 1) = 'a' OR 
        SUBSTR(staffInput, i, 1) = 'E' OR SUBSTR(staffInput, i, 1) = 'e' OR
        SUBSTR(staffInput, i, 1) = 'I' OR SUBSTR(staffInput, i, 1) = 'i' OR
        SUBSTR(staffInput, i, 1) = 'O' OR SUBSTR(staffInput, i, 1) = 'o' OR
        SUBSTR(staffInput, i, 1) = 'U' OR SUBSTR(staffInput, i, 1) = 'u' THEN
            vowelCount := vowelCount + 1;
        END IF;
    END LOOP;
    --return vowel count value 
    RETURN vowelCount;   
--Error handling
EXCEPTION
    --When the data is not found
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20100,'Error...');
END;
/

--Test Function
SELECT NAME, vowel_cnt(NAME) as VowelCountForName, JOB, vowel_cnt(JOB) as VowelCountForJob FROM staff;


-- Question 9 – 
-- Q9 SOLUTION --  
--Create a package called staff_pck which defines and externalizes the stored procedures and functions we have defined in
--the previous questions.

--Create the package
CREATE OR REPLACE PACKAGE staff_pck IS   
--have all the function and procedures with the input 
PROCEDURE staff_add (staffName IN STAFF.NAME%TYPE, staffJob IN STAFF.JOB%TYPE, staffSalary IN STAFF.SALARY%TYPE, staffComm IN STAFF.COMM%TYPE);
PROCEDURE set_comm;   
FUNCTION total_cmp (inputId IN NUMBER)
RETURN NUMBER;
FUNCTION fun_name(inputName VARCHAR2) 
RETURN VARCHAR2;
FUNCTION vowel_cnt(staffInput IN VARCHAR2) 
RETURN NUMBER;
END staff_pck; 

--Create the package body
CREATE OR REPLACE PACKAGE BODY staff_pck IS
PROCEDURE staff_add (staffName IN STAFF.NAME%TYPE, staffJob IN STAFF.JOB%TYPE, staffSalary IN STAFF.SALARY%TYPE, staffComm IN STAFF.COMM%TYPE)
AS 
    --declared variable to the type
    largestId NUMBER(38,0);
    newId NUMBER(38,0);
BEGIN
    --get the max id from staff table
    SELECT MAX(ID) INTO LARGESTID FROM STAFF;
    --calculate as 10 higher than the highest ID currently in the STAFF table
    newId := largestId + 10;
    --check if it job is under sales, cleark or mgr or else it will error
    IF staffJob = 'Sales' OR staffJob = 'Clerk' OR staffJob = 'Mgr' THEN
    --data will inserted into the staff table
        INSERT INTO STAFF (ID, NAME, DEPT, JOB, YEARS, SALARY, COMM) VALUES (newId, staffName, 90, staffJob, 1, staffSalary, staffComm);
    ELSE
    --error handling
        RAISE VALUE_ERROR;
    END IF;
--Error handling
EXCEPTION
    --When it is not sales or clerk or mgr, it will error
    WHEN VALUE_ERROR THEN
        Raise_application_error(-20001, 'Job is not valid!');
END staff_add;

PROCEDURE set_comm AS
BEGIN
    --update the commission depending on the job and calculate by multiplying the salary and percent of the salary of the specific job
    UPDATE STAFF SET COMM = SALARY * 0.2 WHERE JOB = 'Mgr';
    UPDATE STAFF SET COMM = SALARY * 0.1 WHERE JOB = 'Clerk';
    UPDATE STAFF SET COMM = SALARY * 0.3 WHERE JOB = 'Sales';
    UPDATE STAFF SET COMM = SALARY * 0.5 WHERE JOB = 'Prez';
--Error handling
EXCEPTION
    --When the data is not found
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20100,'Error...');
END set_comm;

FUNCTION total_cmp (inputId IN NUMBER)
RETURN NUMBER IS 
    --declared variable to the type
    compensation NUMBER;
    staffSalary NUMBER;
    staffComm NUMBER;
BEGIN
    --get the salary and commission from the staff table into the variables
    SELECT SALARY INTO STAFFSALARY FROM STAFF WHERE ID = INPUTID;
    SELECT COMM INTO STAFFCOMM FROM STAFF WHERE ID = INPUTID;
    --calculate the compensation
    compensation := staffSalary + staffComm;
    --check if the id exist if the compensation has no value
    IF compensation IS NOT NULL THEN
        --return the compensation result
        RETURN compensation;
    ELSE
    --error handling
        RAISE VALUE_ERROR;
    END IF;
--Error handling
EXCEPTION
    --When the id is incorrect 
    WHEN VALUE_ERROR THEN
        RAISE_APPLICATION_ERROR(-20001,'Incorrect ID');
END total_cmp;

FUNCTION fun_name(inputName VARCHAR2) 
RETURN VARCHAR2 IS
    --declared variable to the type
    outputName VARCHAR2(1000);
BEGIN
    --going through every letter of the input value by using the for loop
    FOR i IN 1..LENGTH(inputName) LOOP
        --if the index is gets mod by 2 and is equal to zero then letter value in that index becomes lowercase
        IF i MOD 2 = 0 THEN
            outputName := outputName || LOWER(SUBSTR(inputName, i, 1));
        --but if it gets mod by 2 and is equal to one then letter value in that index becomes uppercase
        ELSE
            outputName := outputName || UPPER(SUBSTR(inputName, i, 1));
        END IF;
    END LOOP;
    --return the changed name as output
    RETURN outputName;
--Error handling
EXCEPTION
    --When the data is not found
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20100,'Error...');
END fun_name;

FUNCTION vowel_cnt(staffInput IN VARCHAR2) 
RETURN NUMBER IS
    --declared variable to the type
    vowelCount NUMBER(38,0) := 0;
BEGIN
    --going through every letter of the input value by using the for loop
    FOR i IN 1..LENGTH(staffInput) LOOP
        --count the number of vowels if it is only “A”, “a”, “E”, “e”, “I”, “I”, “O”, “o”, “U”, “u”
        IF SUBSTR(staffInput, i, 1) = 'A' OR SUBSTR(staffInput, i, 1) = 'a' OR 
        SUBSTR(staffInput, i, 1) = 'E' OR SUBSTR(staffInput, i, 1) = 'e' OR
        SUBSTR(staffInput, i, 1) = 'I' OR SUBSTR(staffInput, i, 1) = 'i' OR
        SUBSTR(staffInput, i, 1) = 'O' OR SUBSTR(staffInput, i, 1) = 'o' OR
        SUBSTR(staffInput, i, 1) = 'U' OR SUBSTR(staffInput, i, 1) = 'u' THEN
            vowelCount := vowelCount + 1;
        END IF;
    END LOOP;
    --return vowel count value 
    RETURN vowelCount;   
--Error handling
EXCEPTION
    --When the data is not found
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20100,'Error...');
END vowel_cnt;
END staff_pck;

--Test Package

SELECT staff_pck.total_cmp(390) as Compensation FROM dual;
SELECT * FROM STAFF WHERE ID = 390;
SELECT staff_pck.fun_name('Haerin') as FunName from dual; 
SELECT staff_pck.fun_name('Tarik') as FunName from dual;
SELECT NAME, staff_pck.vowel_cnt(NAME) as VowelCountForName, JOB, staff_pck.vowel_cnt(JOB) as VowelCountForJob FROM staff;
