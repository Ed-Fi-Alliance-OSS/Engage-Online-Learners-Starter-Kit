# Sample Data Supporting Dashboard Development

The Power BI reports have been built on the Grand Bend (populated template) data
set from the Ed-Fi ODS/API for Suite 3, version 5.2, with the following
modifications:

* Used the time travel script to move dates forward to 2021-2022.
* LMS and LMSX schema objects installed from the LMS Toolkit.
* Extra descriptors from the LMS Toolkit.
* Analytics Middle Tier with options "Engage RLS EWS indexes".
* Ran LMS Toolkit tools to upload sample data from the Toolkit repository.
* Bulk uploaded sample Digital Equity data from the Toolkit repository.
* Manually edited sample data in the `lmsx.AssignmentSubmission` table, updating
  five random records to have a submission status of Upcoming.
* For Power BI Portal upload, converted email addresses in `StaffElectronicMail`
  to be `@edfidev.onmicrosoft.com`.

The SQL Server database with modifications is stored in Azure as a [bacpac
file](https://odsassets.blob.core.windows.net/public/StudentEngagementStarterKit/GrandBend-for-Engage-Online-Learners.bacpac)
