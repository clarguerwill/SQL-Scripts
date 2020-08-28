SELECT main2.* 
	, CASE
		WHEN main2.ExcludeFromGPA = 1 THEN NULL
		ELSE (main2.GPAPoints * main2.CreditHours) 
		END AS SimpleQualityPoints
	, CASE
		WHEN main2.ExcludeFromGPA = 1 THEN NULL
		ELSE ((main2.GPAPoints + main2.AddedValueGPA) * main2.CreditHours) 
		END AS WeightedQualityPoints

FROM (
	
	SELECT 
		main.CurrentGradeID AS CurrentGradeId
		, main.PSGradeID AS PSGradeID
		, main.ImportDate AS ImportDate
		, main.SectionID AS SectionID
		, main.LocalStudentID AS LocalStudentID
		, main.[Percent] AS [Percent]
		, main.Grade AS LetterGrade
		, REPLACE(REPLACE(main.Grade, '-', ''), '+', '') AS LetterGradeCategory
		, CASE
				WHEN main.Grade IN ('A+', 'A', 'P') THEN 4
				WHEN main.Grade = 'A-' THEN 3.67
				WHEN main.Grade = 'B+' THEN 3.33
				WHEN main.Grade = 'B' THEN 3
				WHEN main.Grade = 'B-' THEN 2.67
				WHEN main.Grade = 'C+' THEN 2.33
				WHEN main.Grade = 'C' THEN 2
				WHEN main.Grade = 'C-' THEN 1.67
				WHEN main.Grade = 'D+' THEN 1.33
				WHEN main.Grade IN ('D', 'D-') THEN 1
				ELSE 0
				END AS GPAPoints
		, main.StoreCode AS StoreCode
		, course.MaximumAvailableCredits AS CreditHours
		, course.MaximumAvailableCreditConversion AS AddedValueGPA
		, CASE
			-- COVID grades are not included in GPA
			WHEN main.Grade = 'CV' THEN 1
			WHEN exclude.CodeValue = 'Applicable' THEN 0
			ELSE 1
			END AS ExcludeFromGPA

	FROM ods.InProgressGrades AS main


	-- Getting CreditHours and AddedValue
	INNER JOIN edfi.Section AS section
		ON main.SectionID = section.SectionIdentifier

	INNER JOIN edfi.Course AS course
		ON section.LocalCourseCode = course.CourseCode

	-- Getting ExcludeFromGPA
	LEFT JOIN edfi.Descriptor AS exclude
		ON course.CourseGPAApplicabilityDescriptorId = exclude.DescriptorId

	) AS main2
