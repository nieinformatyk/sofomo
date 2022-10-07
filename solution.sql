-- SQL Oracle syntax

----------------
-- TABELA A
----------------
	-- PL/SQL blok do uczynienia skryptu reinstalowalnym
	DECLARE
		ex_tab_exists EXCEPTION;
		PRAGMA EXCEPTION_INIT(ex_tab_exists, -942);
	BEGIN
		EXECUTE IMMEDIATE 'DROP TABLE a';
	EXCEPTION
		WHEN ex_tab_exists THEN
			NULL;
	END;
	/
	-- stwórz tabelê 
	CREATE TABLE a(
	  dimension_1 VARCHAR2(1)
	, dimension_2 VARCHAR2(1)
	, dimension_3 VARCHAR2(1)
	, measure_1   NUMBER
	)
	;
	-- za³aduj tabelê danymi
	INSERT INTO a(dimension_1, dimension_2, dimension_3, measure_1) VALUES ('a', 'I', 'K', 1);
	INSERT INTO a(dimension_1, dimension_2, dimension_3, measure_1) VALUES ('a', 'J', 'L', 7);
	INSERT INTO a(dimension_1, dimension_2, dimension_3, measure_1) VALUES ('b', 'I', 'M', 2);
	INSERT INTO a(dimension_1, dimension_2, dimension_3, measure_1) VALUES ('c', 'J', 'N', 5);

	COMMIT;


----------------
-- TABELA B
----------------
	-- PL/SQL blok do uczynienia skryptu reinstalowalnym
	DECLARE
		ex_tab_exists EXCEPTION;
		PRAGMA EXCEPTION_INIT(ex_tab_exists, -942);
	BEGIN
		EXECUTE IMMEDIATE 'DROP TABLE b';
	EXCEPTION
		WHEN ex_tab_exists THEN
			NULL;
	END;
	/
	
	-- stwórz tabelê
	CREATE TABLE b(
	  dimension_1 VARCHAR2(1)
	, dimension_2 VARCHAR2(1)
	, measure_2   NUMBER
	)
	;

	-- za³aduj tabelê danymi
	INSERT INTO b(dimension_1, dimension_2, measure_2) VALUES ('a', 'J', 7);
	INSERT INTO b(dimension_1, dimension_2, measure_2) VALUES ('b', 'J', 10);
	INSERT INTO b(dimension_1, dimension_2, measure_2) VALUES ('d', 'J', 4);

	COMMIT;
	
----------------
-- TABELA MAP
----------------
	-- PL/SQL blok do uczynienia skryptu reinstalowalnym
	DECLARE
		ex_tab_exists EXCEPTION;
		PRAGMA EXCEPTION_INIT(ex_tab_exists, -942);
	BEGIN
		EXECUTE IMMEDIATE 'DROP TABLE map';
	EXCEPTION
		WHEN ex_tab_exists THEN
			NULL;
	END;
	/
	
	-- stwórz tabelê
	CREATE TABLE map(
	  dimension_1 		  VARCHAR2(1)
	, correct_dimension_2 VARCHAR2(1)
	)
	;

	-- za³aduj tabelê danymi
	INSERT INTO map(dimension_1, correct_dimension_2) VALUES ('a', 'W');
	INSERT INTO map(dimension_1, correct_dimension_2) VALUES ('a', 'W');
	INSERT INTO map(dimension_1, correct_dimension_2) VALUES ('b', 'X');
	INSERT INTO map(dimension_1, correct_dimension_2) VALUES ('c', 'Y');
	INSERT INTO map(dimension_1, correct_dimension_2) VALUES ('b', 'X');
	INSERT INTO map(dimension_1, correct_dimension_2) VALUES ('d', 'Z');

	COMMIT;

------------------------
-- rozwi¹zanie zadania
------------------------

-- deduplication for table "map" - "Materialize" hint to create temporary segment, because the dataset will be read mutltiple times
WITH s_map AS (
    SELECT /*+MATERIALIZE */DISTINCT 
           dimension_1 		   AS dimension_1
         , correct_dimension_2 AS dimension_2
      FROM map
),
-- correct mapping for table "a" with "measure_1" aggregation
s_a AS (
        SELECT a.dimension_1    AS dimension_1
			 , map.dimension_2  AS dimension_2
			 , SUM(a.measure_1) AS measure_1
          FROM a
    INNER JOIN s_map map
            ON a.dimension_1 = map.dimension_1
      GROUP BY a.dimension_1
             , map.dimension_2
),
-- correct mapping for table "b" with "measure_2" aggregation
s_b AS (
		SELECT b.dimension_1	AS dimension_1
		     , map.dimension_2  AS dimension_2
			 , SUM(b.measure_2) AS measure_2
          FROM b
    INNER JOIN s_map map
            ON b.dimension_1 = map.dimension_1
      GROUP BY b.dimension_1
             , map.dimension_2
)
-- main query(for MSSQL use "NULLIF" instead "NVL")
    SELECT 
		   NVL(s_a.dimension_1, s_b.dimension_1)   AS dimension_1
		 , NVL(s_a.dimension_2, s_b.dimension_2)   AS dimension_2
		 , SUM( NVL(s_a.measure_1, 0) ) 		   AS measure_1
		 , SUM( NVL(s_b.measure_2, 0) ) 		   AS measure_2
		 
      FROM s_a
 FULL JOIN s_b
        ON s_a.dimension_1 = s_b.dimension_1
       AND s_a.dimension_2 = s_b.dimension_2
	   
  GROUP BY NVL(s_a.dimension_1, s_b.dimension_1)
         , NVL(s_a.dimension_2, s_b.dimension_2)
         
  ORDER BY NVL(s_a.dimension_1, s_b.dimension_1)
         , NVL(s_a.dimension_2, s_b.dimension_2)
  ;

