SELECT main.SectionIdentifier AS SectionID  
	, main.LocalCourseCode AS CourseID
	, course.CourseTitle AS CourseName -- JOIN with courses
	, CONCAT(teacher.LastSurname, ', ', teacher.FirstName) AS TeacherName -- double join with Staff and StaffSectionAssociation
	, CONCAT('SY', main.SchoolYear - 1, '-', RIGHT(main.SchoolYear, 2)) AS SchoolYear
	, CASE
		WHEN course.CourseDescription IS NULL THEN NULL 
		WHEN CHARINDEX('@', course.CourseDescription) = LEN(course.CourseDescription) THEN NULL
		WHEN CHARINDEX('@', course.CourseDescription) = 1 
			THEN RIGHT(course.CourseDescription, LEN(course.CourseDescription)-1)
		ELSE RIGHT(course.CourseDescription, LEN(course.CourseDescription)-CHARINDEX('@', course.CourseDescription))
		END AS Department

FROM edfi.Section AS main


-- Getting CourseName and Department
LEFT JOIN edfi.Course AS course
	ON main.LocalCourseCode = course.CourseCode

-- Getting TeacherName
LEFT JOIN edfi.StaffSectionAssociation AS section
	ON main.LocalCourseCode = section.LocalCourseCode
	AND main.SectionIdentifier = section.SectionIdentifier

LEFT JOIN edfi.Staff AS teacher
	ON section.StaffUSI = teacher.StaffUSI


ORDER BY main.LocalCourseCode, main.SectionIdentifier