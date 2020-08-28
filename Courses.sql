/* 
IMPORTANT NOTES

The Comprehensicve [CreditType] and [Department] don't have an equivalent column
in EdFi. To account for this, the EdFi [Description] column is a concatonation of
the Comprehensicve [CreditType] and [Department] with a @ as the deliminator.

Unfortunatley because EdFi limits the number of charaters (1024) in the EdFi 
[Description] column I could not also include the Comprehensive [Description]. 

Also note that the EdFi quivalent of the Comprehensive [SubjectID] is the column
[AcademicSubjectDescriptorId]. Even though [SubjectID] doesn't exist in PS, the 
SQL code is included here if it does exist in the future
*/

SELECT 
	main.CourseCode AS CourseID 
	, main.CourseTitle AS CourseName
	, main.EducationOrganizationId AS LocalSchoolID
	, [subject].CodeValue AS SubjectID -- Does not exist in PS
	, main.MaximumAvailableCredits AS CreditHours
	, CASE
		WHEN main.CourseDescription IS NULL THEN NULL
		WHEN CHARINDEX('@', main.CourseDescription) = 1 THEN NULL
		WHEN CHARINDEX('@', main.CourseDescription) = LEN(main.CourseDescription) 
			THEN LEFT(main.CourseDescription, LEN(main.CourseDescription)-1)
		ELSE LEFT(main.CourseDescription, CHARINDEX('@', main.CourseDescription)-1)
		END AS CreditType
	, CASE
		WHEN main.CourseDescription IS NULL THEN NULL 
		WHEN CHARINDEX('@', main.CourseDescription) = LEN(main.CourseDescription) THEN NULL
		WHEN CHARINDEX('@', main.CourseDescription) = 1 
			THEN RIGHT(main.CourseDescription, LEN(main.CourseDescription)-1)
		ELSE RIGHT(main.CourseDescription, LEN(main.CourseDescription)-CHARINDEX('@', main.CourseDescription))
		END AS Department
	, main.MaximumAvailableCreditConversion AS AddedValueGPA
	, CASE
		WHEN excludeGPA.CodeValue = 'Applicable' THEN 1
		ELSE 0
		END AS ExcludeFromGPA

FROM edfi.Course AS main


-- Getting Subject (returns NULL because value does not exist in PS)
LEFT JOIN edfi.Descriptor AS [subject]
	ON main.AcademicSubjectDescriptorId = [subject].DescriptorId


-- Getting AddedValueGPA
LEFT JOIN edfi.Descriptor AS excludeGPA
	ON main.CourseGPAApplicabilityDescriptorId = excludeGPA.DescriptorId
