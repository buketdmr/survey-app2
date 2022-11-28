CREATE OR REPLACE PROCEDURE "BUCAP"."USP_GET_G_SURVEY_ANS" ( @GROUPSURVEYID BIGINT, @SURVEYID BIGINT, @SECTIONID BIGINT, @BPXQUESTION BOOLEAN)
SPECIFIC BUCAP.USP_GET_G_SURVEY_ANS
LANGUAGE SQL
DYNAMIC RESULT SETS 2
BEGIN
DECLARE C1 CURSOR WITH RETURN FOR
SELECT
   SURVEYQUESTIONID,
   SURVEYQUESTIONANSWEROPTIONID,
   ANSWERDECIMAL,
   ANSWERINTEGER,
   ANSWERDATE,
   ANSWERDATETIME,
   ANSWERTEXT,
   ANSWERBOOLEAN,
   (
   SELECT
       ANSWERBLOB
   FROM        BUCAP.SURVEYGROUPQUESTIONANSWER A
   WHERE        A.SURVEYGROUPQUESTIONANSWERID = A1.SURVEYGROUPQUESTIONANSWERID) ANSWERBLOB,
   -1 LASTUPDATEBYUSERID
FROM    ( (
   SELECT
       S.SURVEYQUESTIONID, SURVEYGROUPQUESTIONANSWERID, SURVEYQUESTIONANSWEROPTIONID, ANSWERDECIMAL, ANSWERINTEGER, ANSWERDATE, ANSWERDATETIME, ANSWERTEXT, ANSWERBOOLEAN, Q.QUESTIONORDER
   FROM        BUCAP.SURVEYGROUPQUESTIONANSWER S
   INNER JOIN BUCAP.SURVEYQUESTION Q ON
       S.SURVEYQUESTIONID = Q.SURVEYQUESTIONID
   INNER JOIN BUCAP.SURVEYGROUPDETAIL SS ON
       S.SURVEYGROUPDETAILID = SS.SURVEYGROUPDETAILID
   WHERE        S.SURVEYQUESTIONID IN (
       SELECT
           Q.SURVEYQUESTIONID
       FROM            BUCAP.SURVEYQUESTION Q INNER JOIN BUCAP.SURVEYGROUPDETAIL SGD ON Q.SURVEYID = SGD.SURVEYID
       WHERE            SGD.SURVEYGROUPDETAILID = @GROUPSURVEYID
           AND Q.SURVEYSECTIONID = @SECTIONID
           AND Q.BPXQUESTION = @BPXQUESTION )
       AND SS.SURVEYGROUPDETAILID = @GROUPSURVEYID)
UNION (
SELECT
   S.SURVEYQUESTIONID, NULL AS SURVEYGROUPQUESTIONANSWERID, NULL SURVEYQUESTIONANSWEROPTIONID, NULL ANSWERDECIMAL, NULL ANSWERINTEGER, NULL ANSWERDATE, NULL ANSWERDATETIME, NULL ANSWERTEXT, NULL ANSWERBOOLEAN, S.QUESTIONORDER
FROM    BUCAP.SURVEYQUESTION S
WHERE    S.SURVEYQUESTIONID IN (
   SELECT
       SURVEYQUESTIONID
   FROM        BUCAP.SURVEYQUESTION Q
   WHERE        SURVEYID = @SURVEYID
       AND SURVEYSECTIONID = @SECTIONID
       AND BPXQUESTION = @BPXQUESTION )
   AND S.SURVEYQUESTIONID NOT IN (
   SELECT
       S.SURVEYQUESTIONID
   FROM        BUCAP.SURVEYGROUPQUESTIONANSWER S
   INNER JOIN BUCAP.SURVEYGROUPDETAIL SS ON
       S.SURVEYGROUPDETAILID = SS.SURVEYGROUPDETAILID
   WHERE        S.SURVEYQUESTIONID IN (
       SELECT
           SURVEYQUESTIONID
       FROM            BUCAP.SURVEYQUESTION Q INNER JOIN BUCAP.SURVEYGROUPDETAIL SGD ON Q.SURVEYID = SGD.SURVEYID
       WHERE            SGD.SURVEYGROUPDETAILID = @GROUPSURVEYID
           AND SURVEYSECTIONID = @SECTIONID
           AND BPXQUESTION = @BPXQUESTION )
       AND SS.SURVEYGROUPDETAILID = @GROUPSURVEYID ) )) A1
ORDER BY
   QUESTIONORDER ;
DECLARE C2 CURSOR WITH RETURN FOR
SELECT
   DISTINCT S.SURVEYQUESTIONID,
   D.SURVEYQUESTIONID AS DEPID,
   SURVEYQUESTIONANSWEROPTIONID,
   ANSWERDECIMAL,
   ANSWERINTEGER,
   ANSWERDATE,
   ANSWERDATETIME,
   ANSWERTEXT,
   ANSWERBOOLEAN,
   T.QUESTIONTYPE,
   D.DEPENDENTSURVEYQUESTIONRESULTBOOLEAN,
   D.DEPENDENTSURVEYQUESTIONRESULTINT
FROM    BUCAP.SURVEYGROUPQUESTIONANSWER S
INNER JOIN BUCAP.SURVEYQUESTIONDEPENDENCY D ON
   S.SURVEYQUESTIONID = D.DEPENDENTSURVEYQUESTIONID
INNER JOIN BUCAP.SURVEYQUESTION Q ON
   S.SURVEYQUESTIONID = Q.SURVEYQUESTIONID
INNER JOIN BUCAP.QUESTIONTYPE T ON
   Q.QUESTIONTYPEID = T.QUESTIONTYPEID
INNER JOIN BUCAP.SURVEYGROUPDETAIL SS ON
   S.SURVEYGROUPDETAILID = SS.SURVEYGROUPDETAILID
WHERE    SS.SURVEYGROUPDETAILID = @GROUPSURVEYID
   AND S.SURVEYQUESTIONID IN (
   SELECT
       DEPENDENTSURVEYQUESTIONID
   FROM        BUCAP.SURVEYQUESTIONDEPENDENCY
   WHERE        SURVEYQUESTIONID IN (
       SELECT
           SURVEYQUESTIONID
       FROM            BUCAP.SURVEYQUESTION Q INNER JOIN BUCAP.SURVEYGROUPDETAIL SGD ON Q.SURVEYID = SGD.SURVEYID
       WHERE            SGD.SURVEYGROUPDETAILID = @GROUPSURVEYID
           AND SURVEYSECTIONID = @SECTIONID
           AND BPXQUESTION = @BPXQUESTION ) );
OPEN C1;
OPEN C2;
END


////////////


CREATE OR REPLACE PROCEDURE "BUCAP"."USP_INS_G_SURVEY_ANS" (
	@SURVEYGUID VARCHAR(4000),
	@SURVEYID BIGINT,

	@GROUPSURVEYID BIGINT,
	@SECTIONID BIGINT,
	@BPXQUESTION BOOLEAN,
	@ANS VARCHAR(10000)
) 
 	SPECIFIC BUCAP.USP_INS_G_SURVEY_ANS
  	LANGUAGE SQL 
  	DYNAMIC RESULT SETS 1
BEGIN
	DECLARE C1 CURSOR WITH RETURN FOR 
	SELECT SURVEYGROUPDETAILID
	FROM BUCAP.SURVEYGROUPDETAIL
	WHERE SURVEYGROUPDETAILID = @GROUPSURVEYID;

	IF (SELECT COUNT(*) FROM BUCAP.SURVEYGROUPDETAIL WHERE SURVEYGROUPDETAILID = @GROUPSURVEYID) = 0 THEN 

		SELECT SURVEYGROUPDETAILID
		INTO @GROUPSURVEYID
		FROM FINAL TABLE (
    		INSERT INTO BUCAP.SURVEYGROUPDETAIL(SURVEYGROUPID, SURVEYID, CREATEDDATE)
			SELECT SURVEYGROUPID, @SURVEYID, CURRENT_TIMESTAMP FROM BUCAP.SURVEYGROUP SG WHERE SG.GUID = @SURVEYGUID
		);
		
	ELSE
		UPDATE BUCAP.SURVEYGROUPDETAIL
		SET LASTUPDATE = CURRENT_TIMESTAMP
		WHERE SURVEYGROUPDETAILID = @GROUPSURVEYID;
	END IF;

	DELETE FROM BUCAP.SURVEYGROUPQUESTIONANSWER WHERE SURVEYGROUPQUESTIONANSWERID IN (
		SELECT SURVEYGROUPQUESTIONANSWERID FROM BUCAP.SURVEYGROUPQUESTIONANSWER S 
		INNER JOIN BUCAP.SURVEYGROUPDETAIL SS ON S.SURVEYGROUPDETAILID = SS.SURVEYGROUPDETAILID 
		WHERE S.SURVEYQUESTIONID IN (
				SELECT SURVEYQUESTIONID 
				FROM BUCAP.SURVEYQUESTION Q
				WHERE SURVEYID = @SURVEYID AND SURVEYSECTIONID = @SECTIONID
		AND SS.SURVEYGROUPDETAILID = @GROUPSURVEYID)
	);

	INSERT INTO BUCAP.SURVEYGROUPQUESTIONANSWER(
		SURVEYGROUPDETAILID,
		SURVEYQUESTIONID, 
		SURVEYQUESTIONANSWEROPTIONID, 
		ANSWERDECIMAL, 
		ANSWERINTEGER, 
		ANSWERDATE, 
		ANSWERDATETIME, 
		ANSWERTEXT, 
		ANSWERBOOLEAN, 
		LASTUPDATE
	)
	SELECT  	
		@GROUPSURVEYID,
		JSON_VAL(SYSTOOLS.JSON2BSON(VALUE),'id','i') AS SURVEYQUESTIONID, 
		JSON_VAL(SYSTOOLS.JSON2BSON(VALUE),'optionId','i') AS SURVEYQUESTIONANSWEROPTIONID,
		JSON_VAL(SYSTOOLS.JSON2BSON(VALUE),'dAns','n') AS ANSWERDECIMAL,
		JSON_VAL(SYSTOOLS.JSON2BSON(VALUE),'iAns','i') AS ANSWERINTEGER,
		JSON_VAL(SYSTOOLS.JSON2BSON(VALUE),'dtAns','d') AS ANSWERDATE,
		JSON_VAL(SYSTOOLS.JSON2BSON(VALUE),'tsAns','ts') AS ANSWERDATETIME,
		JSON_VAL(SYSTOOLS.JSON2BSON(VALUE),'sAns','s:4000') AS ANSWERTEXT,
		JSON_VAL(SYSTOOLS.JSON2BSON(VALUE),'bAns','i') AS ANSWERBOOLEAN,
		CURRENT_TIMESTAMP
 	FROM TABLE(SYSTOOLS.JSON_TABLE(SYSTOOLS.JSON2BSON(@ANS),'json', 's:5000'));

 	IF(@SECTIONID = 1)THEN
 		UPDATE BUCAP.SURVEYGROUPDETAIL SGD
 		SET SGD.SURVEYNAME = (SELECT MAX(SGQA.ANSWERTEXT) FROM BUCAP.SURVEYGROUPQUESTIONANSWER SGQA INNER JOIN BUCAP.SURVEYQUESTION SQ ON SQ.SURVEYQUESTIONID = SGQA.SURVEYQUESTIONID WHERE SQ.QUESTIONCODE = 'Q1-10' AND SGQA.SURVEYGROUPDETAILID = @GROUPSURVEYID)
 		WHERE SGD.SURVEYGROUPDETAILID = @GROUPSURVEYID ;
 	END IF;
	
 	IF(@SECTIONID = (SELECT MAX(SURVEYSECTIONID) FROM BUCAP.SURVEYSECTION S WHERE S.BACTIVE = TRUE AND SECTIONLABEL NOT LIKE '%PX%')) THEN 
 		UPDATE BUCAP.SURVEYGROUPDETAIL 
 		SET COMPLETEDDATE = CURRENT_TIMESTAMP
 		WHERE SURVEYGROUPDETAILID = @GROUPSURVEYID;
 	END IF;
 
 	OPEN C1;
END

//////

CREATE OR REPLACE PROCEDURE "BUCAP"."USP_GET_SECTION_QUESTIONS"(@SURVEYSECTIONID BIGINT, @SURVEYID BIGINT DEFAULT 0, @BPXQUESTION BOOLEAN DEFAULT FALSE) 
 	SPECIFIC BUCAP.USP_GET_SECTION_QUESTIONS
  	LANGUAGE SQL 
  	DYNAMIC RESULT SETS 3
BEGIN 
	DECLARE C1 CURSOR WITH RETURN FOR
	SELECT  DISTINCT Q.SURVEYQUESTIONID, 
			Q.QUESTIONCODE, 
			Q.QUESTION, 
			Q.QUESTIONTYPEID,
			T.QUESTIONTYPE,
			Q.BMANDATORY, 
			Q.BBESPOKE, 
			Q.BPXQUESTION,
			Q.QUESTIONORDER 
	FROM BUCAP.SURVEYQUESTION Q 
	INNER JOIN BUCAP.QUESTIONTYPE T ON Q.QUESTIONTYPEID = T.QUESTIONTYPEID 
	LEFT OUTER JOIN BUCAP.SURVEYQUESTIONDEPENDENCY D ON Q.SURVEYQUESTIONID = D.SURVEYQUESTIONID 
	WHERE Q.BACTIVE = TRUE --AND D.DEPENDENTSURVEYQUESTIONID IS NULL 
	AND SURVEYID = @SURVEYID AND SURVEYSECTIONID = @SURVEYSECTIONID AND Q.BPXQUESTION = @BPXQUESTION
	ORDER BY Q.QUESTIONORDER;
	
	DECLARE C2 CURSOR WITH RETURN FOR
	SELECT 	Q.SURVEYQUESTIONID, 
			Q.QUESTIONCODE, 
			Q.QUESTION, 
			Q.QUESTIONTYPEID,
			T.QUESTIONTYPE,
			Q.BMANDATORY, 
			Q.BBESPOKE, 
			Q.BPXQUESTION,
			D.DEPENDENTSURVEYQUESTIONID, 
			D.DEPENDENTSURVEYQUESTIONRESULTBOOLEAN, 
			D.DEPENDENTSURVEYQUESTIONRESULTINT
	FROM BUCAP.SURVEYQUESTION Q
	INNER JOIN BUCAP.QUESTIONTYPE T ON Q.QUESTIONTYPEID = T.QUESTIONTYPEID 
	INNER JOIN BUCAP.SURVEYQUESTIONDEPENDENCY D ON Q.SURVEYQUESTIONID = D.SURVEYQUESTIONID 
	WHERE Q.BACTIVE = TRUE 
	AND Q.SURVEYID = @SURVEYID AND Q.SURVEYSECTIONID = @SURVEYSECTIONID AND Q.BPXQUESTION = @BPXQUESTION
	ORDER BY Q.QUESTIONORDER;

	DECLARE C3 CURSOR WITH RETURN FOR
	SELECT 	Q.SURVEYQUESTIONID, O.SURVEYQUESTIONANSWEROPTIONID, O.ANSWEROPTION 
	FROM BUCAP.SURVEYQUESTION Q
	INNER JOIN BUCAP.SURVEYQUESTIONANSWEROPTION O ON Q.SURVEYQUESTIONID = O.SURVEYQUESTIONID 
	WHERE Q.BACTIVE = TRUE AND O.BACTIVE = TRUE
	AND Q.SURVEYID = @SURVEYID AND Q.SURVEYSECTIONID = @SURVEYSECTIONID AND Q.BPXQUESTION = @BPXQUESTION
	ORDER BY Q.QUESTIONORDER, O.OPTIONORDER;

	OPEN C1;
	OPEN C2;
	OPEN C3;
END


//////

CREATE OR REPLACE PROCEDURE "BUCAP"."USP_GET_SURVEY_SECTIONS"(@SURVEYID BIGINT DEFAULT 0, @PX BOOLEAN DEFAULT FALSE) 
 	SPECIFIC BUCAP.USP_GET_SURVEY_SECTIONS
  	LANGUAGE SQL 
  	DYNAMIC RESULT SETS 1
BEGIN 
	DECLARE c1 CURSOR WITH RETURN FOR
	SELECT 	SURVEYSECTIONID, 
			SECTIONNAME, 
			SECTIONTEXT,
			SECTIONLABEL,
			SECTIONORDER
	FROM BUCAP.SURVEYSECTION
	WHERE BACTIVE = TRUE 
	AND SURVEYID = @SURVEYID
	AND SECTIONLABEL NOT LIKE '%PX%'
	ORDER BY SECTIONORDER;

	DECLARE c2 CURSOR WITH RETURN FOR
	SELECT 	SURVEYSECTIONID, 
			SECTIONNAME, 
			SECTIONTEXT,
			SECTIONLABEL,
			SECTIONORDER
	FROM BUCAP.SURVEYSECTION
	WHERE BACTIVE = TRUE 
	AND SURVEYID = @SURVEYID
	AND SECTIONLABEL LIKE '%PX%'
	ORDER BY SECTIONORDER;
	
IF @PX = FALSE THEN
	OPEN C1;
ELSE
	OPEN C2;
END IF;
END

////

CREATE OR REPLACE PROCEDURE "BUCAP"."USP_SUBMIT_G_SURVEY"(@GROUPSURVEYID BIGINT)
 
  SPECIFIC USP_SUBMIT_G_SURVEY
  DYNAMIC RESULT SETS 1
  LANGUAGE SQL
  NOT DETERMINISTIC
  EXTERNAL ACTION
  MODIFIES SQL DATA
  CALLED ON NULL INPUT
  INHERIT SPECIAL REGISTERS
  OLD SAVEPOINT LEVEL
BEGIN
 DECLARE
    c1 CURSOR WITH RETURN TO CLIENT FOR
	
-- TO BE COMPLETED


WITH CHECKS (PRECEDENCE,SITETYPEID,SITETYPECODE,SITETYPE,MODELVERSION) AS
(
SELECT 1,-1 ,'BESPOKE TYPE:' SITETYPECODE, 'WIND TURBINE'  SITETYPE,' '
FROM BUCAP.SURVEYGROUPDETAIL SS
INNER JOIN BUCAP.SURVEYGROUPQUESTIONANSWER SSQ ON SS.SURVEYGROUPDETAILID = SSQ.SURVEYGROUPDETAILID AND SS.SURVEYGROUPDETAILID =@GROUPSURVEYID
INNER JOIN BUCAP.SURVEYQUESTION SQ ON SSQ.SURVEYQUESTIONID = SQ.SURVEYQUESTIONID
WHERE QUESTIONCODE = 'Q9-1470' AND ANSWERBOOLEAN = 1
UNION
SELECT 2,-1 ,'BESPOKE TYPE:' SITETYPECODE, 'RECTIFIER NOT INTEGRATED'  SITETYPE,' '
FROM BUCAP.SURVEYGROUPDETAIL SS
INNER JOIN BUCAP.SURVEYGROUPQUESTIONANSWER SSQ ON SS.SURVEYGROUPDETAILID = SSQ.SURVEYGROUPDETAILID AND SS.SURVEYGROUPDETAILID =@GROUPSURVEYID
INNER JOIN BUCAP.SURVEYQUESTION SQ ON SSQ.SURVEYQUESTIONID = SQ.SURVEYQUESTIONID
INNER JOIN BUCAP.SURVEYQUESTIONANSWEROPTION SQAO ON SSQ.SURVEYQUESTIONANSWEROPTIONID = SQAO.SURVEYQUESTIONANSWEROPTIONID
WHERE QUESTIONCODE = 'Q2-150' AND SQAO.ANSWEROPTION = 'Other'
UNION
SELECT 3,-1 ,'BESPOKE TYPE:' SITETYPECODE, 'CONTROLLER NOT INTEGRATED'  SITETYPE,' '
FROM BUCAP.SURVEYGROUPDETAIL SS
INNER JOIN BUCAP.SURVEYGROUPQUESTIONANSWER SSQ ON SS.SURVEYGROUPDETAILID = SSQ.SURVEYGROUPDETAILID AND SS.SURVEYGROUPDETAILID =@GROUPSURVEYID
INNER JOIN BUCAP.SURVEYQUESTION SQ ON SSQ.SURVEYQUESTIONID = SQ.SURVEYQUESTIONID
INNER JOIN BUCAP.SURVEYQUESTIONANSWEROPTION SQAO ON SSQ.SURVEYQUESTIONANSWEROPTIONID = SQAO.SURVEYQUESTIONANSWEROPTIONID
WHERE QUESTIONCODE = 'Q12-1680' AND SQAO.ANSWEROPTION = 'Other'
UNION
SELECT 4,-1 ,'BESPOKE TYPE:' SITETYPECODE, 'GENERATOR 2 EXISTS'  SITETYPE,' '
FROM BUCAP.SURVEYGROUPDETAIL SS
INNER JOIN BUCAP.SURVEYGROUPQUESTIONANSWER SSQ ON SS.SURVEYGROUPDETAILID = SSQ.SURVEYGROUPDETAILID AND SS.SURVEYGROUPDETAILID =@GROUPSURVEYID
INNER JOIN BUCAP.SURVEYQUESTION SQ ON SSQ.SURVEYQUESTIONID = SQ.SURVEYQUESTIONID
WHERE QUESTIONCODE = 'Q4-830' AND ANSWERBOOLEAN = 1
UNION
SELECT DISTINCT  6,ST.SITETYPEID,ST.SITETYPECODE,ST.SITETYPE,ST.MODELVERSION
FROM BUCAP.SITETYPE ST
INNER JOIN 
(SELECT SITETYPEID FROM BUCAP.SITETYPE ST 
INNER JOIN BUCAP.SURVEYGROUPDETAIL SS ON SS.SURVEYGROUPDETAILID =@GROUPSURVEYID
INNER JOIN BUCAP.SURVEYGROUPQUESTIONANSWER SSQ ON SS.SURVEYGROUPDETAILID = SSQ.SURVEYGROUPDETAILID  
INNER JOIN BUCAP.SURVEYQUESTION SQ ON SSQ.SURVEYQUESTIONID = SQ.SURVEYQUESTIONID
AND SQ.QUESTIONCODE = 'Q5-1090' AND SSQ.ANSWERBOOLEAN =  ST.BSOLAR ) SOLAR ON ST.SITETYPEID = SOLAR.SITETYPEID
INNER JOIN 
(SELECT SITETYPEID FROM BUCAP.SITETYPE ST 
INNER JOIN BUCAP.SURVEYGROUPDETAIL SS ON SS.SURVEYGROUPDETAILID =@GROUPSURVEYID
INNER JOIN BUCAP.SURVEYGROUPQUESTIONANSWER SSQ ON SS.SURVEYGROUPDETAILID = SSQ.SURVEYGROUPDETAILID  
INNER JOIN BUCAP.SURVEYQUESTION SQ ON SSQ.SURVEYQUESTIONID = SQ.SURVEYQUESTIONID
AND SQ.QUESTIONCODE = 'Q3-540' AND SSQ.ANSWERBOOLEAN =  ST.BBATTERY) BATTERY ON ST.SITETYPEID = BATTERY.SITETYPEID
INNER JOIN 
(SELECT SITETYPEID FROM BUCAP.SITETYPE ST 
INNER JOIN BUCAP.SURVEYGROUPDETAIL SS ON SS.SURVEYGROUPDETAILID =@GROUPSURVEYID
INNER JOIN BUCAP.SURVEYGROUPQUESTIONANSWER SSQ ON SS.SURVEYGROUPDETAILID = SSQ.SURVEYGROUPDETAILID  
INNER JOIN BUCAP.SURVEYQUESTION SQ ON SSQ.SURVEYQUESTIONID = SQ.SURVEYQUESTIONID
AND SQ.QUESTIONCODE = 'Q3-550' AND SSQ.ANSWERBOOLEAN =  ST.BBATTERY2 ) BATTERY2 ON ST.SITETYPEID = BATTERY2.SITETYPEID
INNER JOIN 
(SELECT SITETYPEID FROM BUCAP.SITETYPE ST 
INNER JOIN BUCAP.SURVEYGROUPDETAIL SS ON SS.SURVEYGROUPDETAILID =@GROUPSURVEYID
INNER JOIN BUCAP.SURVEYGROUPQUESTIONANSWER SSQ ON SS.SURVEYGROUPDETAILID = SSQ.SURVEYGROUPDETAILID  
INNER JOIN BUCAP.SURVEYQUESTION SQ ON SSQ.SURVEYQUESTIONID = SQ.SURVEYQUESTIONID
AND SQ.QUESTIONCODE = 'Q4-720' AND  SSQ.ANSWERBOOLEAN =  ST.BGENERATOR  ) GENERATOR ON ST.SITETYPEID = GENERATOR.SITETYPEID
INNER JOIN 
(SELECT SITETYPEID FROM BUCAP.SITETYPE ST 
INNER JOIN BUCAP.SURVEYGROUPDETAIL SS ON SS.SURVEYGROUPDETAILID =@GROUPSURVEYID
INNER JOIN BUCAP.SURVEYGROUPQUESTIONANSWER SSQ ON SS.SURVEYGROUPDETAILID = SSQ.SURVEYGROUPDETAILID  
INNER JOIN BUCAP.SURVEYQUESTION SQ ON SSQ.SURVEYQUESTIONID = SQ.SURVEYQUESTIONID
AND SQ.QUESTIONCODE = 'Q6-1260'  AND SSQ.ANSWERBOOLEAN =  ST.BGRID ) GRID ON ST.SITETYPEID = GRID.SITETYPEID
INNER JOIN 
(SELECT SITETYPEID FROM BUCAP.SITETYPE ST 
INNER JOIN BUCAP.SURVEYGROUPDETAIL SS ON SS.SURVEYGROUPDETAILID =@GROUPSURVEYID
INNER JOIN BUCAP.SURVEYGROUPQUESTIONANSWER SSQ ON SS.SURVEYGROUPDETAILID = SSQ.SURVEYGROUPDETAILID  
INNER JOIN BUCAP.SURVEYQUESTION SQ ON SSQ.SURVEYQUESTIONID = SQ.SURVEYQUESTIONID
AND SQ.QUESTIONCODE = 'Q2-340' AND SSQ.ANSWERBOOLEAN =  ST.BRECTIFIER2 ) RECTIFIER2 ON ST.SITETYPEID = RECTIFIER2.SITETYPEID
-- BATTERYTYPE - LEAD ACID/LITHIUM - NEED TO SOMEHOW 
INNER JOIN 
(SELECT DISTINCT ST.SITETYPEID ,ST.SITETYPE,BATTERY1TYPE,BATTERY1INTEGRATED,LITHIUMINTEGRATED
FROM 
BUCAP.SITETYPE ST
INNER JOIN BUCAP.BATTERYTYPE BT ON ST.BATTERY1BATTERYTYPEID = BT.BATTERYTYPEID
LEFT OUTER JOIN 
(SELECT SS.SURVEYGROUPDETAILID,SQAO.ANSWEROPTION BATTERY1TYPE FROM  BUCAP.SURVEYGROUPDETAIL SS 
INNER JOIN BUCAP.SURVEYGROUPQUESTIONANSWER SSQ ON SS.SURVEYGROUPDETAILID = SSQ.SURVEYGROUPDETAILID  AND SS.SURVEYGROUPDETAILID =@GROUPSURVEYID
INNER JOIN BUCAP.SURVEYQUESTIONANSWEROPTION SQAO ON SSQ.SURVEYQUESTIONANSWEROPTIONID = SQAO.SURVEYQUESTIONANSWEROPTIONID
INNER JOIN BUCAP.SURVEYQUESTION SQ1 ON SSQ.SURVEYQUESTIONID = SQ1.SURVEYQUESTIONID
WHERE QUESTIONCODE = 'Q3-560') BATTERY1TYPE ON @GROUPSURVEYID= BATTERY1TYPE.SURVEYGROUPDETAILID   
LEFT OUTER JOIN 
(SELECT SS.SURVEYGROUPDETAILID,SSQ.ANSWERBOOLEAN BATTERY1INTEGRATED  FROM  BUCAP.SURVEYGROUPDETAIL SS 
INNER JOIN BUCAP.SURVEYGROUPQUESTIONANSWER SSQ ON SS.SURVEYGROUPDETAILID = SSQ.SURVEYGROUPDETAILID  AND SS.SURVEYGROUPDETAILID =@GROUPSURVEYID
INNER JOIN BUCAP.SURVEYQUESTION SQ1 ON SSQ.SURVEYQUESTIONID = SQ1.SURVEYQUESTIONID
WHERE QUESTIONCODE = 'Q2-280'  ) BATTERY1INTEGRATED ON @GROUPSURVEYID = BATTERY1INTEGRATED.SURVEYGROUPDETAILID    
LEFT OUTER JOIN 
(SELECT SS.SURVEYGROUPDETAILID,SSQ.ANSWERBOOLEAN LITHIUMINTEGRATED FROM  BUCAP.SURVEYGROUPDETAIL SS   
INNER JOIN BUCAP.SURVEYGROUPQUESTIONANSWER SSQ ON SS.SURVEYGROUPDETAILID = SSQ.SURVEYGROUPDETAILID AND  SS.SURVEYGROUPDETAILID =@GROUPSURVEYID
INNER JOIN BUCAP.SURVEYQUESTION SQ1 ON SSQ.SURVEYQUESTIONID = SQ1.SURVEYQUESTIONID
WHERE QUESTIONCODE = 'Q2-200'   ) LITHIUMINTEGRATED  ON  @GROUPSURVEYID= LITHIUMINTEGRATED.SURVEYGROUPDETAILID  
WHERE BATTERY1TYPE = BT.BATTERYTYPECODE AND BATTERY1INTEGRATED = BT.RECTIFIERINTEGRATED
AND CASE WHEN BATTERY1TYPE ='LITHIUM' THEN BT.LITHIUMRECTIFIERINTEGRATED = LITHIUMINTEGRATED ELSE 1=1 END) BATTERYTYPE
ON  ST.SITETYPEID = BATTERYTYPE.SITETYPEID
-- ADD IN BEHAVIOUR CHECKS - INVERTOR
INNER JOIN 
(SELECT DISTINCT ST.SITETYPEID ,ST.SITETYPE,MM.MEASUREMENTMAP 
FROM 
BUCAP.SITETYPE ST
INNER JOIN BUCAP.MEASUREMENTMAP MM ON ST.MEASUREMENTMAPID = MM.MEASUREMENTMAPID
INNER JOIN 
(SELECT SS.SURVEYGROUPDETAILID,SQAO.ANSWEROPTION MEASUREMENTMAPCODE FROM  BUCAP.SURVEYGROUPDETAIL SS 
INNER JOIN BUCAP.SURVEYGROUPQUESTIONANSWER SSQ ON SS.SURVEYGROUPDETAILID = SSQ.SURVEYGROUPDETAILID  AND SS.SURVEYGROUPDETAILID =@GROUPSURVEYID
INNER JOIN BUCAP.SURVEYQUESTIONANSWEROPTION SQAO ON SSQ.SURVEYQUESTIONANSWEROPTIONID = SQAO.SURVEYQUESTIONANSWEROPTIONID
INNER JOIN BUCAP.SURVEYQUESTION SQ1 ON SSQ.SURVEYQUESTIONID = SQ1.SURVEYQUESTIONID
WHERE QUESTIONCODE = 'Q3-567') BB1MEASUREMENTMAP 
ON @GROUPSURVEYID= BB1MEASUREMENTMAP.SURVEYGROUPDETAILID   AND MM.MEASUREMENTMAPCODE=BB1MEASUREMENTMAP.MEASUREMENTMAPCODE) MAP
ON  ST.SITETYPEID = MAP.SITETYPEID
) 

SELECT 'Survey completed by '|| SG.GUID ||' for '|| SGD.SURVEYNAME AS EMAILSUBJECT,
COALESCE(LISTAGG(SITETYPECODE||' '||SITETYPE, ', '),'NO SITE TYPE MATCH FOUND') AS EMAILCONTENT
FROM BUCAP.SURVEYGROUPDETAIL SGD
INNER JOIN BUCAP.SURVEYGROUP SG
ON SG.SURVEYGROUPID = SGD.SURVEYGROUPID
LEFT OUTER JOIN CHECKS C ON 1=1
WHERE SGD.SURVEYGROUPDETAILID = @GROUPSURVEYID
GROUP BY SG.GUID, SGD.SURVEYNAME;

  OPEN c1;
END


CREATE OR REPLACE PROCEDURE "BUCAP"."USP_GET_G_SURVEYS"(@SURVEYGUID VARCHAR(4000)) 
 	SPECIFIC BUCAP.USP_GET_G_SURVEYS
  	LANGUAGE SQL 
  	DYNAMIC RESULT SETS 1
BEGIN 
	DECLARE c1 CURSOR WITH RETURN FOR
	SELECT 	SGD.SURVEYGROUPDETAILID, 
			SGD.SURVEYNAME
	FROM BUCAP.SURVEYGROUPDETAIL SGD INNER JOIN SURVEYGROUP SG ON SG.SURVEYGROUPID = SGD.SURVEYGROUPID
	WHERE SG.GUID = @SURVEYGUID 
	ORDER BY SGD.SURVEYNAME;

	OPEN C1;
END