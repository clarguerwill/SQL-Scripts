-- The code is split into four parts: main1, main2, main3, main4
-- main1 columns are calculated first, main2 second, etc.
-- There is also a base table whic returns a table of one row per student per school per day and the attendancecode

DECLARE @DesiredYear AS INT = 2020 --ONLY WORKS FOR THE 2020 school year and forward because enrollment data for previous years is incorrect


--------------------------------- Start of main4 -----------------------------
SELECT main4.* -- Get necessary main1, main2 and main3 columns --
	-- main3 columns --
	, ROUND(1 - main4.YTDAttendaceRate, 3) AS YTDAbsenceRate
	, CASE
		WHEN main4.YTDRecords >= 20 AND main4.YTDAttendaceRate <= .9 THEN 1
		ELSE 0
		END AS YTDChronicFlag
	, CASE 
		WHEN main4.YTDAttendaceRate <= .7 THEN 5
		WHEN main4.YTDAttendaceRate <= .8 THEN 4
		WHEN main4.YTDAttendaceRate <= .9 THEN 5
		WHEN main4.YTDAttendaceRate <= .95 THEN 2
		WHEN main4.YTDAttendaceRate <= 1 THEN 1
		ELSE 6
		END AS ChronicStatusSort
	, CASE
		WHEN main4.YTDAttendaceRate <= .7 THEN 'Profound Chronic Absence'
		WHEN main4.YTDAttendaceRate <= .8 THEN 'Severe Chronic Absence'
		WHEN main4.YTDAttendaceRate <= .9 THEN 'Moderate Chronic Absence'
		WHEN main4.YTDAttendaceRate <= .95 THEN 'At Risk of Chronic Absence'
		WHEN main4.YTDAttendaceRate <= 1 THEN 'Satisfactory Attendance'
		ELSE 'Less Than 20 Attendance Records'
		END AS YTDChronicStatus

FROM (
	--------------------------------- Start of main3 -----------------------------
	SELECT main3.*  -- Get necessary main1 and main2 columns --
		-- main3 columns --
		, ROUND(main3.YTDPresent / CAST(main3.YTDRecords AS FLOAT), 3) AS YTDAttendaceRate

	FROM (
		--------------------------------- Start of main2 -----------------------------
		SELECT main2.* -- Get necessary main1 columns --
			-- main2 columns -- 
			, SUM(main2.Suspension) 
				OVER (PARTITION BY main2.LocalStudentId, main2.LocalSchoolID ORDER BY main2.EventDate ROWS UNBOUNDED PRECEDING) 
				AS YTDSuspensionDays
			, SUM(main2.PresentWhole) 
				OVER (PARTITION BY main2.LocalStudentId, main2.LocalSchoolID ORDER BY main2.EventDate ROWS UNBOUNDED PRECEDING) 
				AS YTDPresent
			, SUM(CASE WHEN main2.AttendanceEventCategory IS NOT NULL THEN 1 ELSE NULL END) 
					OVER (PARTITION BY main2.LocalStudentId, main2.LocalSchoolID ORDER BY main2.EventDate ROWS UNBOUNDED PRECEDING) 
					AS YTDRecords

		FROM (
		--------------------------------- Start of main1 -----------------------------
			SELECT CONCAT('SY', main1.SchoolYear-1, '-', RIGHT(main1.SchoolYear, 2)) AS SchoolYear
				, main1.EventDate AS EventDate
				, student.StudentUniqueId AS LocalStudentID
				, main1.SchoolId AS LocalSchoolID
				, att.CodeValue AS AttendanceEventCategory
				, CASE 
					WHEN att.CodeValue IS NULL THEN NULL
					WHEN att.ShortDescription LIKE '%Present%' THEN 1
					ELSE 0
					END AS PresentWhole
				, CASE 
					WHEN att.CodeValue IS NULL THEN NULL
					WHEN att.[Description] LIKE '%Excused%' THEN 1
					WHEN att.ShortDescription LIKE '%Excused%' THEN 1
					ELSE 0
					END AS Excused
				, CASE 
					WHEN att.CodeValue IS NULL THEN NULL
					WHEN att.[Description] LIKE '%Tardy%' THEN 1
					WHEN att.ShortDescription LIKE '%Tardy%' THEN 1
					ELSE 0
					END AS Tardy
				, CASE 
					WHEN att.CodeValue IS NULL THEN NULL
					WHEN att.[Description] LIKE '%Suspension%' THEN 1
					ELSE 0
					END AS Suspension
				, CASE 
					WHEN att.CodeValue IS NULL THEN NULL
					WHEN att.ShortDescription = 'Present' AND att.[Description] = 'Present' THEN 1
					ELSE 0
					END AS OnTime
				, CASE 
					WHEN att.CodeValue IS NULL THEN NULL
					WHEN att.ShortDescription LIKE '%Absent%' THEN 1
					ELSE 0
					END AS AbsentWhole
				, CASE 
					WHEN att.CodeValue IS NULL THEN NULL
					WHEN att.ShortDescription LIKE 'Absent' THEN 1
					ELSE 0
					END AS AbsentWholeUnexcused

			FROM ( 
			--------------------------------- Start of base table -----------------------------
				SELECT base.SchoolId, base.StudentUSI, base.[Date] AS EventDate
					, attendance.AttendanceEventCategoryDescriptorId , base.SchoolYear
				FROM (

					SELECT  alldays.SchoolId, get_studentid.StudentUSI, alldays.[Date], alldays.SchoolYear
					FROM (

						SELECT cdce.SchoolId, cdce.[Date], cdce.SchoolYear
						FROM edfi.CalendarDateCalendarEvent AS cdce
	
						LEFT JOIN edfi.Descriptor AS D 
							ON cdce.CalendarEventDescriptorId = D.DescriptorId

						WHERE D.CodeValue = 'Instructional Day'
						AND cdce.SchoolYear = @DesiredYear 
						AND cdce.[Date] < GETDATE() 
						) AS alldays
 
					LEFT JOIN (
						SELECT DISTINCT ae.StudentUSI, ae.SchoolId
						FROM edfi.StudentSchoolAttendanceEvent AS ae
						WHERE ae.SchoolYear = @DesiredYear
						) AS get_studentid
						ON alldays.SchoolID = get_studentid.SchoolID
					
					) AS base

				LEFT JOIN edfi.StudentSchoolAttendanceEvent AS attendance	
					ON base.SchoolId = attendance.SchoolId
					AND base.StudentUSI = attendance.StudentUSI
					AND base.[Date] = attendance.EventDate
					AND attendance.SchoolYear = @DesiredYear
	
				) AS main1
	-------------------------------^ End of base table ^--------------------------


			-- Getting LocalStudentID
			LEFT JOIN edfi.Student AS student
				ON main1.StudentUSI = student.StudentUSI


			-- Getting AttendanceEventCategory
			LEFT JOIN edfi.Descriptor AS att
				ON main1.AttendanceEventCategoryDescriptorId = att.DescriptorId
	----------------------------------^ End of main1 ^-----------------------------

			) AS main2
	----------------------------------^ End of main2 ^-----------------------------

		) AS main3
	----------------------------------^ End of main3 ^-----------------------------

	) AS main4
	----------------------------------^ End of main4 ^-----------------------------