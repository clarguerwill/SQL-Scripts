SELECT main2.* 
	, CASE 
		WHEN main2.Passing = 1 THEN main2.PotentialCreditHours
		ELSE 0
		END AS EarnedCreditHours
	, CASE 
		WHEN main2.ExcludeFromGPA = 1 THEN NULL 
		ELSE (main2.GPAPoints * main2.PotentialCreditHours) 
		END AS SimpleQualityPoints
	, CASE 
		WHEN main2.ExcludeFromGPA = 1 THEN NULL 
		ELSE ((main2.GPAPoints + main2.AddedValueGPA) * main2.PotentialCreditHours)
		END AS WeightedQualityPoints

FROM (

	SELECT CONCAT(main.SchoolId, main.SchoolYear, main.SectionIdentifier, student.StudentUniqueId, main.GradingPeriodDescriptorId) AS StoredGradeId
		, student.StudentUniqueId AS LocalStudentID
		, main.SectionIdentifier AS SectionID
		, main.LocalCourseCode AS CourseID
		, course.CourseTitle AS CourseName
		, CONCAT('SY', main.SchoolYear-1, '-', RIGHT(main.SchoolYear, 2)) AS SchoolYear
		, CONCAT(main.SchoolId, '_', main.SchoolYear, '_', gradingperiod.CodeValue) AS GradingPeriodID
		, CAST(main.NumericGradeEarned AS INT) AS [Percent]
		, main.LetterGradeEarned AS LetterGrade
		, REPLACE(REPLACE(main.LetterGradeEarned, '-', ''), '+', '')  AS LetterGradeCategory
		, gradingperiod.CodeValue AS StoreCode
		, course.MaximumAvailableCredits AS PotentialCreditHours
		, CASE
			WHEN main.LetterGradeEarned IN ('A+', 'A', 'P') THEN 4
			WHEN main.LetterGradeEarned = 'A-' THEN 3.67
			WHEN main.LetterGradeEarned = 'B+' THEN 3.33
			WHEN main.LetterGradeEarned = 'B' THEN 3
			WHEN main.LetterGradeEarned = 'B-' THEN 2.67
			WHEN main.LetterGradeEarned = 'C+' THEN 2.33
			WHEN main.LetterGradeEarned = 'C' THEN 2
			WHEN main.LetterGradeEarned = 'C-' THEN 1.67
			WHEN main.LetterGradeEarned = 'D+' THEN 1.33
			WHEN main.LetterGradeEarned IN ('D', 'D-') THEN 1
			ELSE 0
			END AS GPAPoints
		, course.MaximumAvailableCreditConversion AS AddedValueGPA
		, CASE
			-- Account for COVID grades
			WHEN main.LetterGradeEarned = 'CV' THEN 0
			WHEN excludeGPA.CodeValue = 'Applicable' THEN 1
			ELSE 0
			END AS ExcludeFromGPA
		, CASE
			WHEN REPLACE(REPLACE(main.LetterGradeEarned, '-', ''), '+', '') IN ('A', 'B') THEN 1
			ELSE 0
			END AS AB
		, CASE
			WHEN REPLACE(REPLACE(main.LetterGradeEarned, '-', ''), '+', '') IN ('A', 'B', 'P') THEN 1
			ELSE 0
			END AS Passing
		, main.GradingPeriodSequence AS GradeSortOrder

	FROM edfi.Grade AS main


	-- Getting LocalStudentID
	INNER JOIN edfi.Student AS student
		ON main.StudentUSI = student.StudentUSI

	-- Getting CourseName, PotentialCreditHours and AddedValueGPA 
	INNER JOIN edfi.course AS course
		ON main.LocalCourseCode = course.CourseCode
	

	-- Getting GradingPeriodID and Store Code
	LEFT JOIN edfi.Descriptor AS gradingperiod
		ON main.GradingPeriodDescriptorId = gradingperiod.DescriptorId


	--Getting ExcludeFromGPA
	LEFT JOIN edfi.Descriptor AS excludeGPA
		ON course.CourseGPAApplicabilityDescriptorId = excludeGPA.DescriptorId
	
	) main2