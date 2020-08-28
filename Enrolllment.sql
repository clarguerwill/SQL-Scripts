SELECT S.StudentUniqueId AS LocalStudentID
	, main.SchoolID AS LocalSchoolID
	, gradelevel.CodeValue AS EntryGradeLevel
	, CONCAT('SY', main.SchoolYear-1, '-', RIGHT(main.SchoolYear, 2)) AS SchoolYear
	, main.EntryDate AS EntryDate
	, entrytype.CodeValue AS EntryType
	, main.ExitWithdrawDate AS ExitWithdrawDate
	, withdrawtype.CodeValue AS ExitWithdrawType
	, CASE
		WHEN COALESCE(main.ExitWithdrawDate, CONCAT(main.SchoolYear, '-06-30')) > GETDATE() 
		THEN 1 ELSE 0 
		END AS CurrentEnrollment 
	,CASE 
		WHEN main.EntryDate <= CONCAT(main.SchoolYear-1, '-10-05')
			AND COALESCE(main.ExitWithdrawDate, CONCAT(main.SchoolYear, '-06-30')) >= CONCAT(main.SchoolYear-1, '-10-05')
			THEN 1
		WHEN DATENAME(WEEKDAY, CONCAT(main.SchoolYear-1, '-10-05')) = 'Saturday'
			AND main.EntryDate <= CONCAT(main.SchoolYear-1, '-10-07')
			AND COALESCE(main.ExitWithdrawDate, CONCAT(main.SchoolYear, '-06-30')) >= CONCAT(main.SchoolYear-1, '-10-07')
			THEN 1
		WHEN DATENAME(WEEKDAY, CONCAT(main.SchoolYear-1, '-10-05')) = 'Sunday'
			AND main.EntryDate <= CONCAT(main.SchoolYear-1, '-10-06')
			AND COALESCE(main.ExitWithdrawDate, CONCAT(main.SchoolYear, '-06-30')) >= CONCAT(main.SchoolYear-1, '-10-06')
			THEN 1
		ELSE 0 
		END AS Oct5Flag
	, CASE
		WHEN DATENAME(WEEKDAY, CONCAT(main.SchoolYear-1, '-10-05')) = 'Saturday'
			AND main.EntryDate > CONCAT(main.SchoolYear-1, '-10-07')
			THEN 1
		WHEN DATENAME(WEEKDAY, CONCAT(main.SchoolYear-1, '-10-05')) = 'Saturday'
			AND main.EntryDate <= CONCAT(main.SchoolYear-1, '-10-07')
			THEN 0
		WHEN DATENAME(WEEKDAY, CONCAT(main.SchoolYear-1, '-10-05')) = 'Sunday'
			AND main.EntryDate > CONCAT(main.SchoolYear-1, '-10-06')
			THEN 1
		WHEN DATENAME(WEEKDAY, CONCAT(main.SchoolYear-1, '-10-05')) = 'Sunday'
			AND main.EntryDate <= CONCAT(main.SchoolYear-1, '-10-06')
			THEN 0
		WHEN main.EntryDate > CONCAT(main.SchoolYear-1, '-10-05')
			THEN 1
		ELSE 0 
		END AS MidYearEntry
	, CASE
		WHEN main.EntryDate <= CONCAT(main.SchoolYear-1, '-10-05')
			AND COALESCE(main.ExitWithdrawDate, CONCAT(main.SchoolYear, '-06-30')) >= CONCAT(main.SchoolYear, '-03-01')
			THEN 1
		WHEN DATENAME(WEEKDAY, CONCAT(main.SchoolYear-1, '-10-05')) = 'Saturday'
			AND main.EntryDate <= CONCAT(main.SchoolYear-1, '-10-07')
			AND COALESCE(main.ExitWithdrawDate, CONCAT(main.SchoolYear, '-06-30')) >= CONCAT(main.SchoolYear, '-03-01')
			THEN 1
		WHEN DATENAME(WEEKDAY, CONCAT(main.SchoolYear-1, '-10-05')) = 'Sunday'
			AND main.EntryDate <= CONCAT(main.SchoolYear-1, '-10-06')
			AND COALESCE(main.ExitWithdrawDate, CONCAT(main.SchoolYear, '-06-30')) >= CONCAT(main.SchoolYear, '-03-01')
			THEN 1
		ELSE 0 
		END AS SchoolResponsible

FROM edfi.StudentSchoolAssociation AS main


-- Getting LocalStudentID
LEFT JOIN edfi.Student AS S
	ON main.StudentUSI = S.StudentUSI


-- Getting EntryGradeLevel
LEFT JOIN edfi.Descriptor AS gradelevel
	ON main.EntryGradeLevelDescriptorId = gradelevel.DescriptorId


-- Getting EntryType
LEFT JOIN edfi.Descriptor AS entrytype
	ON main.EntryTypeDescriptorId = entrytype.DescriptorId


-- Getting ExitWithdrawType
LEFT JOIN edfi.Descriptor AS withdrawtype
	ON main.ExitWithdrawTypeDescriptorId = withdrawtype.DescriptorId


