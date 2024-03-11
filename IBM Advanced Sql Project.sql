-- You have to analyze the following datasets for the city of Chicago, as available on the Chicago City data portal.

-- Socioeconomic indicators in Chicago

-- Chicago public schools

-- Chicago crime data

-- Based on the information available in the different tables, you have to run specific queries using 
-- Advanced SQL techniques that generate the required result sets.

-- Exercise 1: Using Joins
-- You have been asked to produce some reports about the communities and crimes in the Chicago area. You will need to use SQL join queries to access the data stored across multiple tables.

-- Question 1
-- Write and execute a SQL query to list the school names, community names and average attendance for communities 
-- with a hardship index of 98.

SELECT 
    cps.NAME_OF_SCHOOL,
    csd.COMMUNITY_AREA_NAME,
    cps.AVERAGE_STUDENT_ATTENDANCE
FROM
    chicago_public_schools AS cps
        LEFT JOIN
    chicago_socioeconomic_data AS csd ON cps.COMMUNITY_AREA_NUMBER = csd.COMMUNITY_AREA_NUMBER
WHERE
    csd.HARDSHIP_INDEX = 98;
    
-- Question 2
-- Write and execute a SQL query to list all crimes that took place at a school. Include case number, crime type and community name.
SELECT 
    cc.CASE_NUMBER, cc.PRIMARY_TYPE, csd.COMMUNITY_AREA_NAME
FROM
    chicago_crime AS cc
        LEFT JOIN
    chicago_socioeconomic_data AS csd ON cc.COMMUNITY_AREA_NUMBER = csd.COMMUNITY_AREA_NUMBER
WHERE
    LOCATION_DESCRIPTION LIKE '%SCHOOL%';
    
-- Exercise 2: Creating a View
-- For privacy reasons, you have been asked to create a view that enables users to select just the school name 
-- and the icon fields from the CHICAGO_PUBLIC_SCHOOLS table. By providing a view, you can ensure that users cannot 
-- see the actual scores given to a school, just the icon associated with their score. You should define new names for 
-- the view columns to obscure the use of scores and icons in the original table.

-- Question 1
-- Write and execute a SQL statement to create a view showing the columns listed in the following table, with new column names 
-- as shown in the second column.
-- Write and execute a SQL statement that returns all of the columns from the view.
-- Write and execute a SQL statement that returns just the school name and leaders rating from the view.

CREATE VIEW CHICAGO_SCHOOL_RATING (School_Name , Safety_Rating , Family_Rating , Environment_Rating , Instruction_Rating , Leaders_Rating , Teachers_Rating) AS
    SELECT 
        NAME_OF_SCHOOL,
        Safety_Icon,
        Family_Involvement_Icon,
        Environment_Icon,
        Instruction_Icon,
        Leaders_Icon,
        Teachers_Icon
    FROM
        chicago_public_schools;
        
SELECT 
    *
FROM
    CHICAGO_SCHOOL_RATING;
    
    SELECT 
    School_Name, Leaders_Rating
FROM
    CHICAGO_SCHOOL_RATING;
        
-- Exercise 3: Creating a Stored Procedure
-- The icon fields are calculated based on the value in the corresponding score field. You need to make sure that when a score field 
-- is updated, the icon field is updated too. To do this, you will write a stored procedure that receives the school id and a 
-- leaders score as input parameters, calculates the icon setting and updates the fields appropriately.

-- Question 1
-- Write the structure of a query to create or replace a stored procedure called UPDATE_LEADERS_SCORE that takes a in_School_ID 
-- parameter as an integer and a in_Leader_Score parameter as an integer.

-- Question 2
-- Inside your stored procedure, write a SQL statement to update the Leaders_Score field in the CHICAGO_PUBLIC_SCHOOLS table for the 
-- school identified by in_School_ID to the value in the in_Leader_Score parameter.

-- Question 3
-- Inside your stored procedure, write a SQL IF statement to update the Leaders_Icon field in the CHICAGO_PUBLIC_SCHOOLS table for 
-- the school identified by in_School_ID using the following information.
-- Score lower limit	Score upper limit	Icon
-- 80	99	Very strong
-- 60	79	Strong
-- 40	59	Average
-- 20	39	Weak
-- 0	19	Very weak

-- Question 4
-- Run your code to create the stored procedure.

DELIMITER //

CREATE PROCEDURE UPDATE_LEADERS_SCORE(IN in_School_ID integer, IN in_Leader_Score integer)
BEGIN
    UPDATE chicago_public_schools
    SET Leaders_Score = in_Leader_Score
    WHERE School_ID = in_School_ID;
    
UPDATE chicago_public_schools 
SET 
    Leaders_Icon = CASE
        WHEN
            in_Leader_Score >= 80
                AND in_Leader_Score <= 99
        THEN
            'Very strong'
        WHEN
            in_Leader_Score >= 60
                AND in_Leader_Score <= 79
        THEN
            'Strong'
        WHEN
            in_Leader_Score >= 40
                AND in_Leader_Score <= 59
        THEN
            'Average'
        WHEN
            in_Leader_Score >= 20
                AND in_Leader_Score <= 39
        THEN
            'Weak'
        WHEN
            in_Leader_Score >= 0
                AND in_Leader_Score <= 19
        THEN
            'Very weak'
        ELSE 'N/A'
    END;      
END //

DELIMITER ;

-- Exercise 4: Using Transactions
-- You realise that if someone calls your code with a score outside of the allowed range (0-99), then the score will be updated 
-- with the invalid data and the icon will remain at its previous value. There are various ways to avoid this problem, one of which 
-- is using a transaction.

-- Question 1
-- Update your stored procedure definition. Add a generic ELSE clause to the IF statement that rolls back the current work if the score 
-- did not fit any of the preceding categories.

-- Question 2
-- Update your stored procedure definition again. Add a statement to commit the current unit of work at the end of the procedure.



DELIMITER //

CREATE PROCEDURE UPDATE_LEADERS_SCORES (IN in_School_ID integer, IN in_Leader_Score integer)
BEGIN
  DECLARE rollback_flag BOOLEAN DEFAULT FALSE;

  START TRANSACTION;

UPDATE chicago_public_schools 
SET 
    Leaders_Score = in_Leader_Score
WHERE
    School_ID = in_School_ID;
   
  UPDATE chicago_public_schools 
  SET 
    Leaders_Icon = CASE
      WHEN in_Leader_Score >= 80 AND in_Leader_Score <= 99 THEN 'Very strong'
      WHEN in_Leader_Score >= 60 AND in_Leader_Score <= 79 THEN 'Strong'
      WHEN in_Leader_Score >= 40 AND in_Leader_Score <= 59 THEN 'Average'
      WHEN in_Leader_Score >= 20 AND in_Leader_Score <= 39 THEN 'Weak'
      WHEN in_Leader_Score >= 0 AND in_Leader_Score <= 19 THEN 'Very weak'
     ELSE 'N/A'
     END;
  BEGIN
    SET rollback_flag = TRUE;
  END;

  IF rollback_flag THEN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Leader Score provided. Rolling back changes.';
  ELSE
    COMMIT;
  END IF;
END //

DELIMITER ;
