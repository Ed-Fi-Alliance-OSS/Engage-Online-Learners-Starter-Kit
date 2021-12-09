begin tran;

insert into dbo.Vendors (
  VendorName
)
values (
  'Starter Kit Vendor'
);

insert into dbo.VendorNamespacePrefixes (
    NamespacePrefix,
    Vendor_VendorId
)
select
    'uri://ed-fi.org',
    VendorId
from
    dbo.Vendors;


insert into dbo.Applications (
  ApplicationName,
  OperationalContextUri,
  Vendor_VendorId,
  ClaimSetName
)
select
  'Starter Kit Bulk Loader',
  'uri://ed-fi.org',
  VendorId,
  'SIS Vendor'
from
    dbo.Vendors;


insert into dbo.ApplicationEducationOrganizations (
    EducationOrganizationId,
    Application_ApplicationId
)
select
    255901,
    ApplicationId
from
    dbo.Applications
where
    ApplicationName = 'Starter Kit Bulk Loader';


insert into dbo.ApiClients (
  [Key],
  [Secret],
  [Name],
  IsApproved,
  UseSandbox,
  SandboxType,
  SecretIsHashed,
  Application_ApplicationId
)
select
  '$(ClientKey)',
  '$(ClientSecret)',
  'Starter Kit Bulk Loader',
  1,
  0,
  0,
  0,
  ApplicationId
from
    dbo.Applications;


insert into dbo.ApiClientApplicationEducationOrganizations (
    ApiClient_ApiClientId,
    ApplicationEducationOrganization_ApplicationEducationOrganizationId
)
select
    ApiClients.ApiClientId,
    ApplicationEducationOrganizations.ApplicationEducationOrganizationId
from
    dbo.ApiClients
cross join
    dbo.Applications
inner join
    dbo.ApplicationEducationOrganizations on
        Applications.ApplicationId = ApplicationEducationOrganizations.Application_ApplicationId
where
    ApiClients.Name = 'Starter Kit Bulk Loader'
and
    Applications.ApplicationName = 'Starter Kit Bulk Loader';

commit;
